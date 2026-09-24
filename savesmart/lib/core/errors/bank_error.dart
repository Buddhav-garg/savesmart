sealed class BankError implements Exception {
  const BankError(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkError extends BankError {
  const NetworkError() : super('Check your connection and try again.');
}

class ValidationError extends BankError {
  const ValidationError(this.code, super.message);
  final String code;
}

class UnauthenticatedError extends BankError {
  const UnauthenticatedError()
    : super('Your session has expired. Sign in again to continue.');
}

class ForbiddenError extends BankError {
  const ForbiddenError()
    : super('You do not have permission to perform this action.');
}

class NotFoundError extends BankError {
  const NotFoundError() : super('The requested information was not found.');
}

class ServerError extends BankError {
  const ServerError() : super('The bank service is unavailable. Try again.');
}

class UnknownError extends BankError {
  const UnknownError(super.message);
}
