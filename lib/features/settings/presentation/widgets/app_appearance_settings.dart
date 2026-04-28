import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../application/settings_providers.dart';
import 'settings_section_card.dart';

/// Language + light/dark theme toggles (SharedPreferences-backed).
class AppAppearanceSettings extends ConsumerWidget {
  const AppAppearanceSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(languageProvider);
    final isArabic = locale.languageCode == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionCard(
          title: l10n.language,
          children: [
            SwitchListTile(
              title: Text(isArabic ? l10n.arabic : l10n.english),
              subtitle: Text(
                isArabic ? 'اللغة الحالية: عربي' : 'Current language: English',
              ),
              value: isArabic,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              onChanged: (_) =>
                  ref.read(languageProvider.notifier).toggleLanguage(),
              secondary: const Icon(Icons.language_rounded),
            ),
          ],
        ),
        SettingsSectionCard(
          title: l10n.theme,
          children: [
            SwitchListTile(
              title: Text(
                themeMode == ThemeMode.dark ? l10n.darkMode : l10n.lightMode,
              ),
              value: themeMode == ThemeMode.dark,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              onChanged: (_) =>
                  ref.read(themeModeProvider.notifier).toggleTheme(),
              secondary: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
