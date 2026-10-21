/// Abstraction over the C++ interpreter backend.
///
/// Two implementations exist behind a conditional export:
///  - `runner_web.dart`: a Web Worker running JSCPP (Flutter web).
///  - `runner_io.dart`:  flutter_js (QuickJS) running JSCPP (Android/IO).
library;

/// What went wrong during a run, if anything.
enum RunError { none, parse, runtime, tle, outputLimit, engine, timeout }

/// The result of executing a program once.
class RunOutput {
  const RunOutput({
    required this.ok,
    this.exitCode = 0,
    this.output = '',
    this.error = RunError.none,
    this.detail = '',
    this.truncated = false,
  });

  final bool ok;
  final int exitCode;
  final String output;
  final RunError error;
  final String detail;
  final bool truncated;

  factory RunOutput.fromJson(Map<String, dynamic> j) {
    RunError kind;
    switch (j['error'] as String? ?? '') {
      case 'PARSE':
        kind = RunError.parse;
        break;
      case 'RUNTIME':
        kind = RunError.runtime;
        break;
      case 'TLE':
        kind = RunError.tle;
        break;
      case 'OUTPUT_LIMIT':
        kind = RunError.outputLimit;
        break;
      case 'ENGINE':
        kind = RunError.engine;
        break;
      default:
        kind = RunError.none;
    }
    return RunOutput(
      ok: j['ok'] == true,
      exitCode: (j['exitcode'] as num?)?.toInt() ?? 0,
      output: j['output'] as String? ?? '',
      error: kind,
      detail: j['detail'] as String? ?? '',
    );
  }
}

/// Runs a C++ program to completion, capturing stdout.
abstract class CppRunner {
  /// Execute [code] feeding [input] to stdin.
  ///
  /// [maxOps] caps interpreter steps (detects infinite loops);
  /// [timeout] is a wall-clock backstop.
  Future<RunOutput> run(
    String code,
    String input, {
    int maxOps = 2000000,
    Duration timeout = const Duration(seconds: 8),
  });

  void dispose();
}
