import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../farm/presentation/dashboard_screen.dart';
import '../../farm/state/farm_notifier.dart';
import '../state/auth_notifier.dart';

class OnboardingFarmSetupScreen extends ConsumerStatefulWidget {
  const OnboardingFarmSetupScreen({super.key});

  @override
  ConsumerState<OnboardingFarmSetupScreen> createState() =>
      _OnboardingFarmSetupScreenState();
}

class _OnboardingFarmSetupScreenState
    extends ConsumerState<OnboardingFarmSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _farmerNameController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _districtController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _areaController = TextEditingController();

  String _selectedState = 'TN';
  String _selectedUnit = 'acre';
  final bool _dpdpAgreed = true;
  bool _isSubmitting = false;

  static const List<Map<String, String>> states = [
    {'code': 'TN', 'name': 'Tamil Nadu'},
    {'code': 'AP', 'name': 'Andhra Pradesh'},
    {'code': 'TG', 'name': 'Telangana'},
    {'code': 'KA', 'name': 'Karnataka'},
    {'code': 'KL', 'name': 'Kerala'},
    {'code': 'PY', 'name': 'Puducherry'},
  ];

  static const List<String> areaUnits = [
    'acre',
    'cent',
    'guntha',
    'ground',
    'ankanam',
    'hectare',
  ];

  @override
  void dispose() {
    _farmerNameController.dispose();
    _farmNameController.dispose();
    _districtController.dispose();
    _pincodeController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || !_dpdpAgreed) return;

    setState(() => _isSubmitting = true);

    final area = double.tryParse(_areaController.text.trim());
    final farmName = _farmNameController.text.trim();

    final loc = AppLocalizations(ref.read(localeProvider));
    // Create the primary farm holding
    await ref.read(farmNotifierProvider.notifier).createFarm(
          name: farmName.isNotEmpty ? farmName : loc.tr('primary_farm'),
          district: _districtController.text.trim(),
          stateCode: _selectedState,
          pincode: _pincodeController.text.trim(),
          enteredArea: area,
          enteredUnit: _selectedUnit,
          isPrimary: true,
        );

    ref.read(authNotifierProvider.notifier).completeOnboarding();

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(ref.watch(localeProvider));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Header Capsule
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
                      const Icon(Icons.nature_people_rounded,
                          size: 16, color: AppColors.lightAccentMint),
                      const SizedBox(width: 8),
                      Text(
                        loc.tr('farmer_onboarding_badge'),
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
                Text(
                  loc.tr('setup_profile'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  loc.tr('setup_subtitle'),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                // Farmer Name Field
                Text(
                  loc.tr('farmer_name'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _farmerNameController,
                  decoration: InputDecoration(
                    hintText: loc.tr('farmer_name_hint'),
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? loc.tr('enter_name_error')
                      : null,
                ),
                const SizedBox(height: 18),
                // Primary Farm Name
                Text(
                  loc.tr('farm_name'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _farmNameController,
                  decoration: InputDecoration(
                    hintText: loc.tr('farm_name_hint'),
                    prefixIcon: const Icon(Icons.landscape_outlined),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? loc.tr('enter_farm_name_error')
                      : null,
                ),
                const SizedBox(height: 18),
                // State & District Row
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.tr('state'),
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedState,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                            ),
                            items: states.map((s) {
                              return DropdownMenuItem(
                                value: s['code'],
                                child: Text(loc.translateState(s['code']!)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedState = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.tr('district'),
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _districtController,
                            decoration: InputDecoration(
                              hintText: loc.tr('district_hint'),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Land Area & Unit Row
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.tr('entered_area'),
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _areaController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              hintText: '2.5',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.tr('entered_unit'),
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedUnit,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                            items: areaUnits.map((u) {
                              return DropdownMenuItem(
                                value: u,
                                child: Text(loc.translateUnit(u)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedUnit = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // DPDP Act 2023 Consent Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkCardBorder
                          : AppColors.lightPrimary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.security_rounded,
                              color: AppColors.lightAccentMint, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loc.tr('dpdp_consent'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        loc.tr('dpdp_consent_body'),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(loc.tr('agree_and_continue')),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
