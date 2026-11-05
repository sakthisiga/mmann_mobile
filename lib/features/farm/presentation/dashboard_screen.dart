import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/presentation/edit_profile_sheet.dart';
import '../../auth/presentation/phone_login_screen.dart';
import '../../auth/state/auth_notifier.dart';
import '../../document/presentation/add_document_modal.dart';
import '../../document/presentation/documents_screen.dart';
import '../../document/state/document_notifier.dart';
import '../../plot/presentation/add_plot_modal.dart';
import '../../plot/presentation/plots_screen.dart';
import '../../plot/state/plot_notifier.dart';
import '../state/farm_notifier.dart';
import 'add_farm_modal.dart';
import 'farm_switcher_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedTab = 0; // 0: Overview, 1: Field Logs

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(farmNotifierProvider.notifier).loadFarms();
      ref.read(plotNotifierProvider.notifier).loadPlots();
      ref.read(documentNotifierProvider.notifier).loadDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final farmState = ref.watch(farmNotifierProvider);
    final plotState = ref.watch(plotNotifierProvider);
    final activeFarm = farmState.activeFarm;
    final activeFarmPlots = plotState.plotsForFarm(activeFarm?.id);
    final currentLocale = ref.watch(localeProvider);
    final loc = AppLocalizations(currentLocale);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = authState.currentUser;
    final farmerName = user?.displayName ?? loc.tr('farmer');

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 110, // Space for floating bottom capsule bar
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Navigation Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.white,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const FarmSwitcherWidget(),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => ref
                                .read(themeModeProvider.notifier)
                                .toggleDarkLight(isDark),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.white,
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: Icon(
                                isDark
                                    ? Icons.light_mode_rounded
                                    : Icons.dark_mode_rounded,
                                size: 19,
                                color: isDark
                                    ? const Color(0xFFFBBF24)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () => _showProfileMenu(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? AppColors.darkPrimary.withValues(alpha: 0.25)
                                    : AppColors.lightPrimary.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.lightPrimary,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  farmerName.isNotEmpty
                                      ? farmerName[0].toUpperCase()
                                      : 'F',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: isDark
                                        ? AppColors.darkPrimary
                                        : AppColors.lightPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Headline & Role Pill
                  Text(
                    loc.tr('operations'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${farmState.farmsList.length} ${loc.tr('active_holdings')}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      InkWell(
                        onTap: () => FarmSwitcherWidget.showSheet(context, ref),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkCardBorder
                                  : AppColors.lightCardBorder,
                            ),
                          ),
                          child: const Icon(Icons.tune_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 3 Stat Metric Cards (Multi-color themed)
                  Row(
                    children: [
                      // Stat 1: Total Farms (Emerald - tappable to open Farm Switcher)
                      Expanded(
                        child: InkWell(
                          onTap: () => FarmSwitcherWidget.showSheet(context, ref),
                          borderRadius: BorderRadius.circular(20),
                          child: _buildMetricCard(
                            context,
                            value: '${farmState.farmsList.length}',
                            label: loc.tr('active_farms'),
                            accentColor: const Color(0xFF059669),
                            isDark: isDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Stat 2: Total Cultivable Area (Indigo)
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          value: farmState.totalCultivableAcres.toStringAsFixed(1),
                          label: loc.tr('acres_total'),
                          accentColor: const Color(0xFF4F46E5),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Stat 3: Active Plots (Amber/Orange)
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PlotsScreen(),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: _buildMetricCard(
                            context,
                            value: '${activeFarmPlots.length}',
                            label: loc.tr('active_plots'),
                            accentColor: const Color(0xFFD97706),
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Active Farm Card Header with Add Farm Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.tr('active_farms_header'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => AddFarmModal.show(context),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(
                          loc.tr('add_new_farm'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                          foregroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildActiveFarmHoldingCard(
                    context,
                    farm: activeFarm,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  // Quick Actions Bar
                  Text(
                    loc.tr('quick_actions'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickActionButton(
                        icon: Icons.description_rounded,
                        label: loc.tr('documents'),
                        color: const Color(0xFFD97706),
                        isDark: isDark,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DocumentsScreen(),
                          ),
                        ),
                      ),
                      _buildQuickActionButton(
                        icon: Icons.currency_rupee_rounded,
                        label: loc.tr('expenses'),
                        color: AppColors.lightAccentCoral,
                        isDark: isDark,
                      ),
                      _buildQuickActionButton(
                        icon: Icons.water_drop_rounded,
                        label: loc.tr('irrigation'),
                        color: const Color(0xFF00B4D8),
                        isDark: isDark,
                      ),
                      _buildQuickActionButton(
                        icon: Icons.grass_rounded,
                        label: loc.tr('harvest'),
                        color: AppColors.lightAccentMint,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Floating Capsule Bottom Navigation Bar (Matching Reference Images!)
            Positioned(
              left: 32,
              right: 32,
              bottom: 24,
              child: _buildFloatingCapsuleNavBar(context, isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String value,
    required String label,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  accentColor.withValues(alpha: 0.18),
                  AppColors.darkSurface,
                ]
              : [
                  accentColor.withValues(alpha: 0.12),
                  AppColors.white,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.35 : 0.3),
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
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFarmHoldingCard(
    BuildContext context, {
    required dynamic farm,
    required bool isDark,
  }) {
    final loc = AppLocalizations(ref.watch(localeProvider));

    if (farm == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            width: 1,
          ),
          boxShadow: !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.landscape_rounded,
                size: 28,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              loc.tr('no_farms_yet'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loc.tr('add_first_farm_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => AddFarmModal.show(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                loc.tr('add_your_first_farm'),
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    final name = farm.name;
    final locationParts = [
      if (farm.village != null && (farm.village as String).isNotEmpty) farm.village,
      if (farm.district != null && (farm.district as String).isNotEmpty) farm.district,
    ];
    final locationText = locationParts.isNotEmpty
        ? locationParts.join(', ')
        : loc.tr('south_india');
    final unit = farm.enteredUnit != null
        ? loc.translateUnit(farm.enteredUnit)
        : loc.tr('unit_acre');
    final area = farm.enteredArea != null
        ? '${farm.enteredArea} $unit'
        : '0 $unit';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF4F46E5).withValues(alpha: 0.16),
                  AppColors.darkSurface,
                  const Color(0xFF059669).withValues(alpha: 0.12),
                ]
              : [
                  const Color(0xFFEEF2FF),
                  AppColors.white,
                  const Color(0xFFECFDF5),
                ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? const Color(0xFF6366F1).withValues(alpha: 0.4)
              : const Color(0xFFA5B4FC),
          width: 1.4,
        ),
        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 5,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4F46E5),
                  Color(0xFF059669),
                  Color(0xFF14B8A6),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locationText,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 19,
                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    ),
                    tooltip: loc.tr('edit_farm'),
                    onPressed: () => AddFarmModal.show(context, farmToEdit: farm),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 19,
                      color: AppColors.lightAccentCoral,
                    ),
                    tooltip: loc.tr('delete_farm'),
                    onPressed: () => _confirmDeleteFarm(context, farm.id, farm.name, loc),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkAccentCoral.withValues(alpha: 0.18)
                          : AppColors.lightAccentCoral.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.lightAccentCoral,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          loc.tr('status_active'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkAccentCoral
                                : AppColors.lightAccentCoral,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Plot Status Box (Tappable to open PlotsScreen / AddPlotModal)
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlotsScreen()),
            ),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground
                    : AppColors.lightPillBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.grid_view_rounded,
                    size: 18,
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ref.watch(plotNotifierProvider).plotsForFarm(farm.id).isEmpty
                          ? '${loc.tr('no_plots_configured')} • ${loc.tr('add_plot_hint')}'
                          : '${ref.watch(plotNotifierProvider).plotsForFarm(farm.id).length} ${loc.tr('plots_configured')} • ${loc.tr('manage_plots')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.add_circle_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    ),
                    tooltip: loc.tr('add_plot'),
                    onPressed: () => AddPlotModal.show(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Document Vault Box (Tappable to open DocumentsScreen / AddDocumentModal)
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DocumentsScreen()),
            ),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground
                    : AppColors.lightPillBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_rounded,
                    size: 18,
                    color: Color(0xFF059669),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${ref.watch(documentNotifierProvider).documentsForFarm(farm.id).length} ${loc.tr('documents')} • ${loc.tr('manage_documents')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.add_circle_rounded,
                      size: 20,
                      color: Color(0xFF059669),
                    ),
                    tooltip: loc.tr('add_document'),
                    onPressed: () => AddDocumentModal.show(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${ref.watch(plotNotifierProvider).plotsForFarm(farm.id).length} ${loc.tr('plots_configured')}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPillBackground
                      : AppColors.lightPillBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  area,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => AddFarmModal.show(context, farmToEdit: farm),
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  ),
                  label: Text(
                    loc.tr('edit_farm'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(
                      color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                          .withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _confirmDeleteFarm(context, farm.id, farm.name, loc),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: AppColors.lightAccentCoral,
                  ),
                  label: Text(
                    loc.tr('delete_farm'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightAccentCoral,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(
                      color: AppColors.lightAccentCoral.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

  Future<void> _confirmDeleteFarm(
    BuildContext context,
    String farmId,
    String farmName,
    AppLocalizations loc,
  ) async {
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
              farmName,
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

    if (confirmed == true) {
      await ref.read(farmNotifierProvider.notifier).deleteFarm(farmId);
      await ref.read(plotNotifierProvider.notifier).loadPlots();
    }
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark
                  ? color.withValues(alpha: 0.18)
                  : color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // Floating Pill Capsule Nav Bar (Directly from the uploaded image)
  Widget _buildFloatingCapsuleNavBar(
    BuildContext context, {
    required bool isDark,
  }) {
    final loc = AppLocalizations(ref.watch(localeProvider));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B28) : AppColors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tab 0: Overview / Pipelines
          InkWell(
            onTap: () => setState(() => _selectedTab = 0),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: _selectedTab == 0
                    ? (isDark
                        ? AppColors.darkAccentCoral
                        : AppColors.lightPrimary)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.segment_rounded,
                    size: 18,
                    color: _selectedTab == 0
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.tr('pipeline'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _selectedTab == 0
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Tab 1: Field Logs / Tasks
          InkWell(
            onTap: () => setState(() => _selectedTab = 1),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _selectedTab == 1
                    ? (isDark
                        ? AppColors.darkAccentCoral
                        : AppColors.lightPrimary)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.task_alt_rounded,
                    size: 18,
                    color: _selectedTab == 1
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.tr('tasks'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _selectedTab == 1
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.read(authNotifierProvider);
    final user = authState.currentUser;
    final org = authState.activeOrg;
    final mobile = user?.mobile ?? '';
    final role = org?.role ?? 'owner';

    const languages = [
      {'code': 'ta', 'native': 'தமிழ்', 'english': 'Tamil'},
      {'code': 'en', 'native': 'English', 'english': 'English'},
      {'code': 'te', 'native': 'తెలుగు', 'english': 'Telugu'},
      {'code': 'kn', 'native': 'ಕನ್ನಡ', 'english': 'Kannada'},
      {'code': 'ml', 'native': 'മലയാളം', 'english': 'Malayalam'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final currentLang = ref.watch(localeProvider).languageCode;
            final loc = AppLocalizations(Locale(currentLang));
            final farmerName = user?.displayName ?? loc.tr('farmer');
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SingleChildScrollView(
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

                    // User Header
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? AppColors.darkPrimary.withValues(alpha: 0.25)
                                : AppColors.lightPrimary.withValues(alpha: 0.12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              farmerName.isNotEmpty
                                  ? farmerName[0].toUpperCase()
                                  : 'F',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.lightPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                farmerName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.white : AppColors.darkSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mobile,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightAccentMint.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.lightAccentMint.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.lightAccentMint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    // Option to Edit Registration Details
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackground
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(Icons.edit_note_rounded, size: 22),
                        ),
                      ),
                      title: Text(
                        loc.tr('edit_profile_details'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        loc.tr('edit_profile_subtitle'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.pop(bottomCtx);
                        EditProfileSheet.show(context);
                      },
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Theme / Appearance Selection
                    Row(
                      children: [
                        Icon(
                          isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          loc.tr('theme_appearance'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(themeModeProvider.notifier)
                                  .setThemeMode(ThemeMode.light);
                              setModalState(() {});
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: !isDark
                                    ? AppColors.lightPrimary.withValues(alpha: 0.12)
                                    : AppColors.darkBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !isDark
                                      ? AppColors.lightPrimary
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.light_mode_rounded,
                                    size: 16,
                                    color: !isDark
                                        ? AppColors.lightPrimary
                                        : AppColors.darkTextSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      loc.tr('light_mode'),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: !isDark
                                            ? AppColors.lightPrimary
                                            : AppColors.darkTextSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(themeModeProvider.notifier)
                                  .setThemeMode(ThemeMode.dark);
                              setModalState(() {});
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkPrimary.withValues(alpha: 0.25)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkPrimary
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.dark_mode_rounded,
                                    size: 16,
                                    color: isDark
                                        ? AppColors.darkPrimary
                                        : AppColors.lightTextSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      loc.tr('dark_mode'),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.darkPrimary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Language Selection
                    Row(
                      children: [
                        const Icon(Icons.language_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          loc.tr('select_language'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: languages.map((lang) {
                        final isSelected = currentLang == lang['code'];
                        return InkWell(
                          onTap: () {
                            final chosenLang = lang['code']!;
                            ref
                                .read(localeProvider.notifier)
                                .setLocale(Locale(chosenLang));
                            setModalState(() {});
                            final currentUser = ref.read(authNotifierProvider).currentUser;
                            if (currentUser != null) {
                              ref.read(authNotifierProvider.notifier).updateProfile(
                                    displayName: currentUser.displayName ?? '',
                                    language: chosenLang,
                                  );
                            }
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
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    // Logout
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.lightAccentCoral.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.logout_rounded,
                            size: 20,
                            color: AppColors.lightAccentCoral,
                          ),
                        ),
                      ),
                      title: Text(
                        loc.tr('logout'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightAccentCoral,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(bottomCtx);
                        ref.read(authNotifierProvider.notifier).logout();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const PhoneLoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 18,
                              height: 18,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Image.asset(
                            isDark
                                ? 'assets/images/wordmark-light.png'
                                : 'assets/images/wordmark-dark.png',
                            height: 10,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '· மருதமண்',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
