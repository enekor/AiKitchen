import 'dart:io';

Future<String> readTextFile(String path) async {
  return await File(path).readAsString();
}
