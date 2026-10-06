import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matrix_desktop/app/app_theme.dart';
import 'package:matrix_desktop/core/models/session_state.dart';
import 'package:matrix_desktop/features/auth/data/auth_repository.dart';
import 'package:matrix_desktop/features/auth/presentation/auth_cubit.dart';
import 'package:matrix_desktop/features/auth/presentation/login_page.dart';
import 'package:matrix_desktop/features/auth/presentation/session_home_page.dart';
import 'package:matrix_desktop/features/auth/presentation/session_loading_view.dart';
import 'package:matrix_desktop/features/rooms/data/room_repository.dart';
import 'package:matrix_desktop/features/rooms/presentation/room_list_cubit.dart';

class MatrixDesktopApp extends StatelessWidget {
  const MatrixDesktopApp({
    required this.authRepository,
    required this.roomRepository,
    required this.appDataDirectory,
    super.key,
  });

  final AuthRepository authRepository;
  final RoomRepository roomRepository;

  final String appDataDirectory;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(
        authRepository,
        appDataDirectory: appDataDirectory,
      )..start(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Matrix Desktop',
        theme: buildAppTheme(),
        home: BlocBuilder<AuthCubit, SessionState>(
          builder: (context, state) => switch (state) {
            SessionUninitialized() ||
            SessionRestoring() =>
              const SessionLoadingView(),
            SessionAuthenticated(:final session) => BlocProvider(
                create: (_) => RoomListCubit(roomRepository)..start(),
                child: SessionHomePage(session: session),
              ),
            SessionUnauthenticated() ||
            SessionAuthenticating() ||
            SessionFailed() =>
              LoginPage(state: state),
          },
        ),
      ),
    );
  }
}
