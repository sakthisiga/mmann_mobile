import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/database_service.dart';
import '../data/farm_api_service.dart';
import '../data/farm_model.dart';
import 'farm_state.dart';

final farmNotifierProvider =
    StateNotifierProvider<FarmNotifier, FarmState>((ref) {
  final apiService = ref.watch(farmApiServiceProvider);
  return FarmNotifier(apiService);
});

class FarmNotifier extends StateNotifier<FarmState> {
  final FarmApiService _apiService;

  FarmNotifier(this._apiService) : super(const FarmState()) {
    loadFarms();
  }

  void reset() {
    state = const FarmState();
  }

  Future<void> loadFarms() async {
    // 1. Instant offline load from local SQLite
    final cachedMaps = await DatabaseService.getCachedFarms();
    if (cachedMaps.isNotEmpty) {
      final cachedFarms =
          cachedMaps.map((m) => Farm.fromSqlite(m)).toList();
      final active = cachedFarms.firstWhere(
        (f) => f.isPrimary,
        orElse: () => cachedFarms.first,
      );
      state = state.copyWith(
        farmsList: cachedFarms,
        activeFarm: active,
      );
    }

    // 2. Fetch fresh from backend and update SQLite cache
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final remoteFarms = await _apiService.getFarms();
      await DatabaseService.cacheFarms(
        remoteFarms.map((f) => f.toSqlite()).toList(),
      );

      final active = remoteFarms.isNotEmpty
          ? remoteFarms.firstWhere(
              (f) => f.isPrimary,
              orElse: () => remoteFarms.first,
            )
          : null;

      state = state.copyWith(
        farmsList: remoteFarms,
        activeFarm: active,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message ?? 'Failed to sync farms with server.',
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void switchActiveFarm(String farmId) {
    try {
      final selected = state.farmsList.firstWhere((f) => f.id == farmId);
      state = state.copyWith(activeFarm: selected);
    } catch (_) {}
  }

  Future<bool> createFarm({
    required String name,
    String? village,
    String? taluk,
    String? district,
    String? stateCode,
    String? pincode,
    double? enteredArea,
    String enteredUnit = 'acre',
    bool isPrimary = false,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final created = await _apiService.createFarm(
        name: name,
        village: village,
        taluk: taluk,
        district: district,
        stateCode: stateCode,
        pincode: pincode,
        enteredArea: enteredArea,
        enteredUnit: enteredUnit,
        isPrimary: isPrimary,
        notes: notes,
      );

      final updatedList = [...state.farmsList, created];
      await DatabaseService.cacheFarms(
        updatedList.map((f) => f.toSqlite()).toList(),
      );

      state = state.copyWith(
        farmsList: updatedList,
        activeFarm: created,
        isLoading: false,
      );
      return true;
    } on DioException catch (e) {
      final detail = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['detail'] as String? ?? e.message)
          : e.message;
      state = state.copyWith(
        isLoading: false,
        errorMessage: detail ?? 'Failed to create farm.',
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred creating farm.',
      );
      return false;
    }
  }

  Future<bool> updateFarm({
    required String id,
    required String name,
    String? village,
    String? taluk,
    String? district,
    String? stateCode,
    String? pincode,
    double? enteredArea,
    String enteredUnit = 'acre',
    bool isPrimary = false,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _apiService.updateFarm(
        id: id,
        name: name,
        village: village,
        taluk: taluk,
        district: district,
        stateCode: stateCode,
        pincode: pincode,
        enteredArea: enteredArea,
        enteredUnit: enteredUnit,
        isPrimary: isPrimary,
        notes: notes,
      );

      final updatedList = state.farmsList.map((f) {
        if (f.id == updated.id) return updated;
        if (updated.isPrimary) return f.copyWith(isPrimary: false);
        return f;
      }).toList();

      await DatabaseService.cacheFarms(
        updatedList.map((f) => f.toSqlite()).toList(),
      );

      state = state.copyWith(
        farmsList: updatedList,
        activeFarm:
            state.activeFarm?.id == updated.id ? updated : state.activeFarm,
        isLoading: false,
      );
      return true;
    } on DioException catch (e) {
      final detail = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['detail'] as String? ?? e.message)
          : e.message;
      state = state.copyWith(
        isLoading: false,
        errorMessage: detail ?? 'Failed to update farm.',
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred updating farm.',
      );
      return false;
    }
  }
}
