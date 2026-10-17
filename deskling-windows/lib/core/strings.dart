import 'reminders.dart';
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
  startFocus('집중 시작하기 (25분)', 'Start Focus (25 min)'),
  stopFocus('집중 멈추기', 'Stop Focus'),
  focusStatus('집중하는 중: %d분 남음', 'Focusing: %d min left'),
  breakStatus('쉬는 중: %d분 남음', 'On a break: %d min left'),
  timer('타이머', 'Timer'),
  timerMinutes('%d분', '%d min'),
  cancelTimer('타이머 취소하기 (%d분 남음)', 'Cancel Timer (%d min left)'),
  stretchReminder('한 시간마다 스트레칭 알림', 'Stretch Reminder Every Hour'),
  focusEndedMessage('집중 시간이 끝났습니다. 이제 5분 동안 쉬는 시간입니다.', 'Focus time is over. Take a 5-minute break.'),
  breakEndedMessage('쉬는 시간이 끝났습니다.', 'Your break is over.'),
  stretchMessage('잠깐 일어나서 몸을 풀고 물을 마실 시간입니다.', 'Stand up, stretch, and drink some water.'),
  timerEndedMessage('타이머가 끝났습니다.', 'Your timer is up.'),
  loginItemFailed('로그인 항목을 바꾸지 못했습니다.', 'Could not change the login item.'),
  missingResources('기본 펫 그림을 찾을 수 없습니다.', 'The default pet images are missing.');

  const Txt(this.korean, this.english);
  final String korean;
  final String english;

  String of(Language language) => language == Language.korean ? korean : english;

  /// Fills the `%d` in texts such as [focusStatus].
  String withNumber(Language language, int number) => of(language).replaceAll('%d', '$number');
}

class PetPresentation {
  static PetPose pose({
    required bool isWalking,
    bool isHeld = false,
    bool isFalling = false,
    bool isHappy = false,
    bool isAlerting = false,
    bool isFocusing = false,
  }) {
    if (isHeld) return PetPose.drag;
    if (isFalling) return PetPose.fall;
    if (isHappy) return PetPose.happy;
    if (isAlerting) return PetPose.waiting;
    if (isFocusing) return PetPose.working;
    return isWalking ? PetPose.walk : PetPose.idle;
  }

  static String message(Reminder reminder, Language language) => switch (reminder) {
        Reminder.focusEnded => Txt.focusEndedMessage.of(language),
        Reminder.breakEnded => Txt.breakEndedMessage.of(language),
        Reminder.stretch => Txt.stretchMessage.of(language),
        Reminder.timerEnded => Txt.timerEndedMessage.of(language),
      };
}
