import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/application/settings_providers.dart';
import 'l10n/app_localizations.dart';

class HrApp extends ConsumerWidget {
  const HrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(languageProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isArabic = locale.languageCode == 'ar';

    return MaterialApp.router(
      title: 'HR System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(isArabic: isArabic),
      darkTheme: AppTheme.darkTheme(isArabic: isArabic),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) {
        return Directionality(
          textDirection:
              isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
    );
  }
}
