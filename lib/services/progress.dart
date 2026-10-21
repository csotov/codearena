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

/// Global persistent progress: XP, solved levels, saved code, language.
class Progress extends ChangeNotifier {
  Progress._();
  static final Progress instance = Progress._();

  static const _prefsKey = 'codearena_progress_v1';

  int xp = 0;
  final Map<String, LevelProgress> levels = {};

  Future<void>? _loading;

  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        xp = (j['xp'] as num?)?.toInt() ?? 0;
        (j['lv'] as Map?)?.forEach((k, v) {
          levels['$k'] =
              LevelProgress.fromJson(Map<String, dynamic>.from(v as Map));
        });
      } catch (_) {/* corrupted state -> start fresh */}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefsKey,
        jsonEncode({
          'xp': xp,
          'lv': levels.map((k, v) => MapEntry(k, v.toJson())),
        }));
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
    _save();
    notifyListeners();
    return earned;
  }

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

  Future<void> reset() async {
    xp = 0;
    levels.clear();
    _loading = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
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
