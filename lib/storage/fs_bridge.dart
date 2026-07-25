/// 跨平台极简文件系统桥：移动端走真实磁盘，Web 走内存。
abstract class FsBridge {
  Future<String> resolveRoot(String folderName);

  Future<void> ensureDirectory(String path);

  Future<bool> exists(String path);

  Future<void> writeBytes(String path, List<int> bytes);

  Future<List<int>> readBytes(String path);

  Future<void> writeString(String path, String content);

  Future<String> readString(String path);

  Future<void> copyFile(String from, String to);
}
