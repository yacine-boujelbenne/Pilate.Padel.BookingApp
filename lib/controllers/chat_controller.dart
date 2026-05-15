import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class Message {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  Message({required this.content, required this.isUser, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class ChatController extends ChangeNotifier {
  final List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;

  final String _systemPrompt =
      '''You are a friendly fitness assistant for a Pilates and Padel sports studio called "Fléx Pilates Studio". 

Your role is to:
1. Recommend suitable activities (Pilates classes, Padel sessions) based on the user's preferences, fitness level, and goals
2. Help create personalized training schedules
3. Answer questions about Pilates and Padel sports
4. Provide fitness tips and advice

Be conversational, helpful, and concise. Ask clarifying questions when needed to give better recommendations.

Keep responses under 3-4 sentences unless the user asks for detailed information.''';

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(Message(content: text, isUser: true));
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _callLLM(text);
      _messages.add(Message(content: response, isUser: false));
    } catch (e) {
      _error = e.toString();
      final display = _error != null && _error!.isNotEmpty
          ? 'Sorry, I encountered an error: ${_error!}'
          : 'Sorry, I encountered an error. Please try again.';
      _messages.add(Message(
        content: display,
        isUser: false,
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> _callLLM(String userMessage) async {
    final client = SupabaseService.instance.client;

    final response = await client.functions.invoke(
      'chat-completion',
      body: {
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          ..._messages.map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              }),
          {'role': 'user', 'content': userMessage},
        ],
        'max_tokens': 500,
        'temperature': 0.7,
      },
    );

    final dynamic data = response.data;
    if (data == null) {
      throw Exception('No response from AI');
    }

    if (data is Map && data['error'] != null) {
      throw Exception('AI error: ${data['error']}');
    }

    try {
      // groq/openai style response: { choices: [ { message: { content: '...' } } ] }
      if (data is Map &&
          data['choices'] is List &&
          data['choices'].isNotEmpty) {
        final choice = data['choices'][0];
        if (choice is Map) {
          final message = choice['message'] ?? choice;
          if (message is Map && message['content'] is String) {
            return message['content'] as String;
          }
          if (choice['text'] is String) {
            return choice['text'] as String;
          }
        }
      }
      // Fallback: try to stringify body
      return data.toString();
    } catch (e) {
      throw Exception('Unexpected AI response shape: $e');
    }
  }

  void clearChat() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }
}
