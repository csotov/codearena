import 'package:flutter/material.dart';

import 'app.dart';
import 'services/progress.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Progress.instance.ensureLoaded();
  runApp(const CodeArenaApp());
}
