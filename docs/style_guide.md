# Dart & Flutter Style Guide

This document outlines the coding standards and best practices for Dart and Flutter development in this project.

## Table of Contents
1. [Naming Conventions](#naming-conventions)
2. [Code Formatting](#code-formatting)
3. [Architectural Patterns](#architectural-patterns)
4. [State Management](#state-management)
5. [Asynchronous Programming](#asynchronous-programming)
6. [Error Handling](#error-handling)
7. [Documentation](#documentation)
8. [Testing](#testing)
9. [Common Pitfalls](#common-pitfalls)
10. [Performance Considerations](#performance-considerations)

## Naming Conventions

### General Rules
- Use `lowerCamelCase` for variables, functions, and method names
- Use `UpperCamelCase` for class, enum, typedef, and extension names
- Use `lowercase_with_underscores` for file names

### Specific Conventions
- Prefix private members with underscore: `_privateVariable`
- Use nouns for class names: `TaskManager`, not `ManageTasks`
- Use verbs for method names: `fetchData()`, not `data()`
- Be descriptive and avoid abbreviations: `userAuthentication`, not `userAuth`
- UI widget variables should end with their type: `loginButton`, `userNameTextField`

## Code Formatting

- Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use 2-space indentation
- Limit lines to 80 characters where possible
- Use trailing commas for multi-line parameter lists to improve formatting
- Run `dart format` before committing code

## Architectural Patterns

### Preferred Patterns
- **Repository Pattern**: Abstract data sources behind repository interfaces
- **Service Locator**: Use for dependency injection (consider `get_it` package)
- **BLoC/Cubit**: For state management in complex screens
- **Provider**: For simpler state management needs

### File Organization
- Group related files in feature-based directories
- Separate business logic from UI components
- Follow the structure:
  ```
  lib/
    ├── features/
    │   ├── feature_name/
    │   │   ├── data/
    │   │   ├── domain/
    │   │   └── presentation/
    ├── core/
    ├── utils/
    └── main.dart
  ```

## State Management

- Prefer immutable state objects
- Use appropriate state management based on complexity:
  - `Provider` for simple state
  - `BLoC/Cubit` for complex state with many events
  - `Riverpod` for more advanced dependency injection needs
- Avoid using `setState()` for complex state management
- Keep UI components as stateless as possible

## Asynchronous Programming

- Use `async`/`await` over raw `Future` callbacks
- Handle errors in async code with try/catch blocks
- Consider using `FutureBuilder` and `StreamBuilder` for UI updates
- Prefer `Stream` for continuous data updates
- Use `Completer` only when necessary for advanced use cases

```dart
// Preferred
Future<void> fetchData() async {
  try {
    final result = await apiService.getData();
    // Process result
  } catch (e) {
    // Handle error
    logError('Failed to fetch data: $e');
  }
}

// Avoid
void fetchData() {
  apiService.getData().then((result) {
    // Process result
  }).catchError((e) {
    // Handle error
  });
}
```

## Error Handling

- Use specific exception types for different error scenarios
- Log errors with appropriate context information
- Provide user-friendly error messages
- Consider using Result/Either pattern for error handling:

```dart
// Using a Result class or Either pattern
Future<void> handleLogin() async {
  final result = await userService.login(email, password);

  if (result.isSuccess) {
    navigateToHome(result.value);
  } else {
    showErrorDialog(result.error.message);
  }
}
```

## Documentation

- Document all public APIs with dartdoc comments
- Include examples for complex functions
- Document parameters, return values, and thrown exceptions
- Add TODO comments for future improvements with ticket numbers

```dart
/// Fetches user data from the remote API.
///
/// Returns a [User] object if successful, or throws a [NetworkException]
/// if the network request fails.
///
/// Example:
/// ```dart
/// final user = await fetchUser('user_id_123');
/// print(user.name);
/// ```
Future<User> fetchUser(String userId) async {
  // Implementation
}
```

## Testing

- Write unit tests for all business logic
- Use widget tests for UI components
- Use integration tests for critical user flows
- Follow the Arrange-Act-Assert pattern
- Use mocks for external dependencies (consider `mockito` or `mocktail`)
- Aim for high test coverage, especially for critical paths

## Common Pitfalls

### Avoid
- Deeply nested widget trees (extract widgets instead)
- Excessive use of global state
- Synchronous operations in the UI thread
- Memory leaks from unhandled stream subscriptions
- Overusing `BuildContext` across async gaps

### Prefer
- Composition over inheritance for widgets
- Lazy loading for expensive operations
- Proper disposal of controllers and streams
- Const constructors for immutable widgets
- Using `context.mounted` check in async callbacks (Flutter 3.7+)

## Performance Considerations

- Use `const` constructors for immutable widgets
- Implement `==` and `hashCode` for custom classes used in collections
- Avoid expensive operations during build
- Use `ListView.builder` for long lists
- Consider caching for expensive computations
- Use `compute` for CPU-intensive operations

---

This style guide is a living document and will evolve as our project and the Dart/Flutter ecosystem evolve.