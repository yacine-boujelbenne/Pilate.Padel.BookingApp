// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Fléx Pilates Studio';

  @override
  String get settings => 'Paramètres';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushNotifications => 'Notifications push';

  @override
  String get emailUpdates => 'Mises à jour par e-mail';

  @override
  String get smsAlerts => 'Alertes SMS';

  @override
  String get account => 'Compte';

  @override
  String get manageAccount => 'Gérer le compte';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get language => 'Langue';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get bookingCancelled => 'Réservation annulée';

  @override
  String get couldNotCancelBooking =>
      'Impossible d\'annuler la réservation. Veuillez réessayer.';

  @override
  String get alreadyOnWaitlist => 'Vous êtes déjà sur cette liste d\'attente';

  @override
  String get addedToWaitlist => 'Ajouté à la liste d\'attente';

  @override
  String get couldNotJoinWaitlist =>
      'Impossible de rejoindre la liste d\'attente';

  @override
  String get spotAvailable => 'Place disponible';

  @override
  String get spotOpenedForWaitlist =>
      'Une place s\'est ouverte pour votre session en liste d\'attente. Réservez maintenant.';
}
