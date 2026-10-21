import 'package:flutter/material.dart';

import 'l10n.dart';
import 'ui/map_screen.dart';
import 'ui/theme.dart';

class CodeArenaApp extends StatelessWidget {
  const CodeArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: L.instance.lang,
      builder: (context, lang, _) => MaterialApp(
        title: 'CodeArena',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const MapScreen(),
      ),
    );
  }
}
