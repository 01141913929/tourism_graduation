import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  int totalFilesModified = 0;

  for (final file in files) {
    String content = file.readAsStringSync();
    bool modified = false;

    // Fix absolute alignments
    if (content.contains('TextAlign.right')) {
      content = content.replaceAll('TextAlign.right', 'TextAlign.start');
      modified = true;
    }

    // CrossAxisAlignment.end in typical Arabic-first apps designed with LTR in mind
    // actually means "Left" in RTL and "Right" in LTR. We want it to be "Start"
    // to be "Right" in RTL and "Left" in LTR.
    if (content.contains('CrossAxisAlignment.end')) {
      // Avoid replacing MainAxisAlignment.end if mistakenly matching, but we match CrossAxisAlignment
      content = content.replaceAll(
          'CrossAxisAlignment.end', 'CrossAxisAlignment.start');
      modified = true;
    }

    if (content.contains('textDirection: TextDirection.rtl')) {
      // Remove hardcoded textDirection: TextDirection.rtl to let Directionality handle it
      content = content.replaceAll(
          RegExp(r'textDirection:\s*TextDirection\.rtl\s*,?'), '');
      modified = true;
    }

    if (modified) {
      file.writeAsStringSync(content);
      totalFilesModified++;
      print('Modified: ${file.path}');
    }
  }

  print('Total files modified: $totalFilesModified');
}
