import 'dart:io';

import 'package:path/path.dart' as p;

/// Windows locations, computed from the environment so tests can pass their own.
class AppPaths {
  AppPaths(this.environment, {p.Context? context}) : _windows = context ?? p.context;

  factory AppPaths.current() => AppPaths(Platform.environment);

  final Map<String, String> environment;
  final p.Context _windows;

  String get _appData => environment['APPDATA'] ?? _windows.join(_home, 'AppData', 'Roaming');
  String get _home => environment['USERPROFILE'] ?? environment['HOME'] ?? '';

  String get supportDirectory => _windows.join(_appData, 'Deskling Pet');
  String get skinsDirectory => _windows.join(supportDirectory, 'skins');
}
