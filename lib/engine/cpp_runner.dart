import 'runner_stub.dart'
    if (dart.library.js) 'runner_web.dart'
    if (dart.library.io) 'runner_io.dart' as impl;

import 'runner.dart';

/// Platform-specific runner resolved at compile time.
CppRunner createRunner() => impl.createPlatformRunner();
