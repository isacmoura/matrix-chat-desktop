import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matrix_desktop/app/app_theme.dart';
import 'package:matrix_desktop/core/models/room_summary.dart';
import 'package:matrix_desktop/features/rooms/presentation/room_list_cubit.dart';

class RoomListPage extends StatelessWidget {
  const RoomListPage({
    this.selectedRoomId,
    this.onRoomSelected,
    super.key,
  });

  final String? selectedRoomId;
  final ValueChanged<RoomSummary>? onRoomSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Salas',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 20),
                  splashRadius: 20,
                  tooltip: 'Nova sala',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.78),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 17, color: AppColors.muted),
                  const SizedBox(width: 9),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Buscar salas...',
                        hintStyle: TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BlocBuilder<RoomListCubit, RoomListState>(
              builder: (context, state) => switch (state) {
                RoomListLoading() => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                RoomListFailed() => Center(
                    child: Text(
                      'Falha ao carregar salas',
                      style: textTheme.bodySmall?.copyWith(color: AppColors.error),
                    ),
                  ),
                RoomListReady(:final rooms) => rooms.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma sala encontrada',
                          style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: rooms.length,
                        itemBuilder: (context, index) {
                          final room = rooms[index];
                          return _RoomItem(
                            room: room,
                            isSelected: selectedRoomId == room.roomId,
                            onTap: onRoomSelected != null
                                ? () => onRoomSelected!(room)
                                : null,
                          );
                        },
                      ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomItem extends StatelessWidget {
  const _RoomItem({
    required this.room,
    required this.isSelected,
    this.onTap,
  });

  final RoomSummary room;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final initial = room.name.isNotEmpty
        ? room.name.substring(0, 1).toUpperCase()
        : '#';

    return Material(
      color: isSelected ? AppColors.selected : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: Colors.white.withOpacity(0.7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.brand100,
                foregroundColor: AppColors.brand700,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.isInvited ? 'Você foi convidado' : 'Sem pré-visualização',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isSelected && room.unreadMessages > 0) ...[
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 21),
                  height: 21,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppColors.brand600,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    room.unreadMessages > 99 ? '99+' : room.unreadMessages.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
