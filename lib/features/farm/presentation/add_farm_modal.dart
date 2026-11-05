import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/storage/database_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_api_service.dart';
import '../../auth/state/auth_notifier.dart';
import '../../plot/state/plot_notifier.dart';
import '../data/farm_model.dart';
import '../state/farm_notifier.dart';

class AddFarmModal extends ConsumerStatefulWidget {
  final Farm? farmToEdit;

  const AddFarmModal({super.key, this.farmToEdit});

  static Future<void> show(BuildContext context, {Farm? farmToEdit}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddFarmModal(farmToEdit: farmToEdit),
    );
  }

  @override
  ConsumerState<AddFarmModal> createState() => _AddFarmModalState();
}

class _AddFarmModalState extends ConsumerState<AddFarmModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _villageController = TextEditingController();
  final _districtController = TextEditingController();
  final _pincodeController = TextEditingController();

  String _selectedState = 'TN';
  String _selectedUnit = 'acre';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.farmToEdit != null) {
      final f = widget.farmToEdit!;
      _nameController.text = f.name;
      _villageController.text = f.village ?? '';
      _districtController.text = f.district ?? '';
      _pincodeController.text = f.pincode ?? '';
      _selectedState = f.stateCode ?? 'TN';
      if (areaUnits.contains(f.enteredUnit)) {
        _selectedUnit = f.enteredUnit;
      }
    } else {
      final authState = ref.read(authNotifierProvider);
      final farmState = ref.read(farmNotifierProvider);

      final initialVillage = authState.activeOrg?.village?.isNotEmpty == true
          ? authState.activeOrg!.village!
          : (authState.pendingRegistration?.village.isNotEmpty == true
              ? authState.pendingRegistration!.village
              : (farmState.primaryFarm?.village ?? ''));

      final initialDistrict = authState.activeOrg?.district?.isNotEmpty == true
          ? authState.activeOrg!.district!
          : (authState.pendingRegistration?.district.isNotEmpty == true
              ? authState.pendingRegistration!.district
              : (farmState.primaryFarm?.district ?? ''));

      final initialState = authState.activeOrg?.stateCode.isNotEmpty == true
          ? authState.activeOrg!.stateCode
          : (farmState.primaryFarm?.stateCode ?? 'TN');

      _villageController.text = initialVillage;
      _districtController.text = initialDistrict;
      _selectedState = initialState;

      if (initialVillage.isEmpty || initialDistrict.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadLocationFallback();
        });
      }
    }
  }

  Future<void> _loadLocationFallback() async {
    try {
      final cached = await DatabaseService.getCachedUserProfile();
      if (cached != null && mounted) {
        final v = cached['village'] as String?;
        final d = cached['district'] as String?;
        if (_villageController.text.trim().isEmpty && v != null && v.isNotEmpty) {
          setState(() => _villageController.text = v);
        }
        if (_districtController.text.trim().isEmpty && d != null && d.isNotEmpty) {
          setState(() => _districtController.text = d);
        }
      }
    } catch (_) {}

    try {
      final api = ref.read(authApiServiceProvider);
      final me = await api.getMe();
      if (mounted && me['org'] != null) {
        final orgMap = me['org'] as Map<String, dynamic>;
        final v = orgMap['village'] as String?;
        final d = orgMap['district'] as String?;
        if (_villageController.text.trim().isEmpty && v != null && v.isNotEmpty) {
          setState(() => _villageController.text = v);
        }
        if (_districtController.text.trim().isEmpty && d != null && d.isNotEmpty) {
          setState(() => _districtController.text = d);
        }
      }
    } catch (_) {}
  }

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
    _nameController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final isEdit = widget.farmToEdit != null;
    bool success;

    if (isEdit) {
      success = await ref.read(farmNotifierProvider.notifier).updateFarm(
            id: widget.farmToEdit!.id,
            name: _nameController.text.trim(),
            village: _villageController.text.trim(),
            district: _districtController.text.trim(),
            stateCode: _selectedState,
            pincode: _pincodeController.text.trim(),
            enteredUnit: _selectedUnit,
            isPrimary: widget.farmToEdit!.isPrimary,
          );
      if (mounted && success) {
        final loc = AppLocalizations(ref.read(localeProvider));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.tr('farm_updated_successfully')),
            backgroundColor: AppColors.lightPrimary,
          ),
        );
      }
    } else {
      final isFirst = ref.read(farmNotifierProvider).farmsList.isEmpty;
      success = await ref.read(farmNotifierProvider.notifier).createFarm(
            name: _nameController.text.trim(),
            village: _villageController.text.trim().isEmpty ? null : _villageController.text.trim(),
            district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
            stateCode: _selectedState,
            pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
            enteredUnit: _selectedUnit,
            isPrimary: isFirst,
          );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleDelete(AppLocalizations loc) async {
    final farm = widget.farmToEdit;
    if (farm == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.lightAccentCoral),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc.tr('confirm_delete_farm_title'),
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              farm.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.lightAccentCoral,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.tr('confirm_delete_farm_desc'),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(loc.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightAccentCoral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              loc.tr('confirm_delete_btn'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isSubmitting = true);
    final success =
        await ref.read(farmNotifierProvider.notifier).deleteFarm(farm.id);
    await ref.read(plotNotifierProvider.notifier).loadPlots();
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final loc = AppLocalizations(currentLocale);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : AppColors.lightCardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.farmToEdit != null
                        ? loc.tr('edit_farm')
                        : loc.tr('add_new_farm'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '${loc.tr('farm_name')} (${loc.tr('add_farm_hint')})',
                  prefixIcon: const Icon(Icons.landscape_rounded),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? loc.tr('enter_farm_name_error')
                    : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _villageController,
                      decoration: InputDecoration(
                        labelText: loc.tr('village'),
                        hintText: loc.tr('village_hint'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      decoration: InputDecoration(
                        labelText: loc.tr('district'),
                        hintText: loc.tr('district_hint'),
                      ),
                    ),
                  ),
                ],
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _villageController,
                builder: (context, villageVal, _) {
                  return ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _districtController,
                    builder: (context, districtVal, _) {
                      if (villageVal.text.trim().isEmpty && districtVal.text.trim().isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 13,
                              color: isDark ? AppColors.darkAccentMint : AppColors.lightAccentMint,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                loc.tr('autofilled_location_hint'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.darkAccentMint : AppColors.lightAccentMint,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedState,
                      decoration: InputDecoration(
                        labelText: loc.tr('state'),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'TN', child: Text('TN (Tamil Nadu)')),
                        DropdownMenuItem(value: 'AP', child: Text('AP (Andhra Pradesh)')),
                        DropdownMenuItem(value: 'TG', child: Text('TG (Telangana)')),
                        DropdownMenuItem(value: 'KA', child: Text('KA (Karnataka)')),
                        DropdownMenuItem(value: 'KL', child: Text('KL (Kerala)')),
                        DropdownMenuItem(value: 'PY', child: Text('PY (Puducherry)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedState = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: loc.tr('pincode'),
                        hintText: '638656',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedUnit,
                decoration: InputDecoration(
                  labelText: loc.tr('entered_unit'),
                  prefixIcon: const Icon(Icons.straighten_rounded),
                ),
                items: areaUnits.map((u) {
                  return DropdownMenuItem(
                    value: u,
                    child: Text(loc.translateUnit(u)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedUnit = val);
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDark
                          ? AppColors.darkAccentMint
                          : AppColors.lightPrimary)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (isDark
                            ? AppColors.darkAccentMint
                            : AppColors.lightPrimary)
                        .withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.calculate_outlined,
                      size: 18,
                      color: isDark
                          ? AppColors.darkAccentMint
                          : AppColors.lightPrimary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.farmToEdit != null
                            ? '${loc.tr('entered_area')}: ${widget.farmToEdit!.enteredArea ?? 0} ${loc.translateUnit(widget.farmToEdit!.enteredUnit)} • ${loc.tr('farm_area_auto_calc_note')}'
                            : loc.tr('farm_area_auto_calc_note'),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSave,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.farmToEdit != null
                        ? loc.tr('save_changes')
                        : loc.tr('add_new_farm')),
              ),
              if (widget.farmToEdit != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : () => _handleDelete(loc),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 19,
                      color: AppColors.lightAccentCoral,
                    ),
                    label: Text(
                      loc.tr('delete_farm'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.lightAccentCoral,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: AppColors.lightAccentCoral.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
