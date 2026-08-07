enum AppFailureCode {
  backendNotConfigured,
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
