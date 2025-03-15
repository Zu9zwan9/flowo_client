

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowo_client/blocs/analytics/analytics_state.dart';
import 'package:flowo_client/models/analytics_data.dart';
import 'package:flowo_client/services/analytics_service.dart';
import 'package:flowo_client/utils/logger.dart';

/// Cubit for managing analytics state
class AnalyticsCubit extends Cubit<AnalyticsState> {
  final AnalyticsService _analyticsService;

  /// Constructor
  AnalyticsCubit(this._analyticsService) : super(AnalyticsInitial());

  /// Load analytics data
  Future<void> loadAnalytics() async {
    try {
      emit(AnalyticsLoading());

      final analyticsData = await _analyticsService.getAnalyticsData();

      emit(AnalyticsLoaded(analyticsData));
    } catch (e) {
      logger.e('Error loading analytics: $e');
      emit(AnalyticsError('Failed to load analytics data: ${e.toString()}'));
    }
  }

  /// Get category distribution data for charts
  List<CategoryDataPoint> getCategoryDistribution() {
    return _analyticsService.getCategoryDistribution();
  }

  /// Get priority distribution data for charts
  List<PriorityDataPoint> getPriorityDistribution() {
    return _analyticsService.getPriorityDistribution();
  }

  /// Get completion rate by category data for charts
  List<CategoryDataPoint> getCompletionRateByCategory() {
    return _analyticsService.getCompletionRateByCategory();
  }

  /// Get priority label
  String getPriorityLabel(int priority) {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      case 4:
        return 'Urgent';
      default:
        return 'Unknown';
    }
  }

  /// Get priority color
  Color getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return CupertinoColors.systemBlue;
      case 2:
        return CupertinoColors.systemGreen;
      case 3:
        return CupertinoColors.systemOrange;
      case 4:
        return CupertinoColors.systemRed;
      default:
        return CupertinoColors.systemGrey;
    }
  }
}
