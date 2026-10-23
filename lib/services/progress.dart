import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

/// Per-level saved state.
class LevelProgress {
  LevelProgress({
    this.solved = false,
    this.stars = 0,
    this.attempts = 0,
    this.hintUsed = false,
    this.code = '',
    this.blocksJson,
  });

  bool solved;
  int stars;
  int attempts;
  bool hintUsed;
  String code;
  List<dynamic>? blocksJson;

  Map<String, dynamic> toJson() => {
        's': solved,
        'st': stars,
        'a': attempts,
        'h': hintUsed,
        'c': code,
        if (blocksJson != null) 'b': blocksJson,
      };

  factory LevelProgress.fromJson(Map<String, dynamic> j) => LevelProgress(
        solved: j['s'] == true,
        stars: (j['st'] as num?)?.toInt() ?? 0,
        attempts: (j['a'] as num?)?.toInt() ?? 0,
        hintUsed: j['h'] == true,
        code: j['c'] as String? ?? '',
        blocksJson: j['b'] as List<dynamic>?,
      );
}

/// A player slot: independent progress so several kids can share a
/// device (or one player can start from zero without losing the old run).
class Profile {
  Profile({required this.id, required this.name, required this.emoji});

  final String id;
  String name;
  String emoji;

  Map<String, dynamic> toJson() => {'id': id, 'n': name, 'e': emoji};

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        name: j['n'] as String? ?? 'Jugador',
        emoji: j['e'] as String? ?? '🐯',
      );
}

/// Global persistent progress: XP, solved levels, saved code, language —
/// namespaced by the active [Profile] slot.
class Progress extends ChangeNotifier {
  Progress._();
  static final Progress instance = Progress._();

  static const _legacyKey = 'codearena_progress_v1';
  static const _profilesKey = 'codearena_profiles_v1';
  static const _activeKey = 'codearena_active_v1';
  static String _keyFor(String id) => 'codearena_progress_$id';

  int xp = 0;
  final Map<String, LevelProgress> levels = {};

  /// Daily training streak — the Gomel/China rule: a little every
  /// day beats a lot once a week.
  int streak = 0;

  /// 'yyyy-mm-dd' of the last day a level was solved.
  String lastSolveDay = '';

  /// Epoch-day when this profile first solved something — anchors
  /// the ghost rival's steady advance (~1 level every 2 days).
  int ghostStartDay = 0;

  final List<Profile> profiles = [];
  Profile? active;

