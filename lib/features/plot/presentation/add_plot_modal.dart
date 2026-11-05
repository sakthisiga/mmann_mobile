import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../farm/state/farm_notifier.dart';
import '../data/plot_model.dart';
import '../state/plot_notifier.dart';

class AddPlotModal extends ConsumerStatefulWidget {
  final PlotModel? plotToEdit;

  const AddPlotModal({super.key, this.plotToEdit});

  static Future<void> show(BuildContext context, {PlotModel? plotToEdit}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddPlotModal(plotToEdit: plotToEdit),
    );
  }

  @override
  ConsumerState<AddPlotModal> createState() => _AddPlotModalState();
}

class _AddPlotModalState extends ConsumerState<AddPlotModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _surveyController;
  late final TextEditingController _subDivController;
  late final TextEditingController _pattaController;
  late final TextEditingController _areaController;
  late final TextEditingController _lessorNameController;
  late final TextEditingController _rentController;
  late final TextEditingController _cropShareController;

  String _selectedUnit = 'cent';
  String _selectedSoil = 'red_loam';
  String _selectedIrrigation = 'borewell';
  String _selectedTenure = 'owned';

  static const _units = [
    'cent',
    'acre',
    'guntha',
    'ground',
    'ankanam',
    'hectare',
  ];

  static const _soils = [
    'red_loam',
    'black_cotton',
    'alluvial_delta',
    'clay_loam',
    'sandy_coastal',
    'laterite',
    'gravelly',
  ];

  static const _irrigations = [
    'borewell',
    'open_well',
    'canal',
    'drip_micro',
    'rainfed',
    'farm_pond',
    'river_lift',
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.plotToEdit;
    _nameController = TextEditingController(text: edit?.name ?? '');
    _surveyController = TextEditingController(text: edit?.surveyNumber ?? '');
    _subDivController =
        TextEditingController(text: edit?.subDivisionNumber ?? '');
    _pattaController = TextEditingController(text: edit?.pattaNumber ?? '');
    _areaController = TextEditingController(
      text: edit?.enteredArea != null ? edit!.enteredArea.toString() : '',
    );
    _lessorNameController =
        TextEditingController(text: edit?.tenure.lessorName ?? '');
    _rentController = TextEditingController(
      text: edit?.tenure.annualRentInr != null
          ? edit!.tenure.annualRentInr.toString()
          : '',
    );
    _cropShareController = TextEditingController(
      text: edit?.tenure.cropSharePct != null
          ? edit!.tenure.cropSharePct.toString()
          : '',
    );

    if (edit != null) {
      _selectedUnit = edit.enteredUnit ?? 'cent';
      _selectedSoil = edit.soilType ?? 'red_loam';
      _selectedIrrigation = edit.irrigationSource ?? 'borewell';
      _selectedTenure = edit.tenure.tenureType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surveyController.dispose();
    _subDivController.dispose();
    _pattaController.dispose();
    _areaController.dispose();
    _lessorNameController.dispose();
    _rentController.dispose();
    _cropShareController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final activeFarm = ref.read(farmNotifierProvider).activeFarm;
    if (widget.plotToEdit == null && activeFarm == null) return;

    final area = double.tryParse(_areaController.text.trim());
    final rent = double.tryParse(_rentController.text.trim());
    final share = double.tryParse(_cropShareController.text.trim());

    final notifier = ref.read(plotNotifierProvider.notifier);
    bool success;

    if (widget.plotToEdit != null) {
      success = await notifier.updatePlot(
        id: widget.plotToEdit!.id,
        name: _nameController.text.trim(),
        surveyNumber: _surveyController.text.trim(),
        subDivisionNumber: _subDivController.text.trim(),
        pattaNumber: _pattaController.text.trim(),
        enteredArea: area,
        enteredUnit: _selectedUnit,
        soilType: _selectedSoil,
        irrigationSource: _selectedIrrigation,
        tenureType: _selectedTenure,
        lessorName: _lessorNameController.text.trim(),
        annualRentInr: rent,
        cropSharePct: share,
      );
    } else {
      success = await notifier.createPlot(
        farmId: activeFarm!.id,
        name: _nameController.text.trim(),
        surveyNumber: _surveyController.text.trim(),
        subDivisionNumber: _subDivController.text.trim(),
        pattaNumber: _pattaController.text.trim(),
        enteredArea: area,
        enteredUnit: _selectedUnit,
        soilType: _selectedSoil,
        irrigationSource: _selectedIrrigation,
        tenureType: _selectedTenure,
        lessorName: _lessorNameController.text.trim(),
        annualRentInr: rent,
        cropSharePct: share,
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(ref.watch(localeProvider));
    final plotState = ref.watch(plotNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.plotToEdit != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Text(
                isEditing ? loc.tr('edit_plot') : loc.tr('add_plot'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.tr('plot_name'),
                  hintText: loc.tr('plot_name_hint'),
                  prefixIcon: const Icon(Icons.grid_view_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _surveyController,
                      decoration: InputDecoration(
                        labelText: loc.tr('survey_number'),
                        hintText: loc.tr('survey_number_hint'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _subDivController,
                      decoration: InputDecoration(
                        labelText: loc.tr('sub_division_number'),
                        hintText: loc.tr('sub_division_hint'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pattaController,
                      decoration: InputDecoration(
                        labelText: loc.tr('patta_number'),
                        hintText: loc.tr('patta_hint'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _areaController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: loc.tr('entered_area'),
                        hintText: '100',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedUnit,
                decoration: InputDecoration(
                  labelText: loc.tr('entered_unit'),
                ),
                items: _units
                    .map(
                      (u) => DropdownMenuItem(
                        value: u,
                        child: Text(loc.translateUnit(u)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedUnit = v);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSoil,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: loc.tr('soil_type'),
                      ),
                      items: _soils
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                loc.tr('soil_$s'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedSoil = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedIrrigation,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: loc.tr('irrigation_source'),
                      ),
                      items: _irrigations
                          .map(
                            (irr) => DropdownMenuItem(
                              value: irr,
                              child: Text(
                                loc.tr('irr_$irr'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedIrrigation = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                loc.tr('tenure_type'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(loc.tr('tenure_owned')),
                    selected: _selectedTenure == 'owned',
                    onSelected: (_) =>
                        setState(() => _selectedTenure = 'owned'),
                  ),
                  ChoiceChip(
                    label: Text(loc.tr('tenure_leased_cash')),
                    selected: _selectedTenure == 'leased_cash',
                    onSelected: (_) =>
                        setState(() => _selectedTenure = 'leased_cash'),
                  ),
                  ChoiceChip(
                    label: Text(loc.tr('tenure_leased_cropshare')),
                    selected: _selectedTenure == 'leased_cropshare',
                    onSelected: (_) =>
                        setState(() => _selectedTenure = 'leased_cropshare'),
                  ),
                ],
              ),
              if (_selectedTenure != 'owned') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lessorNameController,
                        decoration: InputDecoration(
                          labelText: loc.tr('lessor_name'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _selectedTenure == 'leased_cash'
                          ? TextFormField(
                              controller: _rentController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: loc.tr('annual_rent_inr'),
                              ),
                            )
                          : TextFormField(
                              controller: _cropShareController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: loc.tr('crop_share_pct'),
                              ),
                            ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: plotState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    plotState.isLoading
                        ? loc.tr('saving')
                        : (isEditing
                            ? loc.tr('save_changes')
                            : loc.tr('save_plot')),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
