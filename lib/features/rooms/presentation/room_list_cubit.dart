import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matrix_desktop/core/models/room_summary.dart';
import 'package:matrix_desktop/features/rooms/data/room_repository.dart';

sealed class RoomListState {
  const RoomListState();
}

final class RoomListLoading extends RoomListState {
  const RoomListLoading();
}

final class RoomListReady extends RoomListState {
  const RoomListReady(this.rooms);

  final List<RoomSummary> rooms;
}

final class RoomListFailed extends RoomListState {
  const RoomListFailed();
}

final class RoomListCubit extends Cubit<RoomListState> {
  RoomListCubit(this._repository) : super(const RoomListLoading());

  final RoomRepository _repository;
  StreamSubscription<List<RoomSummary>>? _subscription;

  void start() {
    if (_subscription != null) return;
    _subscription = _repository.watchRooms().listen(
          (rooms) => emit(RoomListReady(rooms)),
          onError: (_, __) => emit(const RoomListFailed()),
        );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
