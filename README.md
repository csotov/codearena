# CodeArena ⚔️

Un juego para aprender **C++ y algoritmos (DSA)** jugando — pensado para
niños desde ~10 años con el camino hacia la **IOI** (Olimpiada
Internacional de Informática) como meta.

Learn **C++ and DSA** by fighting code battles — aimed at kids ~10+
on the road to competitive programming / IOI.

## Cómo funciona / How it works

- **Batallas de código**: cada nivel es un problema de juez online
  (entrada → salida) con ejemplos visibles y pruebas ocultas.
- **Bloques → C++ real**: los primeros niveles usan un editor de bloques
  que genera C++ de verdad (se ve el código generado en vivo). Luego se
  pasa a escribir código directamente.
- **Intérprete C++ local**: el código se ejecuta con
  [JSCPP](https://github.com/felixhao28/JSCPP), un intérprete de C++ en
  JavaScript. **100% offline**: sin servidor, sin instalar un compilador.
- **Juez integrado**: comparación de salida insensible a espacios
  (como los jueces reales), límite de pasos contra bucles infinitos,
  y timeouts.
- **Gamificación**: XP, estrellas por nivel (3 = resolver a la primera
  sin pistas), rangos Bronce → IOI, jefes al final de cada mundo.
- **Bilingüe ES/EN** desde el menú.

## El camino / The curriculum (8 mundos, ~70 niveles)

| Mundo | Tema | Niveles |
|-------|------|---------|
| 1 | `cout`, `cin`, variables, aritmética, `%` | 10 |
| 2 | `if/else`, comparaciones, `&&`, `\|\|` | 10 |
| 3 | `for`, `while`, acumuladores, dígitos, bucles anidados | 10 |
| 4 | Arreglos `int a[]`, `char s[]`, `strlen`, recorridos | 10 |
| 5 | Funciones, `return`, recursión (fact, fib, mcd, primos) | 10 |
| 6 | Burbuja, selección, búsqueda lineal y **binaria** | 8 |
| 7 | Pila, cola, frecuencias, paréntesis, merge | 8 |
| 8 | **Prefix sums, sliding window, greedy, DP, DFS, Kadane** | 8 |

## Ejecutar / Run

### Web (sin instalar nada para el jugador)

```bash
flutter pub get
flutter run -d chrome        # desarrollo
flutter build web --release  # producción → build/web/
```

El contenido de `build/web/` es estático: súbelo a GitHub Pages,
Netlify, itch.io o cualquier hosting. El workflow incluido lo publica
en GitHub Pages automáticamente.

### Android (APK)

```bash
flutter build apk --release            # un solo APK
flutter build apk --release --split-per-abi   # APKs más livianos
```

Requiere Android SDK. **Alternativa sin instalar nada**: sube el repo a
GitHub y el workflow `.github/workflows/build.yml` compila el APK y lo
deja como artefacto descargable.

## Arquitectura

```
lib/
  data/        mundos y niveles (contenido)
  engine/      runner (JSCPP vía flutter_js / Web Worker), juez, bloques
  services/    progreso persistente (SharedPreferences)
  ui/          mapa, pantalla de batalla, editores, resultados
assets/vendor/ JSCPP.es5.min.js + runner.js (wrapper con límite de pasos)
web/           jscpp_worker.js (worker para la versión web)
```

### Backend de ejecución

| Plataforma | Implementación |
|------------|----------------|
| Web        | Web Worker + JSCPP (terminable → timeout real) |
| Android    | flutter_js (QuickJS) + JSCPP |
| Tests      | runners falsos en `test/` |

`runner.js` usa el modo *debugger* de JSCPP para contar pasos y cortar
bucles infinitos de forma determinista (`maxOps` por nivel).

### Nota sobre C++ soportado

JSCPP soporta un subconjunto educativo de C++ (verificado end-to-end):
`iostream`, `cstdio`, `cstdlib`, `cstring`, `cmath`, `cctype`, `ctime`,
`iomanip`, arreglos C 1D/2D, `char[]`, funciones, recursión moderada.

**Limitaciones conocidas** (probadas en `tools/engine_test.js`):
- Sin `std::vector`, `std::string`, `<algorithm>` ni `struct` propios.
- `strcmp` de `cstring` está roto (los niveles comparan `s[i]` a mano).
- Las llamadas a función son costosas (~ms c/u): la recursión sirve
  solo para profundidades pequeñas; los niveles la usan así
  (fact, mcd, dígitos, DFS en rejillas ≤ 4×4) y fib se enseña iterativo.
- Bucles grandes son lentos: los niveles mantienen ≤ ~2k iteraciones.
- Sin compilador real ni `bits/stdc++.h`: las estructuras y ordenamientos
  se implementan **a mano** — además es lo correcto pedagógicamente para
  la IOI. Roadmap: niveles "pro" opcionales con compilador remoto.

## Estado / Status

MVP jugable completo: 8 mundos, ~66 niveles, bloques→código, juez,
progreso, bilingüe. Roadmap: más mundos (STL cuando haya backend de
compilación real), avatares/animaciones, sonidos, pistas adaptativas.
