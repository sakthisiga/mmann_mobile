import '../data/plot_model.dart';

class PlotState {
  final List<PlotModel> plotsList;
  final List<StateLandPortalModel> portalsList;
  final bool isLoading;
  final String? errorMessage;

  const PlotState({
    this.plotsList = const [],
    this.portalsList = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  List<PlotModel> plotsForFarm(String? farmId) {
    if (farmId == null) return plotsList;
    return plotsList.where((p) => p.farmId == farmId).toList();
  }

  PlotState copyWith({
    List<PlotModel>? plotsList,
    List<StateLandPortalModel>? portalsList,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlotState(
      plotsList: plotsList ?? this.plotsList,
      portalsList: portalsList ?? this.portalsList,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

