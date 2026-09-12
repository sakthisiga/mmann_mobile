import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/auth_api_service.dart';
import '../state/auth_notifier.dart';
import 'farmer_registration_screen.dart';
import 'verify_otp_screen.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  final String? initialMobile;
  const PhoneLoginScreen({super.key, this.initialMobile});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  late final TextEditingController _phoneController;
  bool _isPhoneValid = false;
  Timer? _debounceTimer;
  bool _isCheckingMobile = false;
  bool _isMobileNotRegistered = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialMobile ?? '');
    _phoneController.addListener(_onPhoneChanged);
    _onPhoneChanged();
  }

  void _onPhoneChanged() {
    final text = _phoneController.text.trim();
    final isValid = RegExp(r'^[6-9]\d{9}$').hasMatch(text);
    if (isValid != _isPhoneValid) {
      setState(() {
        _isPhoneValid = isValid;
      });
    }

    _debounceTimer?.cancel();
    if (isValid) {
      _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
        if (!mounted) return;
        setState(() => _isCheckingMobile = true);
        try {
          final exists = await ref.read(authApiServiceProvider).checkMobile(text);
          if (!mounted) return;
          setState(() {
            _isCheckingMobile = false;
            _isMobileNotRegistered = !exists;
          });
        } catch (_) {
          if (mounted) setState(() => _isCheckingMobile = false);
        }
      });
    } else {
      if (_isMobileNotRegistered || _isCheckingMobile) {
        setState(() {
          _isMobileNotRegistered = false;
          _isCheckingMobile = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_isPhoneValid || _isMobileNotRegistered) return;
    final locale = ref.read(localeProvider);

    // Clear any previous registration draft since this is an existing user phone login
    ref.read(authNotifierProvider.notifier).clearPendingRegistration();

    final success = await ref
        .read(authNotifierProvider.notifier)
        .requestOtp(
          _phoneController.text.trim(),
          locale.languageCode,
          isRegistration: false,
        );

    if (success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifyOtpScreen(
            mobile: _phoneController.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final currentLocale = ref.watch(localeProvider);
    final loc = AppLocalizations(currentLocale);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          _buildLanguageMenuButton(context, ref, isDark),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // App Brand Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
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
                      borderRadius: BorderRadius.circular(11),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MARUTHAMANN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                        ),
                      ),
                      Text(
                        loc.tr('app_name'),
                        style: TextStyle(
                          fontSize: 15,
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
              const SizedBox(height: 20),
              // Stage Indicator Pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPrimary.withValues(alpha: 0.18)
                      : AppColors.lightPillBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.lightAccentMint,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loc.tr('step_1_indicator'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Title & Subtitle for Existing Farmer Login
              Text(
                loc.tr('existing_farmer_title'),
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
                loc.tr('existing_farmer_subtitle'),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 28),

              // Mobile Input Container with locked +91 prefix
              Text(
                loc.tr('indian_mobile_label'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? (_isPhoneValid
                            ? AppColors.lightAccentMint
                            : AppColors.darkCardBorder)
                        : (_isPhoneValid
                            ? AppColors.lightAccentMint
                            : AppColors.lightCardBorder),
                    width: _isPhoneValid ? 1.5 : 1,
                  ),
                  boxShadow: !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    // Country Code
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPillBackground
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Text('🇮🇳', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            '+91',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        autofocus: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: loc.tr('enter_mobile_hint'),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_isPhoneValid)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.lightAccentMint,
                        size: 22,
                      ),
                  ],
                ),
              ),

              // Checking status or unregistered warning banner
              if (_isCheckingMobile) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Checking mobile number...',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ] else if (_isMobileNotRegistered) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkAccentAmber.withValues(alpha: 0.15)
                        : AppColors.lightAccentAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkAccentAmber
                          : AppColors.lightAccentAmber,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: isDark
                            ? AppColors.darkAccentAmber
                            : AppColors.lightAccentAmber,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          loc.tr('phone_not_registered'),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkAccentAmber
                                : AppColors.lightAccentAmber,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => FarmerRegistrationScreen(
                                initialMobile: _phoneController.text.trim(),
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.darkAccentAmber
                              : AppColors.lightAccentAmber,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          loc.tr('register_as_new_farmer'),
                          style: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Error banner if any
              if (authState.errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        AppColors.lightAccentCoral.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.lightAccentCoral.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.lightAccentCoral, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          authState.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.lightAccentCoral,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Primary Action: Send OTP Button (for Existing User)
              ElevatedButton(
                onPressed: (_isPhoneValid &&
                        !_isMobileNotRegistered &&
                        !_isCheckingMobile &&
                        !authState.isLoading)
                    ? _handleSendOtp
                    : null,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(loc.tr('send_otp')),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),

              const SizedBox(height: 36),

              // Divider separating Login and Registration
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: isDark
                          ? AppColors.darkCardBorder
                          : AppColors.lightCardBorder,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      loc.tr('new_farmer_question'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: isDark
                          ? AppColors.darkCardBorder
                          : AppColors.lightCardBorder,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Secondary Action: Register New Farmer Option (for New User)
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FarmerRegistrationScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: BorderSide(
                    color: isDark
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loc.tr('create_farmer_account'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // DPDP Act 2023 Compliance Note
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPrimary.withValues(alpha: 0.08)
                      : AppColors.lightPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkPrimary.withValues(alpha: 0.2)
                        : AppColors.lightPrimary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: AppColors.lightAccentMint,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        loc.tr('dpdp_consent_body'),
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageMenuButton(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final currentLang = ref.watch(localeProvider).languageCode;
    const langNames = {
      'ta': 'தமிழ்',
      'en': 'English',
      'te': 'తెలుగు',
      'kn': 'ಕನ್ನಡ',
      'ml': 'മലയാളം',
    };

    return PopupMenuButton<String>(
      tooltip: 'Language',
      initialValue: currentLang,
      onSelected: (code) {
        ref.read(localeProvider.notifier).setLocale(Locale(code));
      },
      itemBuilder: (ctx) => langNames.entries.map((e) {
        final isSelected = e.key == currentLang;
        return PopupMenuItem<String>(
          value: e.key,
          child: Row(
            children: [
              if (isSelected)
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.lightAccentMint,
                )
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(
                e.value,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface
              : AppColors.lightPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 16),
            const SizedBox(width: 6),
            Text(
              langNames[currentLang] ?? 'தமிழ்',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}
