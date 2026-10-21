import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'runner.dart';

CppRunner createPlatformRunner() => WebCppRunner();

/// Web runner: a persistent dedicated Web Worker executes JSCPP off the
/// UI thread. Calls are serialized (one outstanding run at a time,
/// which matches the judge's sequential usage). On timeout the worker
/// is terminated and lazily respawned.
class WebCppRunner implements CppRunner {
  web.Worker? _worker;
  Completer<RunOutput>? _pending;

  web.Worker _ensureWorker() {
    if (_worker != null) return _worker!;
    final w = web.Worker('jscpp_worker.js'.toJS);
    w.onmessage = ((web.MessageEvent event) {
      final data = event.data;
      final p = _pending;
      if (p == null || p.isCompleted) return;
      if (data.isA<JSString>()) {
        try {
          final parsed = jsonDecode((data as JSString).toDart);
          if (parsed is Map<String, dynamic>) {
            p.complete(RunOutput.fromJson(parsed));
            return;
          }
        } catch (_) {}
      }
      p.complete(const RunOutput(
          ok: false, error: RunError.engine, detail: 'bad worker message'));
    }).toJS;
    w.onerror = ((web.Event event) {
      final p = _pending;
      if (p != null && !p.isCompleted) {
        p.complete(const RunOutput(
            ok: false, error: RunError.engine, detail: 'worker error'));
      }
    }).toJS;
    _worker = w;
    return w;
  }

  @override
  Future<RunOutput> run(
    String code,
    String input, {
    int maxOps = 2000000,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    // Serialize concurrent runs: wait for any in-flight call to settle.
    while (_pending != null && !_pending!.isCompleted) {
      await Future<void>.delayed(const Duration(milliseconds: 15));
    }
    final w = _ensureWorker();
    final completer = Completer<RunOutput>();
    _pending = completer;
    try {
      w.postMessage(<String, Object>{
        'code': code,
        'input': input,
        'maxSteps': maxOps,
      }.jsify());
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      _restart();
      return const RunOutput(ok: false, error: RunError.timeout);
    } finally {
      if (identical(_pending, completer)) _pending = null;
    }
  }

  void _restart() {
    _worker?.terminate();
    _worker = null;
    _pending = null;
  }

  @override
  void dispose() => _restart();
}
