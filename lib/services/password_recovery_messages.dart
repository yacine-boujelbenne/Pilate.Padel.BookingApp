import 'package:supabase_flutter/supabase_flutter.dart';

/// Recovery screens never display provider responses or reveal account existence.
class PasswordRecoveryMessages {
  static const sendFailed =
      'We couldn’t send a reset link. Please try again later or contact the club.';
  static const checkInbox =
      'If an account uses this email, you’ll receive a reset link. Check your inbox and spam folder.';

  static String sendFailure(Object error) {
    final common = _commonFailure(error);
    if (common != null) return common;
    if (error is AuthException &&
        {'email_address_invalid', 'validation_failed'}.contains(error.code)) {
      return 'Please check your email address and try again.';
    }
    return sendFailed;
  }

  static String updateFailure(Object error) {
    final common = _commonFailure(error);
    if (common != null) return common;
    if (error is AuthSessionMissingException ||
        error is AuthException &&
            {
              'otp_expired',
              'session_expired',
              'session_not_found',
              'refresh_token_not_found',
              'bad_jwt',
              'invalid_jwt',
            }.contains(error.code)) {
      return 'This reset link is invalid or has expired. Please request a new link.';
    }
    if (error is AuthException && error.code == 'same_password') {
      return 'Choose a password you haven’t used before.';
    }
    if (error is AuthException && error.code == 'weak_password') {
      return 'Choose a stronger password with a mix of letters, numbers, and symbols.';
    }
    return 'We couldn’t update your password. Please try again or request a new reset link.';
  }

  static String? _commonFailure(Object error) {
    if (error is! AuthException) return null;
    final status = int.tryParse(error.statusCode ?? '');
    if (status == 429 ||
        {
          'over_email_send_rate_limit',
          'over_request_rate_limit',
        }.contains(error.code)) {
      return 'Too many requests. Please wait a while before trying again.';
    }
    // Supabase also wraps mailer HTTP 500 responses in this retryable type.
    // A server delivery failure must not be described as a connectivity problem.
    if (status != null && status >= 500) return null;
    if (error is AuthRetryableFetchException) {
      return 'Couldn’t connect. Check your internet connection and try again.';
    }
    return null;
  }
}
