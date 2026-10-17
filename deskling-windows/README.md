# Deskling Pet for Windows

The Windows version of Deskling Pet, a desktop pet that walks along the taskbar. Built with Flutter.

- Click the pet to make it happy. Hold it to carry it around; let go and it floats back down.
- Double-click or right-click the pet, or click the tray icon, to open the menu (skin, size, hide, launch at login, quit).
- Skins go in `%APPDATA%\Deskling Pet\skins`, one folder per skin with `idle` (required) and optional `walk`, `happy`, `drag` and `fall` images (PNG or GIF) plus an optional `skin.json` (`name`, `height`).

It installs next to the original Deskling: the executable is `DesklingPet.exe`, settings and skins live in their own folders, and Launch at Login uses its own registry value.

## Build

On Windows with Flutter and Visual Studio (Desktop development with C++):

```
flutter pub get
dart analyze --fatal-infos
flutter test
flutter build windows --release
```

The app is in `build\windows\x64\runner\Release`. Ship the whole folder.
