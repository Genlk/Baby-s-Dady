class CameraNodeStatus {
  final String deviceId;
  final String deviceName;
  final String behavior;
  final String behaviorCn;
  final double confidence;
  final bool alert;
  final String alertMessage;
  final double movement;
  final double torsoAngle;
  final bool online;
  final double lastSeen;
  final String? annotatedImageB64;

  const CameraNodeStatus({
    required this.deviceId,
    required this.deviceName,
    required this.behavior,
    required this.behaviorCn,
    required this.confidence,
    required this.alert,
    required this.alertMessage,
    required this.movement,
    required this.torsoAngle,
    required this.online,
    required this.lastSeen,
    this.annotatedImageB64,
  });

  factory CameraNodeStatus.fromJson(Map<String, dynamic> json) {
    return CameraNodeStatus(
      deviceId: json['device_id'] as String? ?? '',
      deviceName: json['device_name'] as String? ?? '监控',
      behavior: json['behavior'] as String? ?? 'unknown',
      behaviorCn: json['behavior_cn'] as String? ?? '未知',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      alert: json['alert'] as bool? ?? false,
      alertMessage: json['alert_message'] as String? ?? '',
      movement: (json['movement'] as num?)?.toDouble() ?? 0,
      torsoAngle: (json['torso_angle'] as num?)?.toDouble() ?? 0,
      online: json['online'] as bool? ?? false,
      lastSeen: (json['last_seen'] as num?)?.toDouble() ?? 0,
      annotatedImageB64: json['annotated_image_b64'] as String?,
    );
  }
}
