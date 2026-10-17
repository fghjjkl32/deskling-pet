import 'dart:async';

import 'package:tray_manager/tray_manager.dart';

import '../core/reminders.dart';
import '../core/strings.dart';

class SkinItem {
  const SkinItem(this.path, this.name);

  /// Null for the bundled default pet.
  final String? path;
  final String name;
}

/// A snapshot of everything the tray menu shows, taken each time it opens.
class TrayState {
  const TrayState({
    required this.phase,
    required this.phaseMinutesLeft,
    required this.timerMinutesLeft,
    required this.stretchEnabled,
    required this.skins,
    required this.selectedSkinPath,
    required this.sizeScale,
    required this.petHidden,
    required this.launchAtLogin,
  });

  /// The running focus phase, or null.
  final FocusPhase? phase;
  final int phaseMinutesLeft;

  /// Null when no timer is running.
  final int? timerMinutesLeft;
  final bool stretchEnabled;
  final List<SkinItem> skins;
  final String? selectedSkinPath;
  final double sizeScale;
  final bool petHidden;
  final bool launchAtLogin;
}

class TrayActions {
  const TrayActions({
    required this.startFocus,
    required this.stopFocus,
    required this.startTimer,
    required this.cancelTimer,
    required this.toggleStretch,
    required this.selectSkin,
    required this.openSkinsFolder,
    required this.setSize,
    required this.togglePet,
    required this.toggleLaunchAtLogin,
    required this.quit,
  });

  final void Function() startFocus;
  final void Function() stopFocus;
  final void Function(int minutes) startTimer;
  final void Function() cancelTimer;
  final void Function() toggleStretch;
  final void Function(String? path) selectSkin;
  final void Function() openSkinsFolder;
  final void Function(double scale) setSize;
  final void Function() togglePet;
  final void Function() toggleLaunchAtLogin;
  final void Function() quit;
}

/// The notification-area icon and its menu, which the pet can also open.
class Tray with TrayListener {
  Tray({required this.language, required this.state, required this.actions});

  static const sizes = [(Txt.sizeSmall, 0.75), (Txt.sizeMedium, 1.0), (Txt.sizeLarge, 1.5)];

  final Language language;
  final TrayState Function() state;
  final TrayActions actions;

  Future<void> start() async {
    await trayManager.setIcon('assets/tray.ico');
    await trayManager.setToolTip('Deskling Pet');
    trayManager.addListener(this);
  }

  Future<void> destroy() => trayManager.destroy();

  @override
  void onTrayIconMouseDown() => unawaited(popUp());

  @override
  void onTrayIconRightMouseDown() => unawaited(popUp());

  Future<void> popUp() async {
    await trayManager.setContextMenu(_menu(state()));
    // ignore: deprecated_member_use
    await trayManager.popUpContextMenu(bringAppToFront: true);
  }

  String _t(Txt text) => text.of(language);

  /// Windows menus treat `&` as a keyboard shortcut marker.
  static String _escape(String text) => text.replaceAll('&', '&&');

  Menu _menu(TrayState s) => Menu(items: [
        if (s.phase != null)
          MenuItem(
            label: (s.phase == FocusPhase.focus ? Txt.focusStatus : Txt.breakStatus).withNumber(language, s.phaseMinutesLeft),
            disabled: true,
          ),
        if (s.phase == null)
          MenuItem(label: _t(Txt.startFocus), onClick: (_) => actions.startFocus())
        else
          MenuItem(label: _t(Txt.stopFocus), onClick: (_) => actions.stopFocus()),
        MenuItem.submenu(
          label: _t(Txt.timer),
          submenu: Menu(items: [
            for (final minutes in Reminders.timerChoices)
              MenuItem(label: Txt.timerMinutes.withNumber(language, minutes), onClick: (_) => actions.startTimer(minutes)),
            if (s.timerMinutesLeft case final left?) ...[
              MenuItem.separator(),
              MenuItem(label: Txt.cancelTimer.withNumber(language, left), onClick: (_) => actions.cancelTimer()),
            ],
          ]),
        ),
        MenuItem.checkbox(
            label: _t(Txt.stretchReminder), checked: s.stretchEnabled, onClick: (_) => actions.toggleStretch()),
        MenuItem.separator(),
        MenuItem.submenu(
          label: _t(Txt.skin),
          submenu: Menu(items: [
            for (final skin in s.skins)
              MenuItem.checkbox(
                label: _escape(skin.name),
                checked: skin.path == s.selectedSkinPath,
                onClick: (_) => actions.selectSkin(skin.path),
              ),
            MenuItem.separator(),
            MenuItem(label: _t(Txt.openSkinsFolder), onClick: (_) => actions.openSkinsFolder()),
          ]),
        ),
        MenuItem.submenu(
          label: _t(Txt.size),
          submenu: Menu(items: [
            for (final (label, scale) in sizes)
              MenuItem.checkbox(
                label: _t(label),
                checked: (scale - s.sizeScale).abs() < 0.01,
                onClick: (_) => actions.setSize(scale),
              ),
          ]),
        ),
        MenuItem(label: _t(s.petHidden ? Txt.showPet : Txt.hidePet), onClick: (_) => actions.togglePet()),
        MenuItem.checkbox(
            label: _t(Txt.launchAtLogin), checked: s.launchAtLogin, onClick: (_) => actions.toggleLaunchAtLogin()),
        MenuItem.separator(),
        MenuItem(label: _t(Txt.quit), onClick: (_) => actions.quit()),
      ]);
}
