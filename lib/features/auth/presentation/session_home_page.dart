import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matrix_desktop/app/app_theme.dart';
import 'package:matrix_desktop/app/widgets/app_rail.dart';
import 'package:matrix_desktop/core/models/session_state.dart';
import 'package:matrix_desktop/features/auth/presentation/auth_cubit.dart';
import 'package:matrix_desktop/features/rooms/presentation/room_list_page.dart';
import 'package:matrix_desktop/core/models/room_summary.dart';
import 'package:matrix_desktop/features/rooms/data/room_repository.dart';
import 'package:matrix_desktop/features/rooms/presentation/timeline_cubit.dart';
import 'package:matrix_desktop/features/rooms/presentation/timeline_page.dart';

class SessionHomePage extends StatefulWidget {
  const SessionHomePage({required this.session, super.key});

  final UserSession session;

  @override
  State<SessionHomePage> createState() => _SessionHomePageState();
}

class _SessionHomePageState extends State<SessionHomePage> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    await context.read<AuthCubit>().logout();
    if (mounted) setState(() => _loggingOut = false);
  }

  RoomSummary? _selectedRoom;

  void _onRoomSelected(RoomSummary room) {
    setState(() => _selectedRoom = room);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      body: Row(
        children: [
          const AppRail(),
          RoomListPage(
            selectedRoomId: _selectedRoom?.roomId,
            onRoomSelected: _onRoomSelected,
          ),
          Expanded(
            child: _selectedRoom == null
                ? _ContentPanel(
                    session: widget.session,
                    loggingOut: _loggingOut,
                    onLogout: _logout,
                  )
                : BlocProvider(
                    key: ValueKey(_selectedRoom!.roomId),
                    create: (context) => TimelineCubit(
                      context.read<RoomRepository>(),
                      _selectedRoom!.roomId,
                    )..start(),
                    child: TimelinePage(room: _selectedRoom!),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ContentPanel extends StatelessWidget {
  const _ContentPanel({
    required this.session,
    required this.loggingOut,
    required this.onLogout,
  });

  final UserSession session;
  final bool loggingOut;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final initial = session.userId.length > 1
        ? session.userId.substring(1, 2).toUpperCase()
        : '?';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.brand100,
                  foregroundColor: AppColors.brand700,
                  child: Text(
                    initial,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sessão ativa',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        session.userId,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Detail(label: 'Homeserver', value: session.homeserver),
            const SizedBox(height: 12),
            _Detail(label: 'Dispositivo', value: session.deviceId),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              key: const Key('logout-button'),
              onPressed: loggingOut ? null : onLogout,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder(),
              ),
              icon: loggingOut
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout),
              label: const Text('Sair'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(value),
      ],
    );
  }
}
