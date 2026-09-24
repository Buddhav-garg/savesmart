import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/state/session_provider.dart';
import 'bank_error.dart';

Future<void> presentBankError(BuildContext context, Object error) async {
  final bankError = error is BankError
      ? error
      : UnknownError(_messageFor(error));
  final isUnauthenticated = bankError is UnauthenticatedError;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(_titleFor(bankError)),
      content: Text(bankError.message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(isUnauthenticated ? 'Sign in' : 'OK'),
        ),
      ],
    ),
  );

  if (isUnauthenticated) {
    AppSession.instance.logout();
    if (context.mounted) context.go('/login');
  }
}

String _titleFor(BankError error) => switch (error) {
  NetworkError() => 'Connection problem',
  UnauthenticatedError() => 'Sign in required',
  ForbiddenError() => 'Access denied',
  NotFoundError() => 'Not found',
  ValidationError() => 'Check your information',
  ServerError() => 'Service unavailable',
  UnknownError() => 'Something went wrong',
};

String _messageFor(Object error) {
  final message = error.toString().replaceFirst(RegExp(r'^Exception: ?'), '');
  return message.isEmpty ? 'Something went wrong. Try again.' : message;
}