  Future<void>? _loading;

  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // profiles
    final rawProfiles = prefs.getString(_profilesKey);
    if (rawProfiles != null) {
      try {
        for (final j in jsonDecode(rawProfiles) as List) {
          profiles.add(Profile.fromJson(Map<String, dynamic>.from(j)));
        }
      } catch (_) {}
    }
    // migrate legacy single-slot progress -> first profile
    if (profiles.isEmpty) {
      final p = Profile(
          id: 'p${DateTime.now().millisecondsSinceEpoch}',
          name: 'Jugador 1',
          emoji: '🐯');
      profiles.add(p);
      final legacy = prefs.getString(_legacyKey);
      if (legacy != null) {
        await prefs.setString(_keyFor(p.id), legacy);
        await prefs.remove(_legacyKey);
      }
      await prefs.setString(_profilesKey,
          jsonEncode(profiles.map((e) => e.toJson()).toList()));
      await prefs.setString(_activeKey, p.id);
    }
    final activeId = prefs.getString(_activeKey) ?? profiles.first.id;
    await _loadProfile(activeId, save: false);
    notifyListeners();
  }

  Future<void> _loadProfile(String id, {bool save = true}) async {
    final prefs = await SharedPreferences.getInstance();
    active = profiles.firstWhere((p) => p.id == id,
        orElse: () => profiles.first);
    xp = 0;
    streak = 0;
    lastSolveDay = '';
    ghostStartDay = 0;
    levels.clear();
    final raw = prefs.getString(_keyFor(active!.id));
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        xp = (j['xp'] as num?)?.toInt() ?? 0;
        streak = (j['rk'] as num?)?.toInt() ?? 0;
        lastSolveDay = j['rd'] as String? ?? '';
        ghostStartDay = (j['gh'] as num?)?.toInt() ?? 0;
        (j['lv'] as Map?)?.forEach((k, v) {
          levels['$k'] =
              LevelProgress.fromJson(Map<String, dynamic>.from(v as Map));
        });
      } catch (_) {/* corrupted state -> start fresh */}
    }
    if (save) await prefs.setString(_activeKey, active!.id);
  }

  Future<void> _save() async {
    if (active == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyFor(active!.id),
        jsonEncode({
          'xp': xp,
          'rk': streak,
          'rd': lastSolveDay,
          'gh': ghostStartDay,
          'lv': levels.map((k, v) => MapEntry(k, v.toJson())),
        }));
  }

  Future<void> _saveProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profilesKey,
        jsonEncode(profiles.map((e) => e.toJson()).toList()));
  }

  /// Create a fresh slot and make it active (starts from zero).
  Future<Profile> createProfile(String name, String emoji) async {
    final p = Profile(
        id: 'p${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim().isEmpty ? 'Jugador' : name.trim(),
        emoji: emoji);
    profiles.add(p);
    await _saveProfiles();
    await _loadProfile(p.id);
    await _save();
    notifyListeners();
    return p;
  }

  /// Switch to an existing slot.
  Future<void> switchProfile(String id) async {
    if (active?.id == id) return;
    await _loadProfile(id);
    notifyListeners();
  }

  /// Rename/recolor the active profile.
  Future<void> updateActive({String? name, String? emoji}) async {
    if (active == null) return;
    if (name != null && name.trim().isNotEmpty) active!.name = name.trim();
    if (emoji != null) active!.emoji = emoji;
    await _saveProfiles();
    notifyListeners();
  }

  LevelProgress of(String levelId) =>
      levels[levelId] ??= LevelProgress();

  /// Returns earned XP for this solve (first solve gives full XP).
  int recordSolve(String levelId, int levelXp, int stars) {
    final p = of(levelId);
    var earned = 0;
    if (!p.solved) {
      earned = levelXp;
      xp += levelXp;
      p.solved = true;
    }
    if (stars > p.stars) p.stars = stars;
    _bumpStreak();
    _save();
    notifyListeners();
    return earned;
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int _epochDay(DateTime d) =>
      d.millisecondsSinceEpoch ~/ 86400000;

  /// A solve on a new day extends the streak if it continues
  /// yesterday's, otherwise it restarts at 1.
  void _bumpStreak() {
    final now = DateTime.now();
    final today = _dayKey(now);
    if (lastSolveDay == today) return;
    streak = (lastSolveDay == _dayKey(now.subtract(const Duration(days: 1))))
        ? streak + 1
        : 1;
    lastSolveDay = today;
    ghostStartDay = ghostStartDay == 0 ? _epochDay(now) : ghostStartDay;
  }

  /// Ghost rival: Nano solves ~1 level every 2 days since the
  /// player's first solve — a gentle race like a real rival.
  int get ghostSolved => ghostStartDay == 0
      ? 0
      : ((_epochDay(DateTime.now()) - ghostStartDay) * 0.5).floor();

  /// Upsolving queue: attempted but never beaten. Clearing these is
  /// the core discipline — no failed problem stays unsolved.
  List<String> get pendingIds => [
        for (final e in levels.entries)
          if (e.value.attempts > 0 && !e.value.solved) e.key,
      ];

  void recordAttempt(String levelId) {
    of(levelId).attempts++;
    _save();
    notifyListeners();
  }

  void recordHint(String levelId) {
    final p = of(levelId);
    if (!p.hintUsed) {
      p.hintUsed = true;
      _save();
      notifyListeners();
    }
  }

  void saveCode(String levelId, String code, {List<dynamic>? blocksJson}) {
    final p = of(levelId);
    p.code = code;
    if (blocksJson != null) p.blocksJson = blocksJson;
    _save();
  }

  /// Campaign rule: the first level of every world is always unlocked,
  /// so the player can jump between worlds freely; inside a world,
  /// each level opens when the previous one is solved.
  bool isUnlocked(Level level, World world) {
    final idx = world.levels.indexWhere((l) => l.id == level.id);
    if (idx <= 0) return true;
    return levels[world.levels[idx - 1].id]?.solved ?? false;
  }

  int get totalStars =>
      levels.values.fold(0, (s, p) => s + p.stars);

  int get solvedCount => levels.values.where((p) => p.solved).length;

  /// Reset only the ACTIVE profile's progress (start from zero).
  Future<void> reset() async {
    xp = 0;
    levels.clear();
    final prefs = await SharedPreferences.getInstance();
    if (active != null) {
      await prefs.remove(_keyFor(active!.id));
    }
    notifyListeners();
  }
}

/// Player rank derived from XP.
class Rank {
  const Rank(this.key, this.minXp, this.color);
  final String key; // l10n key suffix: rank_bronze...
  final int minXp;
  final int color;
}

const kRanks = [
  Rank('rank_bronze', 0, 0xFFCD7F32),
  Rank('rank_silver', 2000, 0xFFC0C0C0),
  Rank('rank_gold', 5000, 0xFFFFD700),
  Rank('rank_platinum', 9000, 0xFF7FE7DC),
  Rank('rank_diamond', 14000, 0xFF6EC6FF),
  Rank('rank_ioi', 20000, 0xFFFF5252),
];

Rank rankForXp(int xp) {
  var r = kRanks.first;
  for (final cand in kRanks) {
    if (xp >= cand.minXp) r = cand;
  }
  return r;
}

Rank? nextRank(int xp) {
  for (final cand in kRanks) {
    if (xp < cand.minXp) return cand;
  }
  return null;
}
