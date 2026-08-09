enum AppFailureCode {
  backendNotConfigured,

  /// No session, or the session expired. Distinct from
  /// [invalidCredentials]: nothing the user typed was wrong, they are simply
  /// not signed in for an action that requires it.
  notAuthenticated,
  invalidCredentials,
  emailNotConfirmed,
  emailAlreadyRegistered,
  weakPassword,
  network,
  unknown,
}

class AppException implements Exception {
  const AppException(this.code, {this.cause});

  final AppFailureCode code;
  final Object? cause;

  @override
  String toString() => 'AppException(code: $code, cause: $cause)';
}
