import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/database_service.dart';
import '../../farm/state/farm_notifier.dart';
import '../data/plot_api_service.dart';
import '../data/plot_model.dart';
import 'plot_state.dart';

final plotNotifierProvider =
    StateNotifierProvider<PlotNotifier, PlotState>((ref) {
  final apiService = ref.watch(plotApiServiceProvider);
  return PlotNotifier(apiService, ref);
});

class PlotNotifier extends StateNotifier<PlotState> {
  final PlotApiService _apiService;
  final Ref _ref;

  PlotNotifier(this._apiService, this._ref) : super(const PlotState()) {
    loadPlots();
    loadLandPortals();
  }

  Future<void> loadPlots() async {
    // 1. Instant offline read from local SQLite
    final cachedMaps = await DatabaseService.getCachedPlots();
    if (cachedMaps.isNotEmpty) {
      state = state.copyWith(
        plotsList: cachedMaps.map((m) => PlotModel.fromSqlite(m)).toList(),
      );
    }

    // 2. Refresh from server & update SQLite cache
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final remotePlots = await _apiService.getPlots();
      await DatabaseService.cachePlots(
        remotePlots.map((p) => p.toSqlite()).toList(),
      );
      state = state.copyWith(
        plotsList: remotePlots,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadLandPortals() async {
    try {
      final portals = await _apiService.getLandPortals();
      state = state.copyWith(portalsList: portals);
    } catch (_) {}
  }

  Future<bool> createPlot({
    required String farmId,
    required String name,
    String? surveyNumber,
    String? subDivisionNumber,
    String? pattaNumber,
    double? enteredArea,
    String enteredUnit = 'cent',
    String? soilType,
    String? irrigationSource,
    String tenureType = 'owned',
    String? lessorName,
    double? annualRentInr,
    double? cropSharePct,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final created = await _apiService.createPlot(
        farmId: farmId,
        name: name,
        surveyNumber: surveyNumber,
        subDivisionNumber: subDivisionNumber,
        pattaNumber: pattaNumber,
        enteredArea: enteredArea,
        enteredUnit: enteredUnit,
        soilType: soilType,
        irrigationSource: irrigationSource,
        tenureType: tenureType,
        lessorName: lessorName,
        annualRentInr: annualRentInr,
        cropSharePct: cropSharePct,
      );

      final updated = [...state.plotsList, created];
      await DatabaseService.cachePlots(
        updated.map((p) => p.toSqlite()).toList(),
      );
      state = state.copyWith(plotsList: updated, isLoading: false);
      await _ref.read(farmNotifierProvider.notifier).loadFarms();
      return true;
    } on DioException catch (e) {
      final detail = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['detail'] as String? ?? e.message)
          : e.message;
      state = state.copyWith(isLoading: false, errorMessage: detail);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create plot.',
      );
      return false;
    }
  }

  Future<bool> updatePlot({
    required String id,
    required String name,
    String? surveyNumber,
    String? subDivisionNumber,
    String? pattaNumber,
    double? enteredArea,
    String enteredUnit = 'cent',
    String? soilType,
    String? irrigationSource,
    String tenureType = 'owned',
    String? lessorName,
    double? annualRentInr,
    double? cropSharePct,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedPlot = await _apiService.updatePlot(
        id: id,
        name: name,
        surveyNumber: surveyNumber,
        subDivisionNumber: subDivisionNumber,
        pattaNumber: pattaNumber,
        enteredArea: enteredArea,
        enteredUnit: enteredUnit,
        soilType: soilType,
        irrigationSource: irrigationSource,
        tenureType: tenureType,
        lessorName: lessorName,
        annualRentInr: annualRentInr,
        cropSharePct: cropSharePct,
      );

      final updatedList = state.plotsList
          .map((p) => p.id == updatedPlot.id ? updatedPlot : p)
          .toList();
      await DatabaseService.cachePlots(
        updatedList.map((p) => p.toSqlite()).toList(),
      );
      state = state.copyWith(plotsList: updatedList, isLoading: false);
      await _ref.read(farmNotifierProvider.notifier).loadFarms();
      return true;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<void> deletePlot(String id) async {
    try {
      await _apiService.deletePlot(id);
      final updatedList = state.plotsList.where((p) => p.id != id).toList();
      await DatabaseService.cachePlots(
        updatedList.map((p) => p.toSqlite()).toList(),
      );
      state = state.copyWith(plotsList: updatedList);
      await _ref.read(farmNotifierProvider.notifier).loadFarms();
    } catch (_) {}
  }
}

