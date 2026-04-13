import 'dart:io';

void main() {
  var dir = Directory('lib');
  int textAlignRightCount = 0;
  int crossAxisAlignmentEndCount = 0;
  int textDirectionRtlCount = 0;

  for (var file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      textAlignRightCount += 'TextAlign.right'.allMatches(content).length;
      crossAxisAlignmentEndCount +=
          'CrossAxisAlignment.end'.allMatches(content).length;
      textDirectionRtlCount += 'TextDirection.rtl'.allMatches(content).length;
    }
  }

  print('TextAlign.right usages: $textAlignRightCount');
  print('CrossAxisAlignment.end usages: $crossAxisAlignmentEndCount');
  print('TextDirection.rtl usages: $textDirectionRtlCount');
}
