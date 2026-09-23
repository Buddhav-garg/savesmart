sealed class BankError implements Exception {
  const BankError(this.message);
  final String message;
}

class NetworkError extends BankError {
  const NetworkError() : super('Check your connection and try again.');
}

class ValidationError extends BankError {
  const ValidationError(this.code, super.message);
  final String code;
}

class UnauthenticatedError extends BankError {
  const UnauthenticatedError() : super('Sign in again.');
}

class UnknownError extends BankError {
  const UnknownError(super.message);
}
