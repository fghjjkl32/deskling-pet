# Deskling Pet

A desktop pet for macOS and Windows.

Deskling Pet walks along the bottom of your screen and takes a rest now and then. It needs nothing else to run: no account, no network, no other app.

- Click the pet to make it happy.
- Hold the pet to make it run, and let go in mid-air to watch it float down.
- Double-click or right-click the pet to open its menu.
- Swap in your own pet with a folder of GIF or PNG images.

Deskling Pet has no window of its own: there is the pet, and a paw icon in the macOS menu bar or the Windows notification area.

Deskling Pet is the standalone sibling of [Deskling](https://github.com/fghjjkl32/deskling), the pet that reacts to Claude Code. The two can be installed side by side.

[한국어 설명](README.ko.md)

## Install

Download the latest files from [Releases](https://github.com/fghjjkl32/deskling-pet/releases/latest).

### macOS

Requires macOS 13 or later.

1. Download `DesklingPet-x.y.z.dmg`.
2. Open the DMG and drag **Deskling Pet** into **Applications**.
3. Open Deskling Pet. macOS will refuse the first time, because the app is not notarized by Apple.
4. Open **System Settings > Privacy & Security**, scroll down, and click **Open Anyway** next to the Deskling Pet message.

If you prefer the terminal, this does the same as steps 3 and 4:

```bash
xattr -dr com.apple.quarantine "/Applications/Deskling Pet.app"
```

### Windows

Requires 64-bit Windows 10 or 11.

1. Download `DesklingPet-windows-x.y.z.zip` and unzip it anywhere.
2. Run `DesklingPet.exe` in the `DesklingPet` folder.
3. Deskling Pet is not signed, so Windows shows "Windows protected your PC" the first time. Choose **More info**, then **Run anyway**.

The pet walks along the taskbar. If the paw icon is hidden, click **^** in the notification area.

## Custom skins

Choose **Skin > Open Skins Folder** from the menu, create a folder, and put your images in it. The folder is `~/Library/Application Support/Deskling Pet/skins/` on macOS and `%APPDATA%\Deskling Pet\skins\` on Windows; the same skin folder works on both.

```
skins/my-pet/
  idle.gif      resting (required)
  walk.gif      walking
  happy.gif     after you click the pet
  drag.gif      held with the mouse (running)
  fall.gif      floating down after you let go
  skin.json     optional
```

- Each file can be a GIF, an animated PNG, or a still PNG (`.gif` or `.png`).
- Only `idle` is required. Missing poses use the `idle` image.
- Without `drag`, the pet runs by playing `walk` at double speed. Without `fall`, it uses the `drag` image.
- Draw the pet facing right. Deskling Pet flips it when it walks left.
- `skin.json` can set a display name and a height in points: `{ "name": "My Pet", "height": 120 }`.

A Deskling skin works too; rename its `done` image to `happy`.

Then pick your skin from the **Skin** menu. Only share images you have the right to share.

## Uninstall

**macOS**: choose **Quit Deskling Pet**, then delete `Deskling Pet.app` and the folder `~/Library/Application Support/Deskling Pet`.

**Windows**: turn off **Launch at Login** if you turned it on, choose **Quit Deskling Pet**, then delete the unzipped `DesklingPet` folder and `%APPDATA%\Deskling Pet`.

## Build from source

**macOS**: Xcode (or its command line tools) with Swift 5.9 or later.

```bash
swift test
scripts/bundle.sh 0.1.0   # creates "dist/Deskling Pet.app"
```

**Windows**: Flutter 3.44 and Visual Studio with the "Desktop development with C++" workload. The app lives in `deskling-windows/`.

```bash
cd deskling-windows
flutter test
flutter build windows --release
```

## License

Code is released under the [MIT License](LICENSE). The default pet is a CC0 cat by shuaa (megupets.com); see [CREDITS.md](CREDITS.md).
