import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../widgets/app_appearance_settings.dart';
import '../widgets/password_settings_section.dart';
import '../widgets/settings_section_card.dart';

/// Language & theme for employee / supervisor (`SharedPreferences`, same as admin).
class UserAppSettingsScreen extends StatelessWidget {
  const UserAppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appSettings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const AppAppearanceSettings(),
          SettingsSectionCard(
            title: l10n.profile,
            children: const [
              PasswordSettingsSection(),
            ],
          ),
        ],
      ),
    );
  }
}
