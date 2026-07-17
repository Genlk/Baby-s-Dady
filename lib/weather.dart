import 'dart:convert';

import 'package:http/http.dart' as http;

/// 天气信息 + 基于天气的穿衣建议。
/// 数据来源：Open-Meteo（免费、无需 API key）。
class WeatherInfo {
  const WeatherInfo({
    required this.city,
    required this.temperature,
    required this.weatherCode,
  });

  final String city;
  final double temperature;
  final int weatherCode;

  /// 天气代码 → 中文描述（WMO weather code）。
  String get condition {
    if (weatherCode == 0) return '晴';
    if (weatherCode <= 3) return '多云';
    if (weatherCode == 45 || weatherCode == 48) return '有雾';
    if (weatherCode >= 51 && weatherCode <= 57) return '毛毛雨';
    if (weatherCode >= 61 && weatherCode <= 67) return '下雨';
    if (weatherCode >= 71 && weatherCode <= 77) return '下雪';
    if (weatherCode >= 80 && weatherCode <= 82) return '阵雨';
    if (weatherCode >= 85 && weatherCode <= 86) return '阵雪';
    if (weatherCode >= 95) return '雷阵雨';
    return '未知';
  }

  bool get isRainy =>
      (weatherCode >= 51 && weatherCode <= 67) ||
      (weatherCode >= 80 && weatherCode <= 82) ||
      weatherCode >= 95;

  bool get isSnowy =>
      (weatherCode >= 71 && weatherCode <= 77) ||
      (weatherCode >= 85 && weatherCode <= 86);

  /// 依据气温推荐的季节标签（与衣物的 season 字段对应）。
  String get recommendedSeason {
    if (temperature >= 25) return '夏';
    if (temperature >= 15) return '春秋';
    return '冬';
  }

  /// 穿衣建议文案。
  String get advice {
    final buffer = StringBuffer();
    if (temperature >= 28) {
      buffer.write('炎热，推荐短袖、连衣裙、凉鞋，注意防晒。');
    } else if (temperature >= 25) {
      buffer.write('温暖，适合短袖、薄款上衣或裙子。');
    } else if (temperature >= 20) {
      buffer.write('舒适，长袖或薄外套都合适。');
    } else if (temperature >= 15) {
      buffer.write('微凉，建议长袖搭配一件薄外套。');
    } else if (temperature >= 8) {
      buffer.write('偏冷，推荐毛衣加外套。');
    } else {
      buffer.write('寒冷，记得穿厚外套、毛衣，注意保暖。');
    }
    if (isRainy) buffer.write(' 有雨，记得带伞或穿防水外套。');
    if (isSnowy) buffer.write(' 有雪，注意保暖防滑。');
    return buffer.toString();
  }
}

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// 通过城市名查询天气；失败时返回 null。
  Future<WeatherInfo?> fetchByCity(String city) async {
    try {
      final geoUri = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search'
        '?name=${Uri.encodeQueryComponent(city)}&count=1&language=zh&format=json',
      );
      final geoResp = await _client.get(geoUri).timeout(const Duration(seconds: 12));
      if (geoResp.statusCode != 200) return null;
      final geoJson = jsonDecode(geoResp.body) as Map<String, dynamic>;
      final results = geoJson['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      final lat = (first['latitude'] as num).toDouble();
      final lon = (first['longitude'] as num).toDouble();
      final name = (first['name'] as String?) ?? city;

      final wUri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code&timezone=auto',
      );
      final wResp = await _client.get(wUri).timeout(const Duration(seconds: 12));
      if (wResp.statusCode != 200) return null;
      final wJson = jsonDecode(wResp.body) as Map<String, dynamic>;
      final current = wJson['current'] as Map<String, dynamic>?;
      if (current == null) return null;

      return WeatherInfo(
        city: name,
        temperature: (current['temperature_2m'] as num).toDouble(),
        weatherCode: (current['weather_code'] as num).toInt(),
      );
    } catch (_) {
      return null;
    }
  }
}
