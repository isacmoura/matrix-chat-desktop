import 'package:flutter/foundation.dart';

@immutable
class TimelineMessage {
  const TimelineMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.isOwn,
    required this.timestamp,
  });

  final String id;
  final String sender;
  final String body;
  final bool isOwn;
  final DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
