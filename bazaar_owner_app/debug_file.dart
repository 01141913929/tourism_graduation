import 'dart:io';

void main() {
  final path = 'assets/images/owners.png';
  final file = File(path);
  if (file.existsSync()) {
    print('File exists at $path');
    print('Absolute: ${file.absolute.path}');
  } else {
    print('File NOT found at $path');
    print('Current Dir: ${Directory.current.path}');
    print('Expected absolute: ${file.absolute.path}');
  }
}
