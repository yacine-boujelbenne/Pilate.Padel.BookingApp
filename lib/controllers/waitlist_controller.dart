import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/waitlist_entry.dart';
import '../services/supabase_service.dart';

class WaitlistController extends ChangeNotifier {
  final _client = SupabaseService.instance.client;

  List<WaitlistEntry> _entries = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;

  List<WaitlistEntry> get entries => _entries;
  bool get isLoading => _loading;
  String? get error => _error;

  void subscribeRealtime() {
    _channel ??= _client.channel('sessions-live')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'sessions',
        callback: (_) => fetchMemberWaitlists(),
      )
      ..subscribe();
  }

  Future<void> joinWaitlist(
      {required String sessionId, required String notifyChannel}) async {
    _setLoading(true);
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        throw Exception('Not authenticated');
      }
      final position = await getPosition(sessionId);
      await _client.from('waitlists').insert({
        'member_id': uid,
        'session_id': sessionId,
        'notify_channel': notifyChannel,
        'position': position,
      });
      _error = null;
      await fetchMemberWaitlists();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> leaveWaitlist(String entryId) async {
    _setLoading(true);
    try {
      await _client.from('waitlists').delete().eq('id', entryId);
      _error = null;
      await fetchMemberWaitlists();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> fetchMemberWaitlists() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      _entries = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      final res = await _client
          .from('waitlists')
          .select()
          .eq('member_id', uid)
          .order('created_at');
      _entries = (res as List)
          .map((e) => WaitlistEntry.fromMap(e as Map<String, dynamic>))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<int> getPosition(String sessionId) async {
    final res = await _client
        .from('waitlists')
        .select('id')
        .eq('session_id', sessionId);
    return (res as List).length + 1;
  }

  Future<void> notifyNextInLine(String sessionId) async {
    await _client.functions
        .invoke('notify-waitlist', body: {'session_id': sessionId});
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
