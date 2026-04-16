import 'dart:convert';
import '../models/groq_model.dart';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/exceptions.dart';
import 'api_key_manager.dart';
import 'rate_limiter.dart';

/// Handles communication with the Groq chat-completions API.
class GroqService extends ChangeNotifier {
  GroqService({
    required this.apiKeyManager,
    required this.rateLimiter,
  });

  final ApiKeyManager apiKeyManager;
  final RateLimiter rateLimiter;

  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _lastError;
  String? get lastError => _lastError;

  /// Send a prompt to Groq and return the assistant's reply.
  ///
  /// Returns `null` if the request was blocked by rate limits or the API returned an error.
  /// Throws [NoApiKeyException] if no active API key is found.
  Future<String?> sendPrompt({
    required GroqModel model,
    required String systemPrompt,
    required String userContent,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    // --- Pre-flight checks ---------------------------------------------------
    if (!rateLimiter.canMakeRequest(model)) {
      _lastError = 'Rate limit reached for ${model.label}. Please wait.';
      notifyListeners();
      return null;
    }

    final activeKey = apiKeyManager.getActiveKey();
    if (activeKey == null || activeKey.value.isEmpty) {
      throw NoApiKeyException();
    }
    final apiKey = activeKey.value;

    // --- Request -------------------------------------------------------------
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model.modelId,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userContent},
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        _lastError =
            'Groq API error ${response.statusCode}: ${body['error']?['message'] ?? response.reasonPhrase}';
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      // --- Record usage ------------------------------------------------------
      final usage = body['usage'] as Map<String, dynamic>?;
      final totalTokens = (usage?['total_tokens'] as int?) ?? 0;
      rateLimiter.recordRequest(model, totalTokens);

      // --- Extract reply -----------------------------------------------------
      final choices = body['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        _lastError = 'No response from model.';
        return null;
      }

      return (choices[0]['message']['content'] as String?)?.trim();
    } catch (e) {
      _lastError = 'Network error: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
