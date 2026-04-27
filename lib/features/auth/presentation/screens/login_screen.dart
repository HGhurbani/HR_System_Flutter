import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../application/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(authNotifierProvider.notifier);
    final success = await notifier.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!success && mounted) {
      final error = ref.read(authNotifierProvider).errorMessage ?? '';
      context.showSnackBar(_localizeError(error), isError: true);
    }
  }

  String _localizeError(String error) {
    final l10n = context.l10n;
    if (error.contains('Incorrect email') || error.contains('invalid-credential')) {
      return l10n.wrongCredentials;
    } else if (error.contains('disabled')) {
      return l10n.accountDisabled;
    } else if (error.contains('too-many-requests')) {
      return l10n.tooManyRequests;
    }
    return l10n.loginFailed;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final l10n = context.l10n;
    final isDark = context.theme.brightness == Brightness.dark;
    final cs = context.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background gradient + subtle brand glow for a more premium dark look.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [
                        AppColors.primaryDark,
                        AppColors.backgroundDark,
                      ]
                    : const [
                        Color(0xFFF6F8F7),
                        AppColors.backgroundLight,
                      ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          // Accent glows
          Positioned(
            top: -90,
            left: -70,
            child: _GlowBlob(
              color: (isDark ? AppColors.gold : AppColors.primary)
                  .withValues(alpha: isDark ? 0.18 : 0.12),
              size: 240,
            ),
          ),
          Positioned(
            bottom: -120,
            right: -90,
            child: _GlowBlob(
              color: AppColors.primaryLight.withValues(alpha: isDark ? 0.18 : 0.10),
              size: 280,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      _buildHeader(context),
                      const SizedBox(height: 28),
                      _buildCard(context, authState, l10n),
                      const SizedBox(height: 20),
                      Text(
                        l10n.appTagline,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.70),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final cs = context.colorScheme;
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: isDark ? 0.45 : 0.30),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppColors.gold : AppColors.primary)
                    .withValues(alpha: isDark ? 0.18 : 0.22),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/images/app_icon.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.appName,
          style: context.textTheme.headlineMedium?.copyWith(
            color: isDark ? AppColors.goldLight : AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.appTagline,
          style: context.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.72),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context,
    AuthState authState,
    dynamic l10n,
  ) {
    final isDark = context.theme.brightness == Brightness.dark;
    final cs = context.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? AppColors.cardDark : Colors.white)
                .withValues(alpha: isDark ? 0.86 : 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: isDark ? 0.30 : 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.loginTitle,
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.loginSubtitle,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 22),
                  AppTextField(
                    label: l10n.email,
                    hint: l10n.emailHint,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l10n.required;
                      if (!v.contains('@')) return l10n.invalidEmail;
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: l10n.password,
                    hint: l10n.passwordHint,
                    controller: _passwordController,
                    obscureText: true,
                    prefixIcon: Icons.lock_outlined,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.required;
                      if (v.length < 8) return l10n.passwordTooShort;
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v ?? true),
                        activeColor: AppColors.gold,
                        checkColor: AppColors.primaryDark,
                        side: BorderSide(
                          color: cs.onSurface.withValues(alpha: 0.30),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l10n.rememberMe,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.82),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.forgotPassword),
                        child: Text(
                          l10n.forgotPassword,
                          style: TextStyle(
                            color: isDark ? AppColors.goldLight : AppColors.goldDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: authState.isLoading ? null : _submit,
                      icon: authState.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            )
                          : const Icon(Icons.login_rounded, size: 20),
                      label: Text(
                        authState.isLoading ? l10n.loginLoading : l10n.loginButton,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.primaryDark,
                        disabledBackgroundColor:
                            AppColors.gold.withValues(alpha: 0.55),
                        disabledForegroundColor:
                            AppColors.primaryDark.withValues(alpha: 0.75),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: TextStyle(
                          fontFamily: context.textTheme.labelLarge?.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
