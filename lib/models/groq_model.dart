/// Available Groq LLM models with their rate-limit profiles.
///
/// Safe limits are set at 90 % of the free-tier ceiling to avoid 429 errors.
enum GroqModel {
  fast(
    label: 'Fast',
    modelId: 'llama-3.1-8b-instant',
    description: 'Everyday tasks',
    safeRpm: 27,
    safeRpd: 12960,
    safeTpm: 5400,
    safeTpd: 450000,
  ),
  smart(
    label: 'Smart',
    modelId: 'llama-3.3-70b-versatile',
    description: 'Complex reasoning, lower daily quota',
    safeRpm: 27,
    safeRpd: 900,
    safeTpm: 10800,
    safeTpd: 90000,
  ),
  balanced(
    label: 'Balanced',
    modelId: 'meta-llama/llama-4-scout-17b-16e-instruct',
    description: 'Large context, high throughput',
    safeRpm: 27,
    safeRpd: 900,
    safeTpm: 27000,
    safeTpd: 450000,
  );

  const GroqModel({
    required this.label,
    required this.modelId,
    required this.description,
    required this.safeRpm,
    required this.safeRpd,
    required this.safeTpm,
    required this.safeTpd,
  });

  final String label;
  final String modelId;
  final String description;
  final int safeRpm;
  final int safeRpd;
  final int safeTpm;
  final int safeTpd;

  /// Look up a model by its persisted name. Falls back to [fast].
  static GroqModel fromName(String? name) {
    return GroqModel.values.firstWhere(
      (m) => m.name == name,
      orElse: () => GroqModel.fast,
    );
  }
}
