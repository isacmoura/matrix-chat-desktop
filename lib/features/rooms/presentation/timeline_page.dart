import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matrix_desktop/app/app_theme.dart';
import 'package:matrix_desktop/core/models/room_summary.dart';
import 'package:matrix_desktop/core/models/timeline_message.dart';
import 'package:matrix_desktop/features/rooms/presentation/timeline_cubit.dart';

class TimelinePage extends StatelessWidget {
  const TimelinePage({required this.room, super.key});

  final RoomSummary room;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TimelineHeader(room: room),
        Expanded(
          child: BlocBuilder<TimelineCubit, TimelineState>(
            builder: (context, state) => switch (state) {
              TimelineLoading() => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              TimelineFailed() => const Center(
                  child: Text('Falha ao carregar linha do tempo'),
                ),
              TimelineReady(:final messages) => _MessageList(messages: messages),
            },
          ),
        ),
        const _Composer(),
      ],
    );
  }
}

class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader({required this.room});

  final RoomSummary room;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  room.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  room.roomId,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.brand100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.brand700,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Sincronizado',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.brand700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages});

  final List<TimelineMessage> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma mensagem ainda',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    return ListView.separated(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      itemCount: messages.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return _MessageRow(message: message);
      },
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message});

  final TimelineMessage message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final initial = message.sender.length > 1
        ? message.sender.substring(1, 2).toUpperCase()
        : '?';
    final h = message.timestamp.hour.toString().padLeft(2, '0');
    final m = message.timestamp.minute.toString().padLeft(2, '0');
    final timeStr = '$h:$m';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.brand100,
          foregroundColor: AppColors.brand700,
          child: Text(
            initial,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    message.sender,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    timeStr,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                message.body,
                style: textTheme.bodyMedium?.copyWith(height: 1.55),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer();

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    context.read<TimelineCubit>().sendMessage(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.attach_file),
            splashRadius: 24,
            tooltip: 'Adicionar anexo',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Escreva uma mensagem...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brand100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _submit,
              icon: const Icon(Icons.send),
              color: AppColors.brand700,
              splashRadius: 22,
              tooltip: 'Enviar mensagem',
            ),
          ),
        ],
      ),
    );
  }
}
