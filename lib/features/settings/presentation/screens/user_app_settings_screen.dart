import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../widgets/app_appearance_settings.dart';

/// Language & theme for employee / supervisor (`SharedPreferences`, same as admin).
class UserAppSettingsScreen extends StatelessWidget {
  const UserAppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appSettings)),
      body: ListView(
        children: const [
          AppAppearanceSettings(),
        ],
      ),
    );
  }
}
