import '../../domain/usecases/base_usecase.dart';

/// Base repository interface following Clean Architecture principles.
/// This interface defines the contract for all repositories in the data layer.
abstract class Repository<T> {
  /// Get all entities of type T.
  Future<List<T>> getAll();

  /// Get an entity by its ID.
  Future<T?> getById(String id);

  /// Save an entity.
  Future<void> save(T entity);

  /// Update an entity.
  Future<void> update(T entity);

  /// Delete an entity by its ID.
  Future<void> delete(String id);
}

/// Base implementation of the Repository interface with error handling.
abstract class BaseRepository<T> implements Repository<T> {
  /// Executes a repository operation with error handling.
  Future<R> executeWithErrorHandling<R>(Future<R> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      throw _mapExceptionToFailure(e);
    }
  }

  /// Maps exceptions to domain failures.
  Failure _mapExceptionToFailure(dynamic exception) {
    // Map different types of exceptions to appropriate failures
    if (exception is Exception) {
      if (exception.toString().contains('SocketException') ||
          exception.toString().contains('Connection')) {
        return NetworkFailure('Network error: ${exception.toString()}');
      } else if (exception.toString().contains('HttpException') ||
          exception.toString().contains('StatusCode')) {
        return ServerFailure('Server error: ${exception.toString()}');
      } else if (exception.toString().contains('Cache') ||
          exception.toString().contains('Storage')) {
        return CacheFailure('Cache error: ${exception.toString()}');
      } else if (exception.toString().contains('Permission')) {
        return PermissionFailure('Permission error: ${exception.toString()}');
      } else if (exception.toString().contains('Auth') ||
          exception.toString().contains('Unauthorized')) {
        return AuthFailure('Authentication error: ${exception.toString()}');
      }
    }

    // Default to generic failure
    return GenericFailure('An error occurred: ${exception.toString()}');
  }
}
