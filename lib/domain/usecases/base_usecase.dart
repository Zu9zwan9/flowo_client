/// Base use case interface following Clean Architecture principles.
/// This interface defines the contract for all use cases in the domain layer.
abstract class UseCase<Type, Params> {
  /// Execute the use case with the given parameters.
  Future<Type> execute(Params params);
}

/// Special case for use cases that don't require parameters.
class NoParams {
  const NoParams();
}

/// Base class for all use case failures.
abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;
}

/// Represents a failure due to network issues.
class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
}

/// Represents a failure due to server issues.
class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
}

/// Represents a failure due to cache issues.
class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

/// Represents a failure due to validation issues.
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

/// Represents a failure due to authentication issues.
class AuthFailure extends Failure {
  const AuthFailure(String message) : super(message);
}

/// Represents a failure due to permission issues.
class PermissionFailure extends Failure {
  const PermissionFailure(String message) : super(message);
}

/// Represents a generic failure.
class GenericFailure extends Failure {
  const GenericFailure(String message) : super(message);
}
