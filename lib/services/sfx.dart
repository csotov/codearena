import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Tiny synthesized sound effects — no audio assets needed.
/// A short victory arpeggio (C5 E5 G5 C6) rendered to WAV in memory.
class Sfx {
  Sfx._();
  static final AudioPlayer _player = AudioPlayer();
  static Uint8List? _victoryWav;

  static Future<void> victory() async {
    try {
      _victoryWav ??= _synthVictory();
      await _player.stop();
      await _player.play(BytesSource(_victoryWav!));
    } catch (_) {
      // Audio is a bonus — never let it break the game.
    }
  }

  static Future<void> dispose() => _player.dispose();

  /// 16-bit PCM mono WAV: C5-E5-G5-C6 arpeggio + sparkle tail.
  static Uint8List _synthVictory() {
    const sr = 22050;
    // [freq, startSec, durSec]
    const notes = [
      [523.25, 0.00, 0.16],
      [659.25, 0.14, 0.16],
      [783.99, 0.28, 0.16],
      [1046.50, 0.42, 0.34],
      [1567.98, 0.60, 0.30], // G6 sparkle
    ];
    const total = 0.95;
    final n = (sr * total).round();
    final samples = Float32List(n);
    for (final nt in notes) {
      final f = nt[0], start = (nt[1] * sr).round(), dur = (nt[2] * sr).round();
      for (var i = 0; i < dur && start + i < n; i++) {
        final t = i / sr;
        // sine + soft 3rd harmonic for a brighter chime
        var s = math.sin(2 * math.pi * f * t) +
            0.25 * math.sin(2 * math.pi * f * 3 * t);
        // attack/decay envelope
        final env = math.min(1.0, t / 0.015) *
            math.exp(-3.0 * t / (nt[2] + 0.001));
        samples[start + i] += (s * env * 0.5).toDouble();
      }
    }
    // normalize & write WAV
    var peak = 0.001;
    for (final s in samples) {
      if (s.abs() > peak) peak = s.abs();
    }
    final pcm = ByteData(44 + n * 2);
    void wStr(int off, String v) {
      for (var i = 0; i < 4; i++) {
        pcm.setUint8(off + i, v.codeUnitAt(i));
      }
    }

    wStr(0, 'RIFF');
    pcm.setUint32(4, 36 + n * 2, Endian.little);
    wStr(8, 'WAVE');
    wStr(12, 'fmt ');
    pcm.setUint32(16, 16, Endian.little);
    pcm.setUint16(20, 1, Endian.little); // PCM
    pcm.setUint16(22, 1, Endian.little); // mono
    pcm.setUint32(24, sr, Endian.little);
    pcm.setUint32(28, sr * 2, Endian.little);
    pcm.setUint16(32, 2, Endian.little);
    pcm.setUint16(34, 16, Endian.little);
    wStr(36, 'data');
    pcm.setUint32(40, n * 2, Endian.little);
    for (var i = 0; i < n; i++) {
      pcm.setInt16(44 + i * 2, (samples[i] / peak * 30000).round(),
          Endian.little);
    }
    return pcm.buffer.asUint8List();
  }
}
