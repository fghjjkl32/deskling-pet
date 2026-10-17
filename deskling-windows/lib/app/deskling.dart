import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

import '../core/paths.dart';
import '../core/skin.dart';
import '../core/strings.dart';
import 'login_item.dart';
import 'native.dart';
import 'pet_controller.dart';
import 'preferences.dart';
import 'sprite.dart';
import 'tray.dart';

/// Wires the pet and the tray together, like the macOS AppDelegate.
class Deskling {
  Deskling({required this.native, required this.preferences, required this.language});

  final Native native;
  final Preferences preferences;
  final Language language;
  final paths = AppPaths.current();
  final sprites = SpriteCache();

  late final String _defaultSkinDirectory = p.join(
      p.dirname(Platform.resolvedExecutable), 'data', 'flutter_assets', 'assets', 'skins', 'default');

  late final PetController pet;
  late final Tray tray;

  String _t(Txt text) => text.of(language);

  /// Returns false when the default skin is missing; the caller quits.
  Future<bool> start() async {
    final skin = _currentSkin();
    if (skin == null) {
      Native.alert(_t(Txt.missingResources), _defaultSkinDirectory);
      return false;
    }
    Directory(paths.skinsDirectory).createSync(recursive: true);
    try {
      LoginItem.repairPath();
    } on Object {
      // The menu still shows the real state.
    }

    pet = PetController(native, skin, preferences.sizeScale, startX: preferences.petX, monitorId: preferences.monitorId)
      ..onDropped = (x, monitorId) {
        preferences.petX = x;
        preferences.monitorId = monitorId;
      }
      ..onInspect = () => unawaited(tray.popUp());
    pet.hidden = preferences.petHidden;
    pet.start();

    tray = Tray(language: language, state: _trayState, actions: _trayActions());
    await tray.start();
    return true;
  }

  // Skins

  Skin? _currentSkin() {
    final path = preferences.skinPath;
    if (path != null) {
      final skin = SkinLoader.load(path);
      if (skin != null) return skin;
    }
    return SkinLoader.load(_defaultSkinDirectory);
  }

  void _applyCurrentSkin() {
    final skin = _currentSkin();
    if (skin == null) return;
    sprites.clear();
    pet.apply(skin: skin, sizeScale: preferences.sizeScale);
  }

  // Tray

  TrayState _trayState() {
    final userSkins = SkinLoader.list(paths.skinsDirectory).map((skin) => SkinItem(skin.directory, skin.name)).toList();
    final selected = userSkins.any((skin) => skin.path == preferences.skinPath) ? preferences.skinPath : null;
    bool launchAtLogin;
    try {
      launchAtLogin = LoginItem.isEnabled;
    } on Object {
      launchAtLogin = false;
    }
    return TrayState(
      skins: [SkinItem(null, _t(Txt.defaultSkin)), ...userSkins],
      selectedSkinPath: selected,
      sizeScale: preferences.sizeScale,
      petHidden: preferences.petHidden,
      launchAtLogin: launchAtLogin,
    );
  }

  TrayActions _trayActions() => TrayActions(
        selectSkin: (path) {
          preferences.skinPath = path;
          _applyCurrentSkin();
        },
        openSkinsFolder: () {
          Directory(paths.skinsDirectory).createSync(recursive: true);
          unawaited(Process.run('explorer.exe', [paths.skinsDirectory]));
        },
        setSize: (scale) {
          preferences.sizeScale = scale;
          _applyCurrentSkin();
        },
        togglePet: () {
          preferences.petHidden = !preferences.petHidden;
          pet.hidden = preferences.petHidden;
          unawaited(preferences.petHidden ? windowManager.hide() : windowManager.show(inactive: true));
        },
        toggleLaunchAtLogin: () {
          try {
            LoginItem.set(!LoginItem.isEnabled);
          } on Object catch (error) {
            Native.alert(_t(Txt.loginItemFailed), '$error');
          }
        },
        quit: () => unawaited(quit()),
      );

  Future<void> quit() async {
    await tray.destroy();
    exit(0);
  }
}
