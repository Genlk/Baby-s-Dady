import 'dart:convert';
import 'dart:typed_data';

import 'fs_bridge.dart';

FsBridge createFsBridge({String? rootOverride}) =>
    MemoryFsBridge(rootOverride: rootOverride);

class MemoryFsBridge implements FsBridge {
  MemoryFsBridge({String? rootOverride})
      : _root = rootOverride ?? '/memory/baby_s_dady';

  final String _root;
  final Map<String, Uint8List> _files = <String, Uint8List>{};
  final Set<String> _dirs = <String>{};

  @override
  Future<String> resolveRoot(String folderName) async {
    final path = '$_root/$folderName';
    _dirs.add(path);
    return path;
  }

  @override
  Future<void> ensureDirectory(String path) async {
    _dirs.add(path);
  }

  @override
  Future<bool> exists(String path) async =>
      _files.containsKey(path) || _dirs.contains(path);

  @override
  Future<void> writeBytes(String path, List<int> bytes) async {
    _files[path] = Uint8List.fromList(bytes);
  }

  @override
  Future<List<int>> readBytes(String path) async {
    final data = _files[path];
    if (data == null) {
      throw StateError('Missing file: $path');
    }
    return data;
  }

  @override
  Future<void> writeString(String path, String content) async {
    await writeBytes(path, utf8.encode(content));
  }

  @override
  Future<String> readString(String path) async {
    return utf8.decode(await readBytes(path));
  }

  @override
  Future<void> copyFile(String from, String to) async {
    final bytes = await readBytes(from);
    await writeBytes(to, bytes);
  }
}
