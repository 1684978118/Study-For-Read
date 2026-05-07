class PendingSyncEvent {
  const PendingSyncEvent({
    required this.id,
    required this.ownerUserId,
    required this.eventType,
    required this.aggregateKey,
    required this.payloadJson,
    required this.status,
    required this.attemptCount,
    required this.lastErrorCode,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUserId;
  final String eventType;
  final String? aggregateKey;
  final String payloadJson;
  final String status;
  final int attemptCount;
  final String? lastErrorCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'owner_user_id': ownerUserId,
      'event_type': eventType,
      'aggregate_key': aggregateKey,
      'payload_json': payloadJson,
      'status': status,
      'attempt_count': attemptCount,
      'last_error_code': lastErrorCode,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory PendingSyncEvent.fromMap(Map<String, Object?> map) {
    return PendingSyncEvent(
      id: map['id'] as String,
      ownerUserId: map['owner_user_id'] as String,
      eventType: map['event_type'] as String,
      aggregateKey: map['aggregate_key'] as String?,
      payloadJson: map['payload_json'] as String,
      status: map['status'] as String,
      attemptCount: map['attempt_count'] as int,
      lastErrorCode: map['last_error_code'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toUtc(),
    );
  }
}
