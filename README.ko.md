# Deskling Pet

macOS와 Windows에서 쓰는 데스크톱 펫입니다.

Deskling Pet은 화면 아래를 걸어 다니다가 가끔 쉽니다. 실행하는 데 다른 것이 필요하지 않습니다. 계정도, 네트워크도, 다른 앱도 쓰지 않습니다.

- 25분 집중 타이머를 켜면 펫이 옆에서 함께 일하다가, 5분 동안 쉴 때가 되면 알려 줍니다.
- 타이머를 맞추거나, 한 시간마다 일어나서 스트레칭하라는 알림을 받을 수 있습니다.
- 펫을 클릭하면 기뻐합니다.
- 펫을 마우스로 잡고 있으면 달리고, 공중에서 놓으면 천천히 떨어집니다.
- 펫을 더블클릭하거나 오른쪽 클릭하면 메뉴가 열립니다.
- GIF나 PNG 그림을 담은 폴더 하나로 펫을 원하는 캐릭터로 바꿀 수 있습니다.

Deskling Pet에는 별도의 창이 없습니다. 펫과, macOS 메뉴 막대 또는 Windows 알림 영역의 발바닥 아이콘만 있습니다.

Deskling Pet은 Claude Code에 반응하는 펫인 [Deskling](https://github.com/fghjjkl32/deskling)에서 그 기능을 뺀 판입니다. 두 앱을 함께 설치해도 됩니다.

[English](README.md)

## 설치하기

[Releases](https://github.com/fghjjkl32/deskling-pet/releases/latest)에서 최신 파일을 내려받습니다.

### macOS

macOS 13 이상이 필요합니다.

1. `DesklingPet-x.y.z.dmg`를 내려받습니다.
2. DMG를 열고 **Deskling Pet**을 **Applications** 폴더로 끌어다 놓습니다.
3. Deskling Pet을 엽니다. Apple의 공증을 받지 않은 앱이라서 처음에는 macOS가 실행을 막습니다.
4. **시스템 설정 > 개인정보 보호 및 보안**을 열고 아래로 내려가서, Deskling Pet 안내 옆에 있는 **그래도 열기**를 누릅니다.

터미널이 편하다면 3번과 4번 대신 다음 명령을 실행해도 됩니다.

```bash
xattr -dr com.apple.quarantine "/Applications/Deskling Pet.app"
```

### Windows

64비트 Windows 10 또는 11이 필요합니다.

1. `DesklingPet-windows-x.y.z.zip`을 내려받아 원하는 곳에 압축을 풉니다.
2. `DesklingPet` 폴더에 있는 `DesklingPet.exe`를 실행합니다.
3. 서명하지 않은 앱이라서 처음에는 "Windows의 PC 보호" 창이 나옵니다. **추가 정보**를 누른 다음 **실행**을 누릅니다.

펫은 작업 표시줄 위를 걸어 다닙니다. 발바닥 아이콘이 보이지 않으면 알림 영역의 **^**를 누릅니다.

## 집중 타이머, 타이머, 스트레칭 알림

발바닥 아이콘을 누르거나 펫을 더블클릭하면 메뉴가 열립니다.

| 메뉴 | 동작 |
|---|---|
| **집중 시작하기 (25분)** | 펫이 앉아서 일합니다. 25분이 지나면 쉬라고 알려 주고, 5분이 더 지나면 쉬는 시간이 끝났다고 알려 줍니다. **집중 멈추기**를 누르면 도중에 끝납니다. 메뉴에 남은 시간이 분 단위로 나옵니다. |
| **타이머** | 5, 10, 15, 30, 60분 중에서 고릅니다. 시간이 다 되면 펫이 알려 줍니다. **타이머 취소하기**를 누르면 멈춥니다. |
| **한 시간마다 스트레칭 알림** | 한 시간마다 일어나서 몸을 풀고 물을 마시라고 알려 줍니다. 집중하는 동안과 그 뒤의 쉬는 시간에는 울리지 않고, 쉬는 시간이 끝난 때부터 다시 한 시간을 셉니다. 앱을 다시 실행해도 설정이 유지됩니다. |

알림이 울리면 펫이 멈추고 말풍선을 띄웁니다. 말풍선이나 펫을 클릭하면 닫힙니다. 펫을 숨긴 동안에도 알림 시간은 계속 흐르지만 말풍선은 나오지 않습니다.

## 스킨 바꾸기

앱에는 캐릭터 두 개가 들어 있습니다. 기본은 **남자아이**이고, **여자아이**도 **스킨** 메뉴에서 고를 수 있습니다.

직접 만들려면 메뉴에서 **스킨 > 스킨 폴더 열기**를 고르고, 폴더를 하나 만들어 그림을 넣습니다. macOS에서는 `~/Library/Application Support/Deskling Pet/skins/`이고 Windows에서는 `%APPDATA%\Deskling Pet\skins\`입니다. 같은 스킨 폴더를 두 운영체제에서 그대로 쓸 수 있습니다.

```
skins/my-pet/
  idle.gif      쉬는 모습 (필수)
  walk.gif      걷는 모습
  happy.gif     펫을 클릭했을 때
  working.gif   집중하는 동안
  waiting.gif   알림을 보여 줄 때
  drag.gif      마우스로 잡고 있을 때 (달리기)
  fall.gif      놓은 뒤 떨어질 때
  skin.json     선택
```

- 그림은 GIF, 움직이는 PNG, 정지한 PNG 중 무엇이든 됩니다(`.gif` 또는 `.png`).
- `idle`만 있으면 됩니다. 없는 동작은 `idle` 그림으로 보여 줍니다.
- `drag`가 없으면 `walk`를 두 배 속도로 재생해서 달리게 합니다. `fall`이 없으면 `drag` 그림을 씁니다.
- 펫은 오른쪽을 보도록 그립니다. 왼쪽으로 걸을 때는 Deskling Pet이 좌우를 뒤집습니다.
- `skin.json`에는 표시 이름과 포인트 단위의 높이를 적을 수 있습니다: `{ "name": "My Pet", "height": 120 }`.

Deskling 스킨도 그대로 쓸 수 있습니다. `done` 그림의 이름만 `happy`로 바꾸면 됩니다.

정지 그림 한 장으로 기본 캐릭터처럼 움직이는 스킨을 만들려면 `python3 scripts/make-skin.py drawing.png skins/my-pet "My Pet"`을 실행합니다(Pillow가 필요합니다). 그다음 **스킨** 메뉴에서 고릅니다. 공유할 권리가 있는 그림만 공유해야 합니다.

## 삭제하기

**macOS**: **종료하기**를 고른 다음 `Deskling Pet.app`과 `~/Library/Application Support/Deskling Pet` 폴더를 지웁니다.

**Windows**: **로그인할 때 실행하기**를 켰다면 끄고 **종료하기**를 고릅니다. 그다음 압축을 푼 `DesklingPet` 폴더와 `%APPDATA%\Deskling Pet`을 지웁니다.

## 소스에서 빌드하기

**macOS**: Swift 5.9 이상이 들어 있는 Xcode나 Command Line Tools가 필요합니다.

```bash
swift test
scripts/bundle.sh 0.1.0   # "dist/Deskling Pet.app"을 만듭니다
```

**Windows**: Flutter 3.44와, "C++를 사용한 데스크톱 개발" 워크로드를 설치한 Visual Studio가 필요합니다. 앱은 `deskling-windows/`에 있습니다.

```bash
cd deskling-windows
flutter test
flutter build windows --release
```

## 라이선스

코드는 [MIT 라이선스](LICENSE)로 공개합니다. 기본 캐릭터는 프로젝트 작성자가 직접 그렸습니다. 자세한 내용은 [CREDITS.md](CREDITS.md)에 있습니다.
