import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/application/auth_providers.dart';

class PasswordSettingsSection extends ConsumerStatefulWidget {
  const PasswordSettingsSection({super.key});

  @override
  ConsumerState<PasswordSettingsSection> createState() =>
      _PasswordSettingsSectionState();
}

class _PasswordSettingsSectionState
    extends ConsumerState<PasswordSettingsSection> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final notifier = ref.read(authNotifierProvider.notifier);
    final success = await notifier.updatePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      context.showSnackBar(context.l10n.passwordUpdated);
    } else {
      final error = ref.read(authNotifierProvider).errorMessage ?? '';
      context.showSnackBar(_localizeError(error), isError: true);
    }
  }

  String _localizeError(String error) {
    final l10n = context.l10n;
    if (error.contains('wrong-password') ||
        error.contains('invalid-credential')) {
      return l10n.currentPasswordIncorrect;
    }
    if (error.contains('weak-password')) return l10n.weakPassword;
    if (error.contains('requires-recent-login') ||
        error.contains('missing-current-user')) {
      return l10n.recentLoginRequired;
    }
    if (error.contains('network-request-failed')) return l10n.errorNetwork;
    return l10n.errorGeneral;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final authState = ref.watch(authNotifierProvider);

    return ExpansionTile(
      leading: const Icon(Icons.lock_reset_rounded),
      title: Text(l10n.changePassword),
      subtitle: Text(l10n.changePasswordSubtitle),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: l10n.currentPassword,
                controller: _currentPasswordController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.required;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: l10n.newPassword,
                controller: _newPasswordController,
                obscureText: true,
                prefixIcon: Icons.lock_reset_outlined,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.required;
                  if (value.length < 8) return l10n.passwordTooShort;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: l10n.confirmNewPassword,
                controller: _confirmPasswordController,
                obscureText: true,
                prefixIcon: Icons.verified_user_outlined,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.required;
                  if (value != _newPasswordController.text) {
                    return l10n.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppButton(
                label: l10n.updatePassword,
                icon: Icons.save_rounded,
                isLoading: authState.isLoading,
                onPressed: authState.isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
