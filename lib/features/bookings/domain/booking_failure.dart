import 'package:supabase_flutter/supabase_flutter.dart';

String bookingFailureMessage(Object error) {
  if (error is PostgrestException) {
    switch (error.message) {
      case 'SESSION_FULL':
        return 'This session just filled up. You can join the waitlist.';
      case 'SESSION_UNAVAILABLE':
        return 'This session is no longer available. Choose another time.';
      case 'ACCOUNT_UNAVAILABLE':
        return 'Your account cannot make a reservation. Contact the studio.';
      case 'PAYMENT_UNAVAILABLE':
        return 'Online payments are not available yet. Pay at the studio.';
      case 'BOOKING_NOT_FOUND':
        return 'This reservation could not be found. Refresh your bookings.';
      case 'SESSION_STARTED':
        return 'This session has already started. Contact the studio to cancel.';
    }
    if (error.code == '23505') {
      return 'You already have a reservation for this session.';
    }
  }
  return 'We could not confirm your reservation. Check your connection and try again.';
}
