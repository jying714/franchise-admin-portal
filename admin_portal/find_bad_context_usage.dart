import 'dart:io';

final badPatterns = [
  // Common misuses, extend as needed
  RegExp(
      r'final\s+[a-zA-Z0-9_]+\s*=\s*AppLocalizations\.of\s*\(\s*context\s*\)'),
  RegExp(r'final\s+[a-zA-Z0-9_]+\s*=\s*Theme\.of\s*\(\s*context\s*\)'),
  RegExp(r'AppLocalizations\.of\s*\(\s*context\s*\)[^;]*;'), // Standalone usage
  RegExp(r'Theme\.of\s*\(\s*context\s*\)[^;]*;'),
];

void main(List<String> args) {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('lib/ directory not found.');
    exit(1);
  }
  final dartFiles = libDir
      .listSync(recursive: true)
      .where((f) => f is File && f.path.endsWith('.dart'))
      .cast<File>();

  int totalWarnings = 0;
  for (final file in dartFiles) {
    final lines = file.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Skip obvious function/method body usage
      if (line.trimLeft().startsWith('//')) continue;

      for (final pattern in badPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          // Check: Is this line in a method body? (crude: look for build/method signature above)
          final preContext = lines.sublist(0, i).reversed.take(15).join('\n');
          final inMethod = RegExp(
                  r'(Widget|void|@override|Future|Stream|State|build)\s+[a-zA-Z0-9_]+\s*\(')
              .hasMatch(preContext);
          if (!inMethod) {
            totalWarnings++;
            print('\nWARNING: Potential bad context usage found:');
            print('File: ${file.path}');
            print('Line: ${i + 1}');
            print('  $line');
          }
        }
      }
    }
  }
  if (totalWarnings == 0) {
    print(
        'No bad AppLocalizations.of(context) or Theme.of(context) usages found at class level!');
  } else {
    print(
        '\nScan complete. $totalWarnings suspect usages found. Review above!');
  }
}
