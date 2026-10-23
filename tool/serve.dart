// Tiny static file server for the release web build.
// Run:  C:\flutter\bin\cache\dart-sdk\bin\dart.exe tool\serve.dart [port]
// Serves build/web on http://localhost:8080 (or your LAN IP).
import 'dart:io';

const _types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.wasm': 'application/wasm',
  '.mp4': 'video/mp4',
  '.webm': 'video/webm',
  '.map': 'application/json',
};

Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? int.parse(args[0]) : 8080;
  final root = Directory('build/web');
  if (!root.existsSync()) {
    stderr.writeln('build/web no existe — corre primero: flutter build web');
    exit(1);
  }
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('CodeArena servido en http://localhost:$port');
  await for (final req in server) {
    try {
      var path = Uri.decodeComponent(req.uri.path);
      if (path == '/' || path.isEmpty) path = '/index.html';
      var file = File('${root.path}$path');
      if (!file.existsSync()) file = File('${root.path}/index.html');
      final ext = path.contains('.')
          ? path.substring(path.lastIndexOf('.'))
          : '.html';
      req.response.headers
        ..contentType = ContentType.parse(
            _types[ext] ?? 'application/octet-stream')
        ..set('Cache-Control', 'no-cache');
      await file.openRead().pipe(req.response);
    } catch (_) {
      req.response.statusCode = 404;
      await req.response.close();
    }
  }
}
