import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/groq_model.dart';
import '../models/usage_snapshot.dart';

/// Tracks API usage per model and enforces safe rate limits.
///
/// • Sliding-window RPM (requests per minute) via timestamp list.
/// • Daily counters (RPD / TPD) reset at midnight UTC.
/// • Warning at ≥ 80 %, auto-pause at ≥ 90 %.
class RateLimiter extends ChangeNotifier {
  RateLimiter();

  // Sliding-window timestamps keyed by model name.
  final Map<String, List<DateTime>> _requestTimestamps = {};

  // Daily counters keyed by "<model>_<yyyy-MM-dd>".
  final Map<String, int> _dailyRequests = {};
  final Map<String, int> _dailyTokens = {};

  // Per-minute token counter (sliding window, simplified as sum of last 60 s).
  final Map<String, List<_TokenEntry>> _tokenTimestamps = {};

  SharedPreferences? _prefs;

  /// Call once at app startup.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _restoreDailyCounts();
  }

  // — Public API ————————————————————————————————————————

  /// Whether a request is allowed right now for [model].
  bool canMakeRequest(GroqModel model) {
    _pruneOldEntries(model);
    final snap = usage(model);
    return !snap.isPaused(
      safeRpm: model.safeRpm,
      safeRpd: model.safeRpd,
      safeTpm: model.safeTpm,
      safeTpd: model.safeTpd,
    );
  }

  /// Record a completed request for [model] that consumed [tokenCount] tokens.
  void recordRequest(GroqModel model, int tokenCount) {
    final now = DateTime.now().toUtc();

    // RPM
    _requestTimestamps.putIfAbsent(model.name, () => []).add(now);

    // TPM
    _tokenTimestamps
        .putIfAbsent(model.name, () => [])
        .add(_TokenEntry(now, tokenCount));

    // Daily
    final dayKey = _dayKey(model, now);
    _dailyRequests[dayKey] = (_dailyRequests[dayKey] ?? 0) + 1;
    _dailyTokens[dayKey] = (_dailyTokens[dayKey] ?? 0) + tokenCount;

    _persistDailyCounts(model, now);
    notifyListeners();
  }

  /// Current usage snapshot for [model].
  UsageSnapshot usage(GroqModel model) {
    _pruneOldEntries(model);
    final now = DateTime.now().toUtc();
    final dayKey = _dayKey(model, now);

    return UsageSnapshot(
      requestsThisMinute: _requestTimestamps[model.name]?.length ?? 0,
      requestsToday: _dailyRequests[dayKey] ?? 0,
      tokensThisMinute: _tokenTimestamps[model.name]
              ?.fold<int>(0, (sum, e) => sum + e.tokens) ??
          0,
      tokensToday: _dailyTokens[dayKey] ?? 0,
    );
  }

  /// Reset all daily counters (manual user action).
  void resetDaily() {
    _dailyRequests.clear();
    _dailyTokens.clear();
    notifyListeners();
  }

  // — Internal ——————————————————————————————————————————

  void _pruneOldEntries(GroqModel model) {
    final cutoff = DateTime.now().toUtc().subtract(const Duration(seconds: 60));

    _requestTimestamps[model.name]?.removeWhere((t) => t.isBefore(cutoff));
    _tokenTimestamps[model.name]?.removeWhere((e) => e.time.isBefore(cutoff));
  }

  String _dayKey(GroqModel model, DateTime now) {
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return '${model.name}_$date';
  }

  // — Persistence ———————————————————————————————————————

  void _persistDailyCounts(GroqModel model, DateTime now) {
    final dayKey = _dayKey(model, now);
    _prefs?.setInt('groq_rpd_$dayKey', _dailyRequests[dayKey] ?? 0);
    _prefs?.setInt('groq_tpd_$dayKey', _dailyTokens[dayKey] ?? 0);
  }

  void _restoreDailyCounts() {
    final now = DateTime.now().toUtc();
    for (final model in GroqModel.values) {
      final dayKey = _dayKey(model, now);
      _dailyRequests[dayKey] = _prefs?.getInt('groq_rpd_$dayKey') ?? 0;
      _dailyTokens[dayKey] = _prefs?.getInt('groq_tpd_$dayKey') ?? 0;
    }
  }
}

class _TokenEntry {
  _TokenEntry(this.time, this.tokens);
  final DateTime time;
  final int tokens;
}
