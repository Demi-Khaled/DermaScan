import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'ai_service.dart';
import '../core/constants.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final _storage = const FlutterSecureStorage();

  final Map<int, List<Map<String, dynamic>>> _histories = {};
  final Map<int, List<ChatMessage>> _messages = {};
  final Map<int, String> _systemInstructions = {};

  List<ChatMessage> getMessages(AnalysisResult result) {
    final id = result.analyzedAt.millisecondsSinceEpoch;
    if (!_messages.containsKey(id)) {
      _messages[id] = [
        ChatMessage(
          text: 'Hi! I am your AI DermaScan Assistant. I have analyzed your lesion image and found a ${result.riskLevel.label.toLowerCase()} risk of ${result.conditionName?.replaceAll('_', ' ') ?? 'a skin condition'}. Do you have any questions about this result?',
          isUser: false,
        )
      ];
      _histories[id] = [];
    }
    return _messages[id]!;
  }

  void _ensureSession(AnalysisResult context) {
    final id = context.analyzedAt.millisecondsSinceEpoch;
    if (_systemInstructions.containsKey(id)) return;

    _systemInstructions[id] = '''
ROLE: You are DermaScan AI, a specialized skin health assistant inside the DermaScan app.

ALLOWED TOPICS — you may ONLY discuss:
- The user's current scan result shown below
- Skin diseases, skin lesions, and dermatology in general
- Skincare advice, sun protection, and skin hygiene
- When and why to see a dermatologist

OFF-TOPIC REFUSAL RULE:
If the user asks about ANYTHING unrelated to skin health (e.g., cooking, sports, general medicine, technology, relationships, or any other subject), you MUST politely refuse and redirect them. Example: "I'm only able to help with skin health and your scan results. For other topics, please use a general assistant. Is there anything about your skin condition I can help with? 😊"

IMPORTANT DISCLAIMERS:
- Always remind the user you are an AI, not a licensed doctor.
- Never provide a definitive diagnosis or prescribe medication.
- Always recommend professional consultation for serious concerns.

USER'S CURRENT SCAN CONTEXT:
- Condition Detected: ${context.conditionName?.replaceAll('_', ' ') ?? 'Unknown'}
- Risk Level: ${context.riskLevel.label}
- AI Confidence: ${(context.confidence * 100).round()}%
- App Recommendation: ${context.recommendation}
- Explanation: ${context.explanation}

Use this scan context to give personalized, relevant answers to the user's skin-related questions.
''';
  }

  Future<ChatMessage> sendMessage(String message, AnalysisResult context) async {
    final id = context.analyzedAt.millisecondsSinceEpoch;
    _ensureSession(context);

    _histories[id]!.add({
      'role': 'user',
      'parts': [{'text': message}],
    });

    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Not authenticated. Please log in again.');
      }

      final url = Uri.parse('${AppConstants.apiBaseUrl}/chat');
      
      final body = <String, dynamic>{
        'message': message,
        'history': _histories[id],
        'systemInstruction': _systemInstructions[id],
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = data['text'] as String? ?? 'I could not generate a response.';

        _histories[id]!.add({
          'role': 'model',
          'parts': [{'text': text}],
        });

        return ChatMessage(text: text, isUser: false);
      } else if (response.statusCode == 401) {
        _histories[id]!.removeLast();
        return ChatMessage(
          text: 'Your session has expired. Please log out and log back in to use the AI chat.',
          isUser: false,
        );
      }

      debugPrint('Backend API error: ${response.statusCode} — ${response.body}');
      _histories[id]!.removeLast();

      return ChatMessage(
        text: 'Sorry, the AI service returned an unexpected response (${response.statusCode}). Please try again.',
        isUser: false,
      );
    } catch (e) {
      debugPrint('Error communicating with backend API: $e');

      if (_histories[id]!.isNotEmpty) _histories[id]!.removeLast();

      return ChatMessage(
        text: 'Sorry, I encountered a network error. Please check your connection and try again.',
        isUser: false,
      );
    }
  }

  void resetChat(AnalysisResult result) {
    final id = result.analyzedAt.millisecondsSinceEpoch;
    _histories.remove(id);
    _messages.remove(id);
    _systemInstructions.remove(id);
  }
}
