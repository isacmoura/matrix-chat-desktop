import 'package:matrix_desktop/bridge/matrix_gateway.dart';
import 'package:matrix_desktop/core/models/room_summary.dart';
import 'package:matrix_desktop/core/models/timeline_message.dart';

final class RoomRepository {
  const RoomRepository(this._gateway);

  final MatrixGateway _gateway;

  Stream<List<RoomSummary>> watchRooms() => _gateway.watchRooms();

  Stream<List<TimelineMessage>> watchTimeline(String roomId) =>
      _gateway.watchTimeline(roomId: roomId);

  Future<bool> sendTextMessage(String roomId, String text) =>
      _gateway.sendTextMessage(roomId: roomId, text: text);
}
