import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/phone_login_screen.dart';
import 'features/auth/state/auth_notifier.dart';
import 'features/farm/presentation/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('selected_language');
  final initialLocale =
      (savedLang != null && ['ta', 'te', 'kn', 'ml', 'en'].contains(savedLang))
          ? Locale(savedLang)
          : const Locale('ta');

  runApp(
    ProviderScope(
      overrides: [
        initialLocaleProvider.overrideWithValue(initialLocale),
      ],
      child: const MaruthamannApp(),
    ),
  );
}

class MaruthamannApp extends ConsumerWidget {
  const MaruthamannApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final authState = ref.watch(authNotifierProvider);

    return MaterialApp(
      title: 'Maruthamann',
      debugShowCheckedModeBanner: false,
      locale: currentLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: authState.isAuthenticated
          ? const DashboardScreen()
          : const PhoneLoginScreen(),
    );
  }
}
