import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 本机设备身份（闲置手机监控端用）
class DeviceService {
  static const _idKey = 'device_id';
  static const _nameKey = 'device_name';
  static const _modeKey = 'app_mode'; // 'parent' | 'camera'

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_idKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_idKey, id);
    }
    return id;
  }

  Future<String> getDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) ?? '儿童房监控';
  }

  Future<void> setDeviceName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name.trim());
  }

  Future<String?> getAppMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modeKey);
  }

  Future<void> setAppMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode);
  }
}
