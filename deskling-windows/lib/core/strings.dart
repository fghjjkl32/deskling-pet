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
  boySkin('남자아이', 'Boy'),
  girlSkin('여자아이', 'Girl'),
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
  customTimer('직접 입력하기…', 'Custom…'),
  customTimerTitle('타이머 시간', 'Timer Length'),
  customTimerBody(
    '몇 분 뒤에 알려 드릴지 입력합니다. 25처럼 분으로 쓰거나, 1:30처럼 시간과 분으로 씁니다.',
    'Enter how long to wait: minutes such as 25, or hours and minutes such as 1:30.',
  ),
  start('시작하기', 'Start'),
  cancel('취소', 'Cancel'),
  invalidDuration('1분에서 24시간 사이로 입력해야 합니다.', 'Enter a length between 1 minute and 24 hours.'),
  countdownFocus('집중', 'Focus'),
  countdownBreak('휴식', 'Break'),
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

  /// What the speech bubble shows: a due reminder, or else the time left on the focus session and the timer,
  /// one per line. `key` stays the same while the same kind of bubble counts down, so a click on it can be
  /// told apart from a click on a new bubble. Returns null when there is nothing to show.
  static ({String key, String text})? bubble({
    required Reminder? alert,
    required Reminders reminders,
    required bool showCountdown,
    required DateTime now,
    required Language language,
  }) {
    if (alert != null) return (key: 'alert-${alert.name}', text: message(alert, language));
    if (!showCountdown) return null;
    final lines = <String>[];
    var key = 'countdown';
    final phase = reminders.phase;
    final phaseEnds = reminders.phaseEnds;
    if (phase != null && phaseEnds != null) {
      final label = phase == FocusPhase.focus ? Txt.countdownFocus : Txt.countdownBreak;
      lines.add('${label.of(language)} ${Reminders.clock(phaseEnds, now)}');
      key += '-${phase.name}';
    }
    final timerEnds = reminders.timerEnds;
    if (timerEnds != null) {
      lines.add('${Txt.timer.of(language)} ${Reminders.clock(timerEnds, now)}');
      key += '-timer';
    }
    return lines.isEmpty ? null : (key: key, text: lines.join('\n'));
  }

  static String message(Reminder reminder, Language language) => switch (reminder) {
        Reminder.focusEnded => Txt.focusEndedMessage.of(language),
        Reminder.breakEnded => Txt.breakEndedMessage.of(language),
        Reminder.stretch => Txt.stretchMessage.of(language),
        Reminder.timerEnded => Txt.timerEndedMessage.of(language),
      };
}
