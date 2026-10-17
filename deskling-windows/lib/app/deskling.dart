import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

import '../core/bubble_guard.dart';
import '../core/input_box.dart';
import '../core/paths.dart';
import '../core/reminders.dart';
import '../core/skin.dart';
import '../core/strings.dart';
import 'login_item.dart';
import 'native.dart';
import 'pet_controller.dart';
import 'preferences.dart';
import 'sprite.dart';
import 'tray.dart';

/// Wires the pet, its reminders and the tray together, like the macOS AppDelegate.
class Deskling {
  Deskling({required this.native, required this.preferences, required this.language});

  final Native native;
  final Preferences preferences;
  final Language language;
  final paths = AppPaths.current();
  final sprites = SpriteCache();
  final reminders = Reminders();

  /// The reminder the pet is showing until it or its bubble is clicked.
  Reminder? _alert;
  final _bubbleGuard = BubbleGuard();

  /// False after the countdown bubble was clicked away, until the next focus session or timer starts or a reminder fires.
  bool _showCountdown = true;

  late final String _bundledSkinsDirectory =
      p.join(p.dirname(Platform.resolvedExecutable), 'data', 'flutter_assets', 'assets', 'skins');

  /// The default pet, stored as a null skin path.
  late final String _defaultSkinDirectory = p.join(_bundledSkinsDirectory, 'boy');

  /// The other bundled pet, stored by its absolute path like a user skin.
  late final String _girlSkinDirectory = p.join(_bundledSkinsDirectory, 'girl');

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
      ..onClicked = clearAlert
      ..onInspect = () => unawaited(tray.popUp());
    pet.hidden = preferences.petHidden;
    pet.start();

    if (preferences.stretchEnabled) reminders.setStretch(enabled: true, now: DateTime.now());
    Timer.periodic(const Duration(seconds: 1), (_) => _tickReminders());

    tray = Tray(language: language, state: _trayState, actions: _trayActions());
    await tray.start();
    return true;
  }

  // Reminders

  void _tickReminders() {
    final due = reminders.tick(DateTime.now());
    if (due.isNotEmpty) {
      _alert = due.last;
      _showCountdown = true;
    }
    _refreshPet();
  }

  void clearAlert() {
    _alert = null;
    _refreshPet();
  }

  /// A click on an alert clears it; a click on the countdown hides the countdown.
  void bubbleClicked() {
    final key = _bubbleGuard.shownKey;
    if (key == null || !_bubbleGuard.acceptsClick(DateTime.now())) return;
    if (key.startsWith('alert')) {
      clearAlert();
    } else {
      _showCountdown = false;
      _refreshPet();
    }
  }

  /// An alert shows `waiting`; a focus phase without one shows `working`. The bubble shows the alert or the countdown.
  /// A hidden pet shows no bubble.
  void _refreshPet() {
    final alert = _alert;
    final now = DateTime.now();
    pet.alerting = alert != null;
    pet.focusing = alert == null && reminders.phase == FocusPhase.focus;
    final content = preferences.petHidden
        ? null
        : PetPresentation.bubble(
            alert: alert, reminders: reminders, showCountdown: _showCountdown, now: now, language: language);
    _bubbleGuard.update(content?.key, now);
    pet.bubbleText = content?.text;
  }

  void _startTimer(int minutes) {
    reminders.startTimer(minutes, DateTime.now());
    _showCountdown = true;
    _refreshPet();
  }

  /// Asks for a timer length until the user types a valid one or cancels.
  Future<void> _askForTimer() async {
    final arguments = InputBox.arguments(title: _t(Txt.customTimerTitle), body: _t(Txt.customTimerBody), initial: '25');
    while (true) {
      final String answer;
      try {
        final result = await Process.run('powershell.exe', arguments, stdoutEncoding: utf8);
        answer = '${result.stdout}'.trim();
      } on Object {
        return;
      }
      if (answer.isEmpty) return;
      final minutes = Reminders.parseMinutes(answer);
      if (minutes != null) {
        _startTimer(minutes);
        return;
      }
      Native.alert(_t(Txt.customTimerTitle), _t(Txt.invalidDuration));
    }
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
    final skins = [
      SkinItem(null, _t(Txt.boySkin)),
      SkinItem(_girlSkinDirectory, _t(Txt.girlSkin)),
      ...userSkins,
    ];
    final selected = skins.any((skin) => skin.path == preferences.skinPath) ? preferences.skinPath : null;
    bool launchAtLogin;
    try {
      launchAtLogin = LoginItem.isEnabled;
    } on Object {
      launchAtLogin = false;
    }
    final now = DateTime.now();
    final phaseEnds = reminders.phaseEnds;
    final timerEnds = reminders.timerEnds;
    return TrayState(
      phase: reminders.phase,
      phaseMinutesLeft: phaseEnds == null ? 0 : Reminders.minutesLeft(phaseEnds, now),
      timerMinutesLeft: timerEnds == null ? null : Reminders.minutesLeft(timerEnds, now),
      stretchEnabled: reminders.stretchEnabled,
      skins: skins,
      selectedSkinPath: selected,
      sizeScale: preferences.sizeScale,
      petHidden: preferences.petHidden,
      launchAtLogin: launchAtLogin,
    );
  }

  TrayActions _trayActions() => TrayActions(
        startFocus: () {
          reminders.startFocus(DateTime.now());
          _showCountdown = true;
          _refreshPet();
        },
        stopFocus: () {
          reminders.stopFocus();
          _refreshPet();
        },
        startTimer: _startTimer,
        customTimer: () => unawaited(_askForTimer()),
        cancelTimer: () {
          reminders.cancelTimer();
          _refreshPet();
        },
        toggleStretch: () {
          final enabled = !reminders.stretchEnabled;
          reminders.setStretch(enabled: enabled, now: DateTime.now());
          preferences.stretchEnabled = enabled;
        },
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
          _refreshPet();
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
