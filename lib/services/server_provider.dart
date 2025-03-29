import 'package:flowo_client/services/server_api_client.dart';
import 'package:flowo_client/services/server_time_estimation_strategy.dart';
import 'package:flowo_client/services/task_time_estimator.dart';
import 'package:flowo_client/utils/ai_model/server_task_breakdown_api.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Provides server-based implementations for task breakdown and estimation
class ServerProvider {
  /// Creates providers for server-based implementations
  ///
  /// This should be added to the provider tree in main.dart
  static List<SingleChildWidget> createProviders({
    required String serverUrl,
    required String apiKey,
  }) {
    return [
      // Server API client
      Provider<ServerApiClient>(
        create: (_) => ServerApiClient(baseUrl: serverUrl, apiKey: apiKey),
      ),

      // Server task breakdown API
      ProxyProvider<ServerApiClient, ServerTaskBreakdownAPI>(
        update: (_, apiClient, __) => ServerTaskBreakdownAPI(apiClient),
      ),

      // Server time estimation strategy
      ProxyProvider<ServerApiClient, ServerTimeEstimationStrategy>(
        update: (_, apiClient, __) => ServerTimeEstimationStrategy(apiClient),
      ),

      // Task time estimator with server strategy
      ProxyProvider<ServerTimeEstimationStrategy, TaskTimeEstimator>(
        update: (_, strategy, __) => TaskTimeEstimator(strategy),
      ),
    ];
  }
}
