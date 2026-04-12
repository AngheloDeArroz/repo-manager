/// A point-in-time snapshot of API usage against a model's safe limits.
class UsageSnapshot {
  const UsageSnapshot({
    required this.requestsThisMinute,
    required this.requestsToday,
    required this.tokensThisMinute,
    required this.tokensToday,
  });

  final int requestsThisMinute;
  final int requestsToday;
  final int tokensThisMinute;
  final int tokensToday;

  /// Returns usage as a 0.0–1.0+ ratio against [limit].
  double percentOf(int limit) => limit == 0 ? 0 : _raw(limit);

  double _raw(int limit) => 0; // placeholder; real logic is per-dimension

  // — Per-dimension helpers ——————————————————————————————

  double rpmPercent(int safeRpm) =>
      safeRpm == 0 ? 0 : requestsThisMinute / safeRpm;

  double rpdPercent(int safeRpd) =>
      safeRpd == 0 ? 0 : requestsToday / safeRpd;

  double tpmPercent(int safeTpm) =>
      safeTpm == 0 ? 0 : tokensThisMinute / safeTpm;

  double tpdPercent(int safeTpd) =>
      safeTpd == 0 ? 0 : tokensToday / safeTpd;

  /// The highest utilisation across all four dimensions (0.0–1.0+).
  double maxPercent({
    required int safeRpm,
    required int safeRpd,
    required int safeTpm,
    required int safeTpd,
  }) {
    final values = [
      rpmPercent(safeRpm),
      rpdPercent(safeRpd),
      tpmPercent(safeTpm),
      tpdPercent(safeTpd),
    ];
    return values.reduce((a, b) => a > b ? a : b);
  }

  /// True when any dimension is ≥ 80 % of its safe limit.
  bool isWarning({
    required int safeRpm,
    required int safeRpd,
    required int safeTpm,
    required int safeTpd,
  }) =>
      maxPercent(
        safeRpm: safeRpm,
        safeRpd: safeRpd,
        safeTpm: safeTpm,
        safeTpd: safeTpd,
      ) >=
      0.8;

  /// True when any dimension is ≥ 90 % — requests should be paused.
  bool isPaused({
    required int safeRpm,
    required int safeRpd,
    required int safeTpm,
    required int safeTpd,
  }) =>
      maxPercent(
        safeRpm: safeRpm,
        safeRpd: safeRpd,
        safeTpm: safeTpm,
        safeTpd: safeTpd,
      ) >=
      0.9;

  static const empty = UsageSnapshot(
    requestsThisMinute: 0,
    requestsToday: 0,
    tokensThisMinute: 0,
    tokensToday: 0,
  );
}
