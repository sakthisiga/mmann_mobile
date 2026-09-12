import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../state/auth_notifier.dart';
import '../../farm/presentation/dashboard_screen.dart';
import 'phone_login_screen.dart';

class LanguageSelectScreen extends ConsumerWidget {
  const LanguageSelectScreen({super.key});

  static const List<Map<String, String>> languages = [
    {'code': 'ta', 'native': 'தமிழ்', 'english': 'Tamil'},
    {'code': 'te', 'native': 'తెలుగు', 'english': 'Telugu'},
    {'code': 'kn', 'native': 'ಕನ್ನಡ', 'english': 'Kannada'},
    {'code': 'ml', 'native': 'മലയാളം', 'english': 'Malayalam'},
    {'code': 'en', 'native': 'English', 'english': 'English'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canGoBack = Navigator.of(context).canPop();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (canGoBack) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 8),
              ] else
                const SizedBox(height: 16),
              // App Brand Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isDark ? AppColors.darkSurface : AppColors.white,
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MARUTHAMANN',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                        ),
                      ),
                      Text(
                        AppLocalizations(currentLocale).tr('app_name'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),
              Text(
                AppLocalizations(currentLocale).tr('select_language'),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations(currentLocale).tr('select_language_subtitle'),
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 28),
              // Language Cards Grid
              Expanded(
                child: ListView.separated(
                  itemCount: languages.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    final isSelected = currentLocale.languageCode == lang['code'];

                    return InkWell(
                      onTap: () {
                        ref
                            .read(localeProvider.notifier)
                            .setLocale(Locale(lang['code']!));
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: isDark
                              ? (isSelected
                                  ? AppColors.darkSurface
                                  : AppColors.darkSurface.withValues(alpha: 0.6))
                              : (isSelected
                                  ? AppColors.white
                                  : AppColors.lightSurface.withValues(alpha: 0.7)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? (isDark
                                    ? AppColors.darkAccentCoral
                                    : AppColors.lightPrimary)
                                : (isDark
                                    ? AppColors.darkCardBorder
                                    : AppColors.lightCardBorder),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected && !isDark
                              ? [
                                  BoxShadow(
                                    color: AppColors.lightPrimary
                                        .withValues(alpha: 0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? (isDark
                                        ? AppColors.darkAccentCoral
                                        : AppColors.lightPrimary)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : (isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted),
                                  width: 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 20)
                                  : null,
                            ),
                            const SizedBox(width: 18),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang['native']!,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  lang['english']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Continue Button
              ElevatedButton(
                onPressed: () {
                  final authState = ref.read(authNotifierProvider);
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else if (authState.isAuthenticated) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const DashboardScreen(),
                      ),
                    );
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const PhoneLoginScreen(),
                      ),
                    );
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations(currentLocale).tr('verify_and_continue'),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
