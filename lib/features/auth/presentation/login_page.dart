import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matrix_desktop/app/app_theme.dart';
import 'package:matrix_desktop/core/models/session_state.dart';
import 'package:matrix_desktop/features/auth/presentation/auth_cubit.dart';
import 'package:matrix_desktop/features/auth/presentation/auth_error_message.dart';

const _heroBreakpoint = 900.0;

class LoginPage extends StatelessWidget {
  const LoginPage({required this.state, super.key});

  final SessionState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showHero = constraints.maxWidth >= _heroBreakpoint;
          final heroWidth = (constraints.maxWidth * 0.39).clamp(440.0, 620.0);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHero)
                SizedBox(width: heroWidth, child: const _LoginHero()),
              Expanded(
                key: const ValueKey('login-form-area'),
                child: _LoginFormArea(state: state, showBrandMark: !showHero),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.brand600,
        gradient: RadialGradient(
          center: Alignment.bottomLeft,
          radius: 0.9,
          colors: [AppColors.brand300, AppColors.brand600],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -100,
            right: -120,
            child: IgnorePointer(
              child: Container(
                width: 430,
                height: 430,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            BrandMark(inverse: true),
                            SizedBox(width: 12),
                            Text(
                              'Matrix Desktop',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'CLIENTE MATRIX PARA DESKTOP',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white.withOpacity(0.72),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Converse sem perder o foco.',
                          style: textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.04,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Uma experiência enxuta para acessar salas, acompanhar '
                          'mensagens e continuar exatamente de onde você parou.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 40),
                        const _Benefit('Sessão restaurada com segurança'),
                        const _Benefit('Salas e mensagens sincronizadas'),
                        const _Benefit('Bridge nativo entre Flutter e Rust'),
                        const Spacer(),
                        Text(
                          'Compatível com qualquer homeserver Matrix.',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.66),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                border: Border.all(color: Colors.white.withOpacity(0.24)),
              ),
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({this.inverse = false, this.size = 44, super.key});

  final bool inverse;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: inverse ? Colors.white : AppColors.brand600,
          borderRadius: BorderRadius.circular(size * 0.27),
        ),
        child: Text(
          'M',
          style: TextStyle(
            color: inverse ? AppColors.brand700 : Colors.white,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LoginFormArea extends StatefulWidget {
  const _LoginFormArea({required this.state, required this.showBrandMark});

  final SessionState state;
  final bool showBrandMark;

  @override
  State<_LoginFormArea> createState() => _LoginFormAreaState();
}

class _LoginFormAreaState extends State<_LoginFormArea> {
  final _formKey = GlobalKey<FormState>();
  final _homeserver = TextEditingController(text: 'https://matrix.org');
  final _userId = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  bool get _busy => widget.state is SessionAuthenticating;

  @override
  void dispose() {
    _homeserver.dispose();
    _userId.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;

    final password = _password.text;
    _password.clear();

    context.read<AuthCubit>().login(
          homeserver: _homeserver.text,
          userId: _userId.text,
          password: password,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final error = state is SessionFailed ? state.error : null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.panel.withOpacity(0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F2B1E46),
                  blurRadius: 45,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(34),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Heading(showBrandMark: widget.showBrandMark),
                      const SizedBox(height: 24),
                      _FieldLabel(
                        label: 'Homeserver',
                        child: TextFormField(
                          key: const Key('login-homeserver'),
                          controller: _homeserver,
                          enabled: !_busy,
                          keyboardType: TextInputType.url,
                          autofillHints: const [AutofillHints.url],
                          textInputAction: TextInputAction.next,
                          validator: validateHomeserver,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _FieldLabel(
                        label: 'ID Matrix',
                        child: TextFormField(
                          key: const Key('login-user-id'),
                          controller: _userId,
                          enabled: !_busy,
                          autofillHints: const [AutofillHints.username],
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: '@usuario:matrix.org',
                          ),
                          validator: validateMatrixId,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _FieldLabel(
                        label: 'Senha',
                        child: TextFormField(
                          key: const Key('login-password'),
                          controller: _password,
                          enabled: !_busy,
                          obscureText: _obscurePassword,
                          enableSuggestions: false,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          validator: (value) => (value ?? '').isEmpty
                              ? 'Informe sua senha.'
                              : null,
                          decoration: InputDecoration(
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 3),
                              child: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Mostrar senha'
                                    : 'Ocultar senha',
                                color: AppColors.muted,
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 15),
                        _FormError(message: error.message),
                      ],
                      const SizedBox(height: 18),
                      FilledButton(
                        key: const Key('login-submit'),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                  semanticsLabel: 'Entrando',
                                ),
                              )
                            : const Text('Entrar'),
                      ),
                      const SizedBox(height: 18),
                      const _SecurityNote(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? validateHomeserver(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'Informe o homeserver.';
  if (text.contains('://')) {
    final uri = Uri.tryParse(text);
    final validScheme = uri?.scheme == 'https' || uri?.scheme == 'http';
    if (uri == null || !validScheme || uri.host.isEmpty) {
      return 'Use um endereço como https://matrix.org.';
    }
  } else if (text.contains(' ') || !text.contains('.')) {
    return 'Use um endereço como https://matrix.org.';
  }
  return null;
}

String? validateMatrixId(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'Informe seu ID Matrix.';
  if (text.contains(' ')) return 'O ID Matrix não pode conter espaços.';
  if (text.startsWith('@')) {
    final separator = text.indexOf(':');
    if (separator <= 1 || separator == text.length - 1) {
      return 'Use o formato @usuario:servidor.';
    }
  }
  return null;
}

class _Heading extends StatelessWidget {
  const _Heading({required this.showBrandMark});

  final bool showBrandMark;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        if (showBrandMark) ...[
          const BrandMark(),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Entrar no Matrix Desktop',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Use sua conta Matrix para acessar suas conversas.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Semantics(label: label, child: child),
      ],
    );
  }
}

class _FormError extends StatelessWidget {
  const _FormError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('login-error'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.errorSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          message,
          style: const TextStyle(color: AppColors.error, fontSize: 12.5),
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.subtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(Icons.lock_outline, size: 18, color: AppColors.muted),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sua senha é usada somente para autenticar no homeserver '
              'selecionado.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
