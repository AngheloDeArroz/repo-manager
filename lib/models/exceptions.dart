class NoApiKeyException implements Exception {
  final String message;
  NoApiKeyException([this.message = 'No API key provided.']);
  
  @override
  String toString() => message;
}
