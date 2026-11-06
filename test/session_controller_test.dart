import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flex_pilates_studio/controllers/session_controller.dart';
import 'booking_model_test.dart' show sessionRow;

void main() {
  test(
    'a slow previous date response cannot replace the latest selected day',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final client = SupabaseClient(
        'http://127.0.0.1:${server.port}',
        'test-public-client-key',
      );
      final controller = SessionController(client: client);
      final requests = <HttpRequest>[];
      final firstArrived = Completer<void>();
      final secondArrived = Completer<void>();
      final subscription = server.listen((request) {
        requests.add(request);
        if (requests.length == 1) firstArrived.complete();
        if (requests.length == 2) secondArrived.complete();
      });
      Future<void> respond(HttpRequest request, String title) async {
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode([
            {...sessionRow(), 'title': title},
          ]),
        );
        await request.response.close();
      }

      try {
        final first = controller.fetchSessionsByDate(DateTime(2030, 6, 12));
        await firstArrived.future;
        final second = controller.fetchSessionsByDate(DateTime(2030, 6, 13));
        await secondArrived.future;
        expect(
          requests[1].uri.queryParameters['select'],
          contains('coach:profiles!coach_id'),
        );
        await respond(requests[1], 'Latest day');
        await second;
        expect(controller.isLoading, isFalse);
        expect(controller.sessions.single.title, 'Latest day');
        await respond(requests[0], 'Old day');
        await first;
        expect(controller.sessions.single.title, 'Latest day');
        expect(controller.isLoading, isFalse);
      } finally {
        controller.dispose();
        await subscription.cancel();
        await server.close(force: true);
        await client.dispose();
      }
    },
  );
}
