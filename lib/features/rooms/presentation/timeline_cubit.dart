import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matrix_desktop/core/models/timeline_message.dart';
import 'package:matrix_desktop/features/rooms/data/room_repository.dart';

sealed class TimelineState {
  const TimelineState();
}

final class TimelineLoading extends TimelineState {
  const TimelineLoading();
}

final class TimelineReady extends TimelineState {
  const TimelineReady(this.messages);

  final List<TimelineMessage> messages;
}

final class TimelineFailed extends TimelineState {
  const TimelineFailed();
}

class TimelineCubit extends Cubit<TimelineState> {
  TimelineCubit(this._repository, this.roomId) : super(const TimelineLoading());

  final RoomRepository _repository;
  final String roomId;
  StreamSubscription<List<TimelineMessage>>? _subscription;

  void start() {
    if (_subscription != null) return;
    _subscription = _repository.watchTimeline(roomId).listen(
          (messages) => emit(TimelineReady(messages)),
          onError: (_, __) => emit(const TimelineFailed()),
        );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    await _repository.sendTextMessage(roomId, text.trim());
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
