import 'package:flutter/material.dart';

import 'l10n.dart';
import 'services/sfx.dart';
import 'ui/splash.dart';
import 'ui/theme.dart';

class CodeArenaApp extends StatelessWidget {
  const CodeArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: L.instance.lang,
      // First user gesture unlocks audio on web (autoplay policy).
      builder: (context, lang, _) => Listener(
        onPointerDown: (_) => Sfx.poke(),
        child: MaterialApp(
          title: 'CodeArena',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
