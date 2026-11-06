import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flex_pilates_studio/app/theme.dart';
import 'package:flex_pilates_studio/controllers/auth_controller.dart';
import 'package:flex_pilates_studio/services/password_recovery_messages.dart';
import 'package:flex_pilates_studio/views/screens/auth/forgot_password_screen.dart';

class RecoveryAuth extends AuthController {
  RecoveryAuth(SupabaseClient client, this.respond) : super(client: client);
  final Future<void> Function() respond;
  bool busy = false;
  int calls = 0;
  @override
  bool get isLoading => busy;
  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    calls++;
    busy = true;
    notifyListeners();
    try {
      await respond();
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}

Future<void> pumpRecovery(WidgetTester tester, AuthController auth) =>
    tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: auth,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const ForgotPasswordScreen(),
        ),
      ),
    );

void main() {
  late SupabaseClient client;
  setUpAll(() {
    client = SupabaseClient(
      'https://example.invalid',
      'test-public-client-key',
    );
  });
  tearDownAll(() => client.dispose());
  testWidgets(
    'a delivery failure stays on the form without exposing diagnostics',
    (tester) async {
      final auth = RecoveryAuth(
        client,
        () async => throw AuthRetryableFetchException(
          message:
              '{"code":"unexpected_failure","message":"Error sending recovery email"}',
          statusCode: '500',
        ),
      );
      await pumpRecovery(tester, auth);
      await tester.enterText(find.byType(TextField), 'member@example.test');
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();
      expect(find.text(PasswordRecoveryMessages.sendFailed), findsOneWidget);
      expect(find.textContaining('AuthRetryableFetchException'), findsNothing);
      expect(find.textContaining('unexpected_failure'), findsNothing);
      expect(find.text('Check your inbox'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.errorText,
        isNull,
      );
      expect(auth.calls, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      auth.dispose();
    },
  );

  testWidgets('successful requests show an account-neutral inbox state', (
    tester,
  ) async {
    final auth = RecoveryAuth(client, () async {});
    await pumpRecovery(tester, auth);
    await tester.enterText(find.byType(TextField), 'member@example.test');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(find.text('Check your inbox'), findsOneWidget);
    expect(find.text(PasswordRecoveryMessages.checkInbox), findsOneWidget);
    expect(find.text('Send reset link'), findsNothing);
    await tester.tap(find.text('Use a different email'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    auth.dispose();
  });

  testWidgets('invalid email and repeated submits do not send extra requests', (
    tester,
  ) async {
    final complete = Completer<void>();
    final auth = RecoveryAuth(client, () => complete.future);
    await pumpRecovery(tester, auth);
    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.tap(find.text('Send reset link'));
    await tester.pump();
    expect(auth.calls, 0);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'member@example.test');
    await tester.tap(find.text('Send reset link'));
    await tester.tap(find.text('Send reset link'));
    await tester.pump();
    expect(auth.calls, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    complete.complete();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    auth.dispose();
  });
}
