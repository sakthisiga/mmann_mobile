import '../data/farm_model.dart';

class FarmState {
  final List<Farm> farmsList;
  final Farm? activeFarm;
  final bool isLoading;
  final String? errorMessage;

  const FarmState({
    this.farmsList = const [],
    this.activeFarm,
    this.isLoading = false,
    this.errorMessage,
  });

  FarmState copyWith({
    List<Farm>? farmsList,
    Farm? activeFarm,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FarmState(
      farmsList: farmsList ?? this.farmsList,
      activeFarm: activeFarm ?? this.activeFarm,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  Farm? get primaryFarm {
    for (final f in farmsList) {
      if (f.isPrimary) return f;
    }
    return activeFarm ?? (farmsList.isNotEmpty ? farmsList.first : null);
  }

  double get totalCultivableAcres {
    double total = 0.0;
    for (final f in farmsList) {
      if (f.enteredArea != null) {
        if (f.enteredUnit == 'cent') {
          total += f.enteredArea! / 100.0;
        } else if (f.enteredUnit == 'guntha') {
          total += f.enteredArea! / 40.0;
        } else {
          total += f.enteredArea!;
        }
      }
    }
    return total;
  }
}
