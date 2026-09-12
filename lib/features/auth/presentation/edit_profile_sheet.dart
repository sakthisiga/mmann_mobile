import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/auth_api_service.dart';
import '../data/auth_models.dart';
import '../state/auth_notifier.dart';

class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key});

  static Future<void> show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const EditProfileSheet(),
    );
  }

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _phoneController;
  late final TextEditingController _districtController;
  late final TextEditingController _talukController;
  late final TextEditingController _villageController;

  String _selectedState = 'TN';
  String _selectedLanguage = 'ta';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authNotifierProvider);
    final user = authState.currentUser;
    final org = authState.activeOrg;

    _nameController = TextEditingController(text: user?.displayName ?? '');
    _ageController = TextEditingController(
      text: user?.age != null ? user!.age.toString() : '',
    );
    final rawMobile = user?.mobile ?? '';
    _phoneController = TextEditingController(
      text: rawMobile.replaceFirst(RegExp(r'^\+91'), ''),
    );

    _selectedState = (org?.stateCode.isNotEmpty == true)
        ? org!.stateCode
        : (user?.stateCode ?? 'TN');

    _districtController = TextEditingController(text: org?.district ?? '');
    _talukController = TextEditingController(text: org?.taluk ?? '');
    _villageController = TextEditingController(text: org?.village ?? '');

    _selectedLanguage = ref.read(localeProvider).languageCode;

    // Always fetch fresh profile details from backend to ensure age & org details are up to date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFreshProfile();
    });
  }

  Future<void> _fetchFreshProfile() async {
    try {
      final me = await ref.read(authApiServiceProvider).getMe();
      if (!mounted) return;
      if (me['user'] != null) {
        final userData = me['user'] as Map<String, dynamic>;
        final user = UserProfile.fromJson(userData);
        if (_nameController.text.isEmpty && user.displayName != null) {
          _nameController.text = user.displayName!;
        }
        if (_ageController.text.isEmpty && user.age != null) {
          _ageController.text = user.age.toString();
        }
      }
      if (me['org'] != null) {
        final orgData = me['org'] as Map<String, dynamic>;
        if (_districtController.text.isEmpty && orgData['district'] != null) {
          _districtController.text = orgData['district'] as String;
        }
        if (_talukController.text.isEmpty && orgData['taluk'] != null) {
          _talukController.text = orgData['taluk'] as String;
        }
        if (_villageController.text.isEmpty && orgData['village'] != null) {
          _villageController.text = orgData['village'] as String;
        }
      }
      if (me['farms'] != null && me['farms'] is List && (me['farms'] as List).isNotEmpty) {
        final farms = me['farms'] as List;
        final primary = farms.firstWhere(
          (f) => f is Map && f['isPrimary'] == true,
          orElse: () => farms.first,
        ) as Map<String, dynamic>?;
        if (primary != null) {
          if (_districtController.text.isEmpty && primary['district'] != null) {
            _districtController.text = primary['district'] as String;
          }
          if (_talukController.text.isEmpty && primary['taluk'] != null) {
            _talukController.text = primary['taluk'] as String;
          }
          if (_villageController.text.isEmpty && primary['village'] != null) {
            _villageController.text = primary['village'] as String;
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _districtController.dispose();
    _talukController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final loc = AppLocalizations(Locale(_selectedLanguage));

    int? parsedAge;
    if (_ageController.text.trim().isNotEmpty) {
      parsedAge = int.tryParse(_ageController.text.trim());
    }

    final success = await ref.read(authNotifierProvider.notifier).updateProfile(
          displayName: _nameController.text.trim(),
          age: parsedAge,
          stateCode: _selectedState,
          language: _selectedLanguage,
          district: _districtController.text.trim(),
          taluk: _talukController.text.trim(),
          village: _villageController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      // Sync local app language if farmer changed preferred language
      ref.read(localeProvider.notifier).setLocale(Locale(_selectedLanguage));

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.tr('profile_updated_successfully')),
          backgroundColor: AppColors.lightPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile. Please try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations(Locale(_selectedLanguage));

    final stateNames = {
      'TN': 'Tamil Nadu (தமிழ்நாடு)',
      'KA': 'Karnataka (ಕರ್ನಾಟಕ)',
      'AP': 'Andhra Pradesh (ఆంధ్రప్రదేశ్)',
      'TG': 'Telangana (తెలంగాణ)',
      'KL': 'Kerala (കേരളം)',
    };

    const languages = [
      {'code': 'ta', 'native': 'தமிழ்', 'english': 'Tamil'},
      {'code': 'en', 'native': 'English', 'english': 'English'},
      {'code': 'te', 'native': 'తెలుగు', 'english': 'Telugu'},
      {'code': 'kn', 'native': 'ಕನ್ನಡ', 'english': 'Kannada'},
      {'code': 'ml', 'native': 'മലയാളം', 'english': 'Malayalam'},
    ];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle pill
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Row
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPrimary.withValues(alpha: 0.2)
                          : AppColors.lightPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person_rounded,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('edit_profile_details'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.white : AppColors.darkSurface,
                          ),
                        ),
                        Text(
                          loc.tr('edit_profile_subtitle'),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Farmer Full Name & Age
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${loc.tr('farmer_name')} *',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: loc.tr('farmer_name_hint'),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkBackground
                                : AppColors.lightCardBorder.withValues(alpha: 0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return loc.tr('valid_name_error');
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('farmer_age'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: loc.tr('farmer_age_hint'),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkBackground
                                : AppColors.lightCardBorder.withValues(alpha: 0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Mobile Number (Read-only anchor)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.tr('enter_mobile'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightAccentMint.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.lightAccentMint.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 11,
                              color: AppColors.lightAccentMint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              loc.tr('verified_mobile'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.lightAccentMint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneController,
                    readOnly: true,
                    enabled: false,
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '🇮🇳 +91',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkBackground.withValues(alpha: 0.5)
                          : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Preferred Language Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.tr('select_language'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: languages.map((lang) {
                      final isSelected = _selectedLanguage == lang['code'];
                      return InkWell(
                        onTap: () {
                          setState(() => _selectedLanguage = lang['code']!);
                          ref
                              .read(localeProvider.notifier)
                              .setLocale(Locale(lang['code']!));
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? AppColors.darkPrimary.withValues(alpha: 0.25)
                                    : AppColors.lightPrimary.withValues(alpha: 0.12))
                                : (isDark
                                    ? AppColors.darkBackground
                                    : Colors.grey[100]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.lightPrimary)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                lang['native']!,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  fontSize: 13,
                                  color: isSelected
                                      ? (isDark
                                          ? AppColors.darkPrimary
                                          : AppColors.lightPrimary)
                                      : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.lightPrimary,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // State Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.tr('state'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : AppColors.lightCardBorder.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedState,
                        isExpanded: true,
                        dropdownColor:
                            isDark ? AppColors.darkSurface : AppColors.white,
                        items: stateNames.entries.map((e) {
                          return DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedState = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // District & Taluk
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('district'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _districtController,
                          decoration: InputDecoration(
                            hintText: loc.tr('district_hint'),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkBackground
                                : AppColors.lightCardBorder.withValues(alpha: 0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('taluk'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _talukController,
                          decoration: InputDecoration(
                            hintText: loc.tr('taluk_hint'),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkBackground
                                : AppColors.lightCardBorder.withValues(alpha: 0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Village
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.tr('village'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _villageController,
                    decoration: InputDecoration(
                      hintText: loc.tr('village_hint'),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkBackground
                          : AppColors.lightCardBorder.withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            loc.tr('save_changes'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
