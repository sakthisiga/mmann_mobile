import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../farm/state/farm_notifier.dart';
import '../data/plot_model.dart';
import '../state/plot_notifier.dart';
import 'add_plot_modal.dart';

class PlotsScreen extends ConsumerWidget {
  const PlotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations(ref.watch(localeProvider));
    final farmState = ref.watch(farmNotifierProvider);
    final plotState = ref.watch(plotNotifierProvider);
    final activeFarm = farmState.activeFarm;
    final plots = plotState.plotsForFarm(activeFarm?.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stateCode = activeFarm?.stateCode ?? 'TN';
    final portal = plotState.portalsList
            .where((p) => p.stateCode == stateCode)
            .firstOrNull ??
        plotState.portalsList.firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.tr('plots_page_title'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: () => AddPlotModal.show(context),
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: loc.tr('add_plot'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddPlotModal.show(context),
        backgroundColor:
            isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          loc.tr('add_plot'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
        children: [
          // Official State Land Portal Verification Card
          if (portal != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkPrimary.withValues(alpha: 0.12)
                    : AppColors.lightPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkPrimary.withValues(alpha: 0.35)
                      : AppColors.lightPrimary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_rounded, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${loc.tr('official_land_portal')} · ${portal.portalName}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.tr('legal_portal_disclaimer'),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    portal.portalUrl,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          if (plots.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkCardBorder
                      : AppColors.lightCardBorder,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.grid_view_rounded,
                    size: 42,
                    color:
                        isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.tr('no_plots_configured'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.tr('add_plot_hint'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ...plots.asMap().entries.map((entry) => _buildPlotCard(
                  context,
                  ref,
                  entry.value,
                  entry.key,
                  loc,
                  isDark,
                )),
        ],
      ),
    );
  }

  Widget _buildPlotCard(
    BuildContext context,
    WidgetRef ref,
    PlotModel plot,
    int index,
    AppLocalizations loc,
    bool isDark,
  ) {
    final unit = plot.enteredUnit != null
        ? loc.translateUnit(plot.enteredUnit!)
        : loc.tr('unit_cent');
    final tenureKey = 'tenure_${plot.tenure.tenureType}';
    const palette = <Color>[
      Color(0xFF059669), // Emerald Paddy
      Color(0xFF4F46E5), // Indigo River
      Color(0xFFD97706), // Amber Harvest
      Color(0xFFE11D48), // Rose Coral
      Color(0xFF7C3AED), // Violet Millet
      Color(0xFF0891B2), // Cyan Canal
    ];
    final accentColor = palette[index % palette.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  accentColor.withValues(alpha: 0.16),
                  AppColors.darkSurface,
                ]
              : [
                  accentColor.withValues(alpha: 0.10),
                  AppColors.white,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.4 : 0.32),
          width: 1.2,
        ),
        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            width: double.infinity,
            color: accentColor,
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        plot.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.edit_outlined,
                              size: 18, color: accentColor),
                          onPressed: () =>
                              AddPlotModal.show(context, plotToEdit: plot),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.lightAccentCoral,
                          ),
                          onPressed: () => ref
                              .read(plotNotifierProvider.notifier)
                              .deletePlot(plot.id),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(loc.tr(tenureKey), accentColor, isDark),
                    if (plot.surveyNumber != null &&
                        plot.surveyNumber!.isNotEmpty)
                      _chip(
                        '${loc.tr('survey_number')}: ${plot.surveyNumber}${plot.subDivisionNumber != null && plot.subDivisionNumber!.isNotEmpty ? '/${plot.subDivisionNumber}' : ''}',
                        accentColor,
                        isDark,
                      ),
                    if (plot.pattaNumber != null &&
                        plot.pattaNumber!.isNotEmpty)
                      _chip(
                        '${loc.tr('patta_number')}: ${plot.pattaNumber}',
                        accentColor,
                        isDark,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        [
                          if (plot.soilType != null)
                            loc.tr('soil_${plot.soilType}'),
                          if (plot.irrigationSource != null)
                            loc.tr('irr_${plot.irrigationSource}'),
                        ].join(' · '),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${plot.enteredArea ?? 0} $unit (${(plot.areaSqm ?? 0).toStringAsFixed(0)} m²)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

