import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/auth_api_service.dart';
import '../state/auth_notifier.dart';
import '../state/auth_state.dart';
import 'phone_login_screen.dart';
import 'verify_otp_screen.dart';

class FarmerRegistrationScreen extends ConsumerStatefulWidget {
  final String? initialMobile;
  const FarmerRegistrationScreen({super.key, this.initialMobile});

  @override
  ConsumerState<FarmerRegistrationScreen> createState() =>
      _FarmerRegistrationScreenState();
}

class _FarmerRegistrationScreenState
    extends ConsumerState<FarmerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  late final TextEditingController _phoneController;
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _talukController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();

  bool _isQuickLoginMode = false;
  Timer? _debounceTimer;
  bool _isCheckingMobile = false;
  bool _isMobileAlreadyRegistered = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialMobile ?? '');
    _phoneController.addListener(_onPhoneChanged);
    if (widget.initialMobile != null && widget.initialMobile!.isNotEmpty) {
      _onPhoneChanged();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _phoneController.removeListener(_onPhoneChanged);
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _villageController.dispose();
    _talukController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    final text = _phoneController.text.trim();
    _debounceTimer?.cancel();

    if (_isQuickLoginMode) {
      if (_isMobileAlreadyRegistered || _isCheckingMobile) {
        setState(() {
          _isMobileAlreadyRegistered = false;
          _isCheckingMobile = false;
        });
      }
      return;
    }

    if (_isPhoneValid(text)) {
      _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
        if (!mounted) return;
        setState(() {
          _isCheckingMobile = true;
        });

        try {
          final exists =
              await ref.read(authApiServiceProvider).checkMobile(text);
          if (!mounted) return;
          setState(() {
            _isCheckingMobile = false;
            _isMobileAlreadyRegistered = exists;
          });
        } catch (_) {
          if (mounted) {
            setState(() {
              _isCheckingMobile = false;
            });
          }
        }
      });
    } else {
      if (_isMobileAlreadyRegistered || _isCheckingMobile) {
        setState(() {
          _isMobileAlreadyRegistered = false;
          _isCheckingMobile = false;
        });
      }
    }
  }

  bool _isPhoneValid(String text) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(text.trim());
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (!_isPhoneValid(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).tr('valid_phone_error')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_isQuickLoginMode && _isMobileAlreadyRegistered) {
      return;
    }

    if (!_isQuickLoginMode && !_formKey.currentState!.validate()) {
      return;
    }

    final locale = ref.read(localeProvider);

    RegistrationDraft? draft;
    if (!_isQuickLoginMode) {
      draft = RegistrationDraft(
        fullName: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        mobile: phone,
        village: _villageController.text.trim(),
        taluk: _talukController.text.trim(),
        district: _districtController.text.trim(),
        language: locale.languageCode,
      );
      ref.read(authNotifierProvider.notifier).setPendingRegistration(draft);
    }

    final success = await ref.read(authNotifierProvider.notifier).requestOtp(
          phone,
          locale.languageCode,
          registration: draft,
          isRegistration: !_isQuickLoginMode,
        );

    if (success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifyOtpScreen(
            mobile: phone,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isQuickLoginMode = !_isQuickLoginMode;
              });
            },
            icon: Icon(
              _isQuickLoginMode ? Icons.person_add_outlined : Icons.login_rounded,
              size: 18,
            ),
            label: Text(
              _isQuickLoginMode
                  ? loc.tr('new_registration')
                  : loc.tr('login_instead'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 18),
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
                        _isQuickLoginMode
                            ? loc.tr('step_1_indicator')
                            : loc.tr('registration_step'),
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
                const SizedBox(height: 16),

                // Main Title & Subtitle
                Text(
                  _isQuickLoginMode
                      ? loc.tr('enter_mobile')
                      : loc.tr('registration_title'),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isQuickLoginMode
                      ? loc.tr('select_language_subtitle')
                      : loc.tr('registration_subtitle'),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Error Banner if present
                if (authState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkAccentCoral.withValues(alpha: 0.15)
                          : AppColors.lightAccentCoral.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkAccentCoral
                            : AppColors.lightAccentCoral,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: isDark
                              ? AppColors.darkAccentCoral
                              : AppColors.lightAccentCoral,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            authState.errorMessage!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkAccentCoral
                                  : AppColors.lightAccentCoral,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (!_isQuickLoginMode) ...[
                  // 0. Preferred Language Selection
                  _buildLabel(loc.tr('select_language'), isRequired: true),
                  const SizedBox(height: 8),
                  _buildLanguageSelector(
                    context,
                    ref,
                    ref.watch(localeProvider).languageCode,
                    isDark,
                  ),
                  const SizedBox(height: 20),

                  // 1. Full Name of Farmer
                  _buildLabel(loc.tr('farmer_name'), isRequired: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: loc.tr('farmer_name_hint'),
                      prefixIcon: const Icon(Icons.person_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 2) {
                        return loc.tr('valid_name_error');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // 2. Age of Farmer
                  _buildLabel(loc.tr('farmer_age'), isRequired: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: InputDecoration(
                      hintText: loc.tr('farmer_age_hint'),
                      prefixIcon: const Icon(Icons.cake_outlined),
                    ),
                    validator: (val) {
                      final age = int.tryParse(val?.trim() ?? '');
                      if (age == null || age < 15 || age > 120) {
                        return loc.tr('valid_age_error');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                ],

                // 3. Mobile Number Field (+91 fixed)
                _buildLabel(loc.tr('indian_mobile_label'), isRequired: true),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkCardBorder
                          : AppColors.lightCardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 15),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: isDark
                                  ? AppColors.darkCardBorder
                                  : AppColors.lightCardBorder,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🇮🇳', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(
                              '+91',
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
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            hintText: loc.tr('enter_mobile_hint'),
                            counterText: '',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          validator: (val) {
                            if (val == null || !_isPhoneValid(val)) {
                              return loc.tr('valid_phone_error');
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isCheckingMobile) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
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
                ],
                if (_isMobileAlreadyRegistered) ...[
                  const SizedBox(height: 8),
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
                            loc.tr('phone_already_exists'),
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
                                builder: (_) => PhoneLoginScreen(
                                  initialMobile: _phoneController.text.trim(),
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: isDark
                                ? AppColors.darkAccentAmber.withValues(alpha: 0.25)
                                : AppColors.lightAccentAmber.withValues(alpha: 0.2),
                            foregroundColor: isDark
                                ? Colors.white
                                : AppColors.lightTextPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            loc.tr('sign_in_instead'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                if (!_isQuickLoginMode) ...[
                  // 4. Village Field
                  _buildLabel(loc.tr('village'), isRequired: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _villageController,
                    keyboardType: TextInputType.streetAddress,
                    decoration: InputDecoration(
                      hintText: loc.tr('village_hint'),
                      prefixIcon: const Icon(Icons.location_city_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return loc.tr('valid_village_error');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // 5. Taluk Field
                  _buildLabel(loc.tr('taluk'), isRequired: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _talukController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: loc.tr('taluk_hint'),
                      prefixIcon: const Icon(Icons.map_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return loc.tr('valid_taluk_error');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // 6. District Field
                  _buildLabel(loc.tr('district'), isRequired: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _districtController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: loc.tr('district_hint'),
                      prefixIcon: const Icon(Icons.holiday_village_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return loc.tr('valid_district_error');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // DPDP Act 2023 Compliance Banner
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimary.withValues(alpha: 0.1)
                        : AppColors.lightPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkPrimary.withValues(alpha: 0.25)
                          : AppColors.lightPrimary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 20,
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
                const SizedBox(height: 28),

                // Submit Button: Send OTP
                ElevatedButton(
                  onPressed: (authState.isLoading ||
                          _isMobileAlreadyRegistered ||
                          _isCheckingMobile)
                      ? null
                      : _handleSendOtp,
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
                            Text(
                              _isQuickLoginMode
                                  ? loc.tr('send_otp')
                                  : loc.tr('register_and_send_otp'),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    String currentLang,
    bool isDark,
  ) {
    const languages = [
      {'code': 'ta', 'native': 'தமிழ்', 'english': 'Tamil'},
      {'code': 'en', 'native': 'English', 'english': 'English'},
      {'code': 'te', 'native': 'తెలుగు', 'english': 'Telugu'},
      {'code': 'kn', 'native': 'ಕನ್ನಡ', 'english': 'Kannada'},
      {'code': 'ml', 'native': 'മലയാളം', 'english': 'Malayalam'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: languages.map((lang) {
        final isSelected = lang['code'] == currentLang;
        return InkWell(
          onTap: () {
            ref.read(localeProvider.notifier).setLocale(Locale(lang['code']!));
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? AppColors.darkPrimary.withValues(alpha: 0.25)
                      : AppColors.lightPrimary.withValues(alpha: 0.12))
                  : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                    : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  lang['native']!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${lang['english']})',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}
