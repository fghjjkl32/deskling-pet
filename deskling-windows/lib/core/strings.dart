import 'skin.dart';

enum Language {
  korean,
  english;

  /// Follows the first preferred language, given as locale tags such as `ko-KR` or `ko_KR`.
  static Language current(List<String> preferred) =>
      preferred.isNotEmpty && preferred.first.toLowerCase().startsWith('ko') ? Language.korean : Language.english;
}

enum Txt {
  skin('스킨', 'Skin'),
  defaultSkin('기본 펫', 'Default pet'),
  openSkinsFolder('스킨 폴더 열기', 'Open Skins Folder'),
  size('크기', 'Size'),
  sizeSmall('작게', 'Small'),
  sizeMedium('보통', 'Medium'),
  sizeLarge('크게', 'Large'),
  hidePet('펫 숨기기', 'Hide Pet'),
  showPet('펫 보이기', 'Show Pet'),
  launchAtLogin('로그인할 때 실행하기', 'Launch at Login'),
  quit('종료하기', 'Quit Deskling Pet'),
  loginItemFailed('로그인 항목을 바꾸지 못했습니다.', 'Could not change the login item.'),
  missingResources('기본 펫 그림을 찾을 수 없습니다.', 'The default pet images are missing.');

  const Txt(this.korean, this.english);
  final String korean;
  final String english;

  String of(Language language) => language == Language.korean ? korean : english;
}

class PetPresentation {
  static PetPose pose({required bool isWalking, bool isHeld = false, bool isFalling = false, bool isHappy = false}) {
    if (isHeld) return PetPose.drag;
    if (isFalling) return PetPose.fall;
    if (isHappy) return PetPose.happy;
    return isWalking ? PetPose.walk : PetPose.idle;
  }
}
