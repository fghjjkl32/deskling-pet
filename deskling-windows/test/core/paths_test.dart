import 'package:deskling_pet/core/paths.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('support files live under APPDATA', () {
    final paths = AppPaths({'APPDATA': r'C:\Users\Me\AppData\Roaming', 'USERPROFILE': r'C:\Users\Me'}, context: p.windows);
    expect(paths.supportDirectory, r'C:\Users\Me\AppData\Roaming\Deskling Pet');
    expect(paths.skinsDirectory, r'C:\Users\Me\AppData\Roaming\Deskling Pet\skins');
  });

  test('without APPDATA the roaming folder is found from the profile', () {
    final paths = AppPaths({'USERPROFILE': r'C:\Users\Me'}, context: p.windows);
    expect(paths.supportDirectory, r'C:\Users\Me\AppData\Roaming\Deskling Pet');
  });
}
