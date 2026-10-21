import 'runner.dart';

CppRunner createPlatformRunner() => const StubCppRunner();

/// Fallback used when neither dart.library.js nor dart.library.io apply.
class StubCppRunner implements CppRunner {
  const StubCppRunner();
  @override
  Future<RunOutput> run(String code, String input,
          {int maxOps = 2000000,
          Duration timeout = const Duration(seconds: 8)}) async =>
      const RunOutput(
          ok: false, error: RunError.engine, detail: 'unsupported platform');
  @override
  void dispose() {}
}
