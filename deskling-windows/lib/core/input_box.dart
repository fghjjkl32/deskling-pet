/// Builds the PowerShell call that asks for a line of text with the Visual Basic InputBox.
class InputBox {
  /// PowerShell treats the typographic single quotes as quote marks too, so each is doubled like `'`.
  static String quote(String text) => "'${text.replaceAllMapped(RegExp('[\'‘’‚‛]'), (m) => '${m[0]}${m[0]}')}'";

  /// Arguments for `powershell.exe`. The answer comes back on standard output in UTF-8; an empty answer means cancelled.
  static List<String> arguments({required String title, required String body, String initial = ''}) => [
        '-NoProfile',
        '-Command',
        '[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; '
            'Add-Type -AssemblyName Microsoft.VisualBasic; '
            '[Microsoft.VisualBasic.Interaction]::InputBox(${quote(body)}, ${quote(title)}, ${quote(initial)})',
      ];
}
