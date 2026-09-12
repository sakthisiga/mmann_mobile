import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../state/farm_notifier.dart';
import 'add_farm_modal.dart';

class FarmSwitcherWidget extends ConsumerWidget {
  const FarmSwitcherWidget({super.key});

  void _showSwitcherModal(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = ref.read(localeProvider);
    final loc = AppLocalizations(currentLocale);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final farmState = ref.watch(farmNotifierProvider);
            final farms = farmState.farmsList;
            final activeFarm = farmState.activeFarm;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.tr('farm_switch_title'),
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
                                '${farms.length} ${farms.length == 1 ? loc.tr('farm_registered_singular') : loc.tr('farms_registered')}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Farms List or Empty State
                    if (farms.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightPillBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.landscape_rounded,
                              size: 36,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              loc.tr('no_farms_yet'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: farms.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                          final farm = farms[index];
                          final isSelected = activeFarm?.id == farm.id;

                          return InkWell(
                            onTap: () {
                              ref
                                  .read(farmNotifierProvider.notifier)
                                  .switchActiveFarm(farm.id);
                              Navigator.of(context).pop();
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? (isSelected
                                        ? AppColors.darkPillBackground
                                        : AppColors.darkSurface)
                                    : (isSelected
                                        ? AppColors.lightPillBackground
                                        : AppColors.lightBackground),
                                borderRadius: BorderRadius.circular(18),
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
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isDark
                                              ? AppColors.darkAccentCoral
                                              : AppColors.lightPrimary)
                                          : (isDark
                                              ? AppColors.darkCardBorder
                                              : AppColors.lightCardBorder),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '🌾',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                farm.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark
                                                      ? AppColors.darkTextPrimary
                                                      : AppColors.lightTextPrimary,
                                                ),
                                              ),
                                            ),
                                            if (farm.isPrimary) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.lightAccentMint
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  loc.tr('primary'),
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors
                                                        .lightAccentMint,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${farm.enteredArea != null ? "${farm.enteredArea} ${loc.translateUnit(farm.enteredUnit)}" : ""} · ${farm.district ?? loc.tr("south_india")}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      size: 19,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                    tooltip: loc.tr('edit_farm'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      AddFarmModal.show(context, farmToEdit: farm);
                                    },
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: isDark
                                          ? AppColors.darkAccentCoral
                                          : AppColors.lightPrimary,
                                      size: 22,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    ],
                    const SizedBox(height: 18),
                    // Add Farm Button
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        AddFarmModal.show(context);
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                      label: Text(loc.tr('add_new_farm')),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkCardBorder
                              : AppColors.lightCardBorder,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmState = ref.watch(farmNotifierProvider);
    final activeFarm = farmState.activeFarm;
    final farms = farmState.farmsList;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = ref.watch(localeProvider);
    final loc = AppLocalizations(currentLocale);
    final farmName = farms.isEmpty ? loc.tr('add_new_farm') : (activeFarm?.name ?? loc.tr('my_farm'));

    return InkWell(
      onTap: () => _showSwitcherModal(context, ref),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface
              : AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            width: 1,
          ),
          boxShadow: !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (farms.isEmpty)
              Icon(
                Icons.add_rounded,
                size: 16,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              )
            else
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lightAccentMint,
                ),
              ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                farmName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
