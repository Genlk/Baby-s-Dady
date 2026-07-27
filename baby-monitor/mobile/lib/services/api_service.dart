import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/analysis_result.dart';

class ApiService {
  static const _defaultBaseUrl = 'http://10.0.2.2:8000'; // Android 模拟器访问本机
  static const _prefKey = 'api_base_url';

  String _baseUrl = _defaultBaseUrl;

  String get baseUrl => _baseUrl;

  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_prefKey) ?? _defaultBaseUrl;
  }

  Future<void> saveBaseUrl(String url) async {
    _baseUrl = url.replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _baseUrl);
  }

  Future<bool> checkHealth() async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<AnalysisResult> analyzeImage(Uint8List imageBytes) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/v1/analyze/image'),
    );
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: 'capture.jpg',
    ));
    request.fields['return_image'] = 'true';

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode != 200) {
      throw Exception('分析失败: ${resp.statusCode} ${resp.body}');
    }
    return AnalysisResult.fromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
  }

  Future<AnalysisResult> analyzeFrame(Uint8List jpegBytes, {double timestamp = 0}) async {
    final resp = await http
        .post(
          Uri.parse('$_baseUrl/api/v1/analyze/frame'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'image_b64': base64Encode(jpegBytes),
            'timestamp': timestamp,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) {
      throw Exception('帧分析失败: ${resp.statusCode}');
    }
    return AnalysisResult.fromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
  }

  Future<VideoSummary> analyzeVideo(Uint8List videoBytes, {String filename = 'video.mp4'}) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/v1/analyze/video'),
    );
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      videoBytes,
      filename: filename,
    ));
    request.fields['max_frames'] = '150';

    final streamed = await request.send().timeout(const Duration(minutes: 3));
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode != 200) {
      throw Exception('视频分析失败: ${resp.statusCode}');
    }
    return VideoSummary.fromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
  }
}
