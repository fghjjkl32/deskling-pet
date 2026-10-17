import 'package:deskling_pet/core/input_box.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('single quotes, typographic ones included, are doubled inside a quoted string', () {
    expect(InputBox.quote('plain'), "'plain'");
    expect(InputBox.quote("it's"), "'it''s'");
    expect(InputBox.quote('a\u2019b'), "'a\u2019\u2019b'");
    expect(InputBox.quote(''), "''");
  });

  test('the command shows an InputBox with body, title and initial text', () {
    final arguments = InputBox.arguments(title: "Timer's Length", body: '1:30처럼 씁니다.', initial: '25');
    expect(arguments.take(2), ['-NoProfile', '-Command']);
    expect(arguments, hasLength(3));
    expect(arguments[2], contains('Add-Type -AssemblyName Microsoft.VisualBasic;'));
    expect(arguments[2],
        endsWith("[Microsoft.VisualBasic.Interaction]::InputBox('1:30처럼 씁니다.', 'Timer''s Length', '25')"));
  });

  test('a command injection attempt stays inside the string', () {
    final command = InputBox.arguments(title: "x'); Remove-Item C:\\ -Recurse; ('", body: 'b')[2];
    expect(command, contains("InputBox('b', 'x''); Remove-Item C:\\ -Recurse; (''', '')"));
  });
}
