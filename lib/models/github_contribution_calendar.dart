class GitHubContributionDay {
  const GitHubContributionDay({
    required this.date,
    required this.weekday,
    required this.contributionCount,
    required this.contributionLevel,
  });

  final DateTime date;
  final int weekday;
  final int contributionCount;
  final String contributionLevel;

  bool get hasContributions => contributionCount > 0;

  factory GitHubContributionDay.fromJson(Map<String, dynamic> json) {
    return GitHubContributionDay(
      date:
          DateTime.tryParse(json['date'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      weekday: (json['weekday'] as num?)?.toInt() ?? 0,
      contributionCount: (json['contributionCount'] as num?)?.toInt() ?? 0,
      contributionLevel: json['contributionLevel'] as String? ?? 'NONE',
    );
  }
}

class GitHubContributionCalendar {
  const GitHubContributionCalendar({
    required this.totalContributions,
    required this.weeks,
  });

  final int totalContributions;
  final List<List<GitHubContributionDay>> weeks;

  List<GitHubContributionDay> get days =>
      weeks.expand((week) => week).toList(growable: false);

  int get activeDays => days.where((day) => day.hasContributions).length;

  int get activeWeeks =>
      weeks.where((week) => week.any((day) => day.hasContributions)).length;

  factory GitHubContributionCalendar.fromJson(Map<String, dynamic> json) {
    final rawWeeks = json['weeks'] as List<dynamic>? ?? const [];
    final weeks = rawWeeks
        .map(
          (week) =>
              ((week as Map<String, dynamic>)['contributionDays']
                          as List<dynamic>? ??
                      const [])
                  .map(
                    (day) => GitHubContributionDay.fromJson(
                      day as Map<String, dynamic>,
                    ),
                  )
                  .toList(growable: false),
        )
        .toList(growable: false);

    return GitHubContributionCalendar(
      totalContributions: (json['totalContributions'] as num?)?.toInt() ?? 0,
      weeks: weeks,
    );
  }
}
