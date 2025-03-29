// This file conditionally exports the appropriate implementation
// based on the platform (web or non-web)

export 'web_utilities.dart' if (dart.library.io) 'web_utilities_stub.dart';
