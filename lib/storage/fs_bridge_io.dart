import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'fs_bridge.dart';

FsBridge createFsBridge({String? rootOverride}) =>
    IoFsBridge(rootOverride: rootOverride);

class IoFsBridge implements FsBridge {
  IoFsBridge({this.rootOverride});

  final String? rootOverride;

  @override
  Future<String> resolveRoot(String folderName) async {
    if (rootOverride != null) {
      final dir = Directory('$rootOverride/$folderName');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return dir.path;
    }
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$folderName');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir.path;
  }

  @override
  Future<void> ensureDirectory(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  @override
  Future<bool> exists(String path) async {
    return File(path).existsSync() || Directory(path).existsSync();
  }

  @override
  Future<void> writeBytes(String path, List<int> bytes) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<List<int>> readBytes(String path) => File(path).readAsBytes();

  @override
  Future<void> writeString(String path, String content) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content, flush: true);
  }

  @override
  Future<String> readString(String path) => File(path).readAsString();

  @override
  Future<void> copyFile(String from, String to) async {
    final target = File(to);
    await target.parent.create(recursive: true);
    await File(from).copy(to);
  }
}
