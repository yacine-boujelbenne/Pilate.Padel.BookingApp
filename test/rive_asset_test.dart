import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import 'package:flex_pilates_studio/views/widgets/confirmation_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('bundled Marketplace confirmation has a playable timeline', () async {
    await rive.RiveNative.init();
    final file = await rive.File.asset(
      'assets/animations/success_check.riv',
      riveFactory: rive.Factory.flutter,
    );
    expect(file, isNotNull);
    final board = file!.defaultArtboard();
    expect(board, isNotNull);
    expect(board!.animationCount(), greaterThan(0));
    final animation = board.animationAt(0);
    expect(animation.duration, greaterThan(0));
    expect(animation.name, isNotEmpty);
    animation.dispose();
    board.dispose();
    file.dispose();
  });
  testWidgets(
    'confirmation renders the bundled Rive animation with motion enabled',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ConfirmationMotion())),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.byType(rive.RiveArtboardWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
