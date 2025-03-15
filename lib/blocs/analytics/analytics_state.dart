import 'package:equatable/equatable.dart';
import 'package:flowo_client/models/analytics_data.dart';

/// Base class for analytics states
abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the analytics screen is first loaded
class AnalyticsInitial extends AnalyticsState {}

/// State when analytics data is being loaded
class AnalyticsLoading extends AnalyticsState {}

/// State when analytics data has been successfully loaded
class AnalyticsLoaded extends AnalyticsState {
  final AnalyticsData analyticsData;

  const AnalyticsLoaded(this.analyticsData);

  @override
  List<Object?> get props => [analyticsData];
}

/// State when there is an error loading analytics data
class AnalyticsError extends AnalyticsState {
  final String message;

  const AnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}
