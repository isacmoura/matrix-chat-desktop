final class RoomSummary {
  const RoomSummary({
    required this.roomId,
    required this.name,
    required this.unreadMessages,
    required this.isInvited,
  });

  final String roomId;
  final String name;
  final int unreadMessages;
  final bool isInvited;

  @override
  bool operator ==(Object other) =>
      other is RoomSummary &&
      other.roomId == roomId &&
      other.name == name &&
      other.unreadMessages == unreadMessages &&
      other.isInvited == isInvited;

  @override
  int get hashCode => Object.hash(roomId, name, unreadMessages, isInvited);
}
