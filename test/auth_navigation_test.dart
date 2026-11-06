import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flex_pilates_studio/app/router.dart';
import 'package:flex_pilates_studio/app/theme.dart';
import 'package:flex_pilates_studio/controllers/auth_controller.dart';
import 'support/preview_controllers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, dynamic>{} : true,
        );
    await Supabase.initialize(
      url: 'https://example.invalid',
      anonKey: 'test-public-client-key',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
      debug: false,
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  testWidgets(
    'account creation and recovery screens have working Log in links',
    (tester) async {
      final auth = PreviewSignedOut();
      final router = AppRouter(auth).router;
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthController>.value(
          value: auth,
          child: MaterialApp.router(
            theme: buildAppTheme(),
            routerConfig: router,
          ),
        ),
      );
      for (final path in ['/register', '/forgot-password', '/reset-password']) {
        router.go(path);
        await tester.pumpAndSettle();
        final link = find.text('Log in');
        expect(link, findsOneWidget);
        await tester.ensureVisible(link);
        await tester.tap(link);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/login');
      }
      router.go('/register');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/login');
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      auth.dispose();
    },
  );
}
