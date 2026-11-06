import 'package:flutter/foundation.dart';

/// A late network response may finish after a user has signed out. Its old
/// provider must not notify a disposed widget tree or affect the new account.
abstract class AppNotifier extends ChangeNotifier {
  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
