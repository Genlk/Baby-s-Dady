class AnalysisResult {
  final String behavior;
  final String behaviorCn;
  final double confidence;
  final bool alert;
  final String alertMessage;
  final double movement;
  final double torsoAngle;
  final String? annotatedImageB64;

  const AnalysisResult({
    required this.behavior,
    required this.behaviorCn,
    required this.confidence,
    required this.alert,
    required this.alertMessage,
    required this.movement,
    required this.torsoAngle,
    this.annotatedImageB64,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      behavior: json['behavior'] as String? ?? 'unknown',
      behaviorCn: json['behavior_cn'] as String? ?? '未知',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      alert: json['alert'] as bool? ?? false,
      alertMessage: json['alert_message'] as String? ?? '',
      movement: (json['movement'] as num?)?.toDouble() ?? 0,
      torsoAngle: (json['torso_angle'] as num?)?.toDouble() ?? 0,
      annotatedImageB64: json['annotated_image_b64'] as String?,
    );
  }
}

class VideoSummary {
  final int framesProcessed;
  final String dominantBehavior;
  final Map<String, double> distribution;
  final int alertCount;
  final String lastBehavior;

  const VideoSummary({
    required this.framesProcessed,
    required this.dominantBehavior,
    required this.distribution,
    required this.alertCount,
    required this.lastBehavior,
  });

  factory VideoSummary.fromJson(Map<String, dynamic> json) {
    final dist = <String, double>{};
    (json['distribution'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      dist[k] = (v as num).toDouble();
    });
    return VideoSummary(
      framesProcessed: json['frames_processed'] as int? ?? 0,
      dominantBehavior: json['dominant_behavior'] as String? ?? '未知',
      distribution: dist,
      alertCount: json['alert_count'] as int? ?? 0,
      lastBehavior: json['last_behavior'] as String? ?? '未知',
    );
  }
}
