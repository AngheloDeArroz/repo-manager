import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/groq_model.dart';
import 'rate_limiter.dart';
import 'secure_storage_service.dart';

/// Handles communication with the Groq chat-completions API.
class GroqService extends ChangeNotifier {
  GroqService({
    required this.storageService,
    required this.rateLimiter,
  });

  final SecureStorageService storageService;
  final RateLimiter rateLimiter;

  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _lastError;
  String? get lastError => _lastError;

  /// Send a prompt to Groq and return the assistant's reply.
  ///
  /// Returns `null` if the request was blocked by rate limits, the API key
  /// is missing, or the API returned an error.
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

    final apiKey = await storageService.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      _lastError = 'Groq API key not set.';
      notifyListeners();
      return null;
    }

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
