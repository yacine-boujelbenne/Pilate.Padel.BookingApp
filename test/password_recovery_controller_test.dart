import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flex_pilates_studio/controllers/auth_controller.dart';
import 'package:flex_pilates_studio/services/password_recovery_messages.dart';

class MemoryPkceStorage extends GotrueAsyncStorage {
  final values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}

void main() {
  for (final status in [500, 429, 200]) {
    test(
      'recovery HTTP $status keeps the API contract and safe error state',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final client = SupabaseClient(
          'http://127.0.0.1:${server.port}',
          'test-public-client-key',
          authOptions: AuthClientOptions(pkceAsyncStorage: MemoryPkceStorage()),
        );
        final auth = AuthController(client: client);
        final requests = <Map<String, dynamic>>[];
        final subscription = server.listen((request) async {
          expect(request.uri.path, '/auth/v1/recover');
          requests.add(
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>,
          );
          request.response.statusCode = status;
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode(
              status == 200
                  ? {}
                  : {
                      'code': status == 429
                          ? 'over_email_send_rate_limit'
                          : 'unexpected_failure',
                      'message':
                          'Error sending recovery email: private SMTP diagnostic',
                    },
            ),
          );
          await request.response.close();
        });
        try {
          final operation = auth.sendPasswordResetEmail(
            email: 'member@example.test',
          );
          if (status == 200) {
            await operation;
            expect(auth.error, isNull);
          } else {
            await expectLater(operation, throwsA(isA<AuthException>()));
            expect(auth.error, isNot(contains('private SMTP')));
            expect(auth.error, isNot(contains('AuthRetryableFetchException')));
            expect(
              auth.error,
              status == 500
                  ? PasswordRecoveryMessages.sendFailed
                  : contains('Too many requests'),
            );
          }
          expect(requests.single['email'], 'member@example.test');
          expect(requests.single['code_challenge'], isNotEmpty);
          expect(auth.isLoading, isFalse);
        } finally {
          auth.dispose();
          await client.dispose();
          await subscription.cancel();
          await server.close(force: true);
        }
      },
    );
  }
}
