// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fléx Pilates Studio';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get emailUpdates => 'Email updates';

  @override
  String get smsAlerts => 'SMS alerts';

  @override
  String get account => 'Account';

  @override
  String get manageAccount => 'Manage account';

  @override
  String get signOut => 'Sign out';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get bookingCancelled => 'Booking cancelled';

  @override
  String get couldNotCancelBooking =>
      'Could not cancel booking. Please try again.';

  @override
  String get alreadyOnWaitlist => 'You are already on this waitlist';

  @override
  String get addedToWaitlist => 'Added to waitlist';

  @override
  String get couldNotJoinWaitlist => 'Could not join waitlist';

  @override
  String get spotAvailable => 'Spot available';

  @override
  String get spotOpenedForWaitlist =>
      'A spot opened for your waitlisted session. Book now.';
}
