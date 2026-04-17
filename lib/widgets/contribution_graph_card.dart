import 'package:flutter/material.dart';

import '../models/github_contribution_calendar.dart';

const double _calendarCellSize = 12;
const double _calendarDayGap = 4;
const double _calendarWeekGap = 4;
const double _calendarWeekdayLabelWidth = 13;
const double _calendarWeekdayLabelGap = 7;
const double _calendarMonthLabelHeight = 14;
const double _calendarMonthLabelSlotWidth = _calendarCellSize;
const double _calendarMonthLabelWidth = 24;
const List<String> _calendarMonthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class ContributionGraphCard extends StatelessWidget {
  const ContributionGraphCard({
    super.key,
    required this.future,
    required this.onRetry,
  });

  final Future<GitHubContributionCalendar?> future;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GitHubContributionCalendar?>(
      future: future,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final calendar = snapshot.data;

        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF0F141B),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF30363D)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.16),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: isLoading
                ? const _LoadingState(key: ValueKey('loading'))
                : calendar == null
                ? _ErrorState(key: const ValueKey('error'), onRetry: onRetry)
                : _LoadedState(
                    key: const ValueKey('loaded'),
                    calendar: calendar,
                  ),
          ),
        );
      },
    );
  }
}

class _LoadedState extends StatelessWidget {
  const _LoadedState({required this.calendar, super.key});

  final GitHubContributionCalendar calendar;

  @override
  Widget build(BuildContext context) {
    final displayWeeks = calendar.weeks.toList(growable: false);
    final monthLabels = _buildMonthLabels(displayWeeks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: const Text(
                'Contribution calendar',
                style: TextStyle(
                  color: Color(0xFFE6EDF3),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${calendar.totalContributions} contributions',
              style: const TextStyle(
                color: Color(0xFF39D353),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (displayWeeks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'No contribution data yet.',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 10),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(
                      width:
                          _calendarWeekdayLabelWidth + _calendarWeekdayLabelGap,
                    ),
                    for (var index = 0; index < displayWeeks.length; index++)
                      Padding(
                        padding: EdgeInsets.only(
                          right: index == displayWeeks.length - 1
                              ? 0
                              : _calendarWeekGap,
                        ),
                        child: SizedBox(
                          width: _calendarMonthLabelSlotWidth,
                          height: _calendarMonthLabelHeight,
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: monthLabels[index] == null
                                ? const SizedBox.shrink()
                                : OverflowBox(
                                    alignment: Alignment.bottomLeft,
                                    minWidth: 0,
                                    maxWidth: _calendarMonthLabelWidth,
                                    child: Text(
                                      monthLabels[index]!,
                                      style: const TextStyle(
                                        color: Color(0xFF8B949E),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _WeekdayLabels(),
                    const SizedBox(width: _calendarWeekdayLabelGap),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (
                          var index = 0;
                          index < displayWeeks.length;
                          index++
                        )
                          Padding(
                            padding: EdgeInsets.only(
                              right: index == displayWeeks.length - 1
                                  ? 0
                                  : _calendarWeekGap,
                            ),
                            child: _WeekColumn(days: displayWeeks[index]),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 170,
      child: Center(child: CircularProgressIndicator(color: Color(0xFF39D353))),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.area_chart_rounded,
              color: Color(0xFF8B949E),
              size: 24,
            ),
            const SizedBox(height: 10),
            const Text(
              'Unable to load contribution activity.',
              style: TextStyle(
                color: Color(0xFFE6EDF3),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Check the GitHub session or try again.',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 10),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF39D353),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels();

  @override
  Widget build(BuildContext context) {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return SizedBox(
      width: _calendarWeekdayLabelWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < labels.length; index++)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == labels.length - 1 ? 0 : _calendarDayGap,
              ),
              child: SizedBox(
                width: _calendarWeekdayLabelWidth,
                height: _calendarCellSize,
                child: Center(
                  child: Text(
                    labels[index],
                    style: const TextStyle(
                      color: Color(0xFF6E7681),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekColumn extends StatelessWidget {
  const _WeekColumn({required this.days});

  final List<GitHubContributionDay> days;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < days.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == days.length - 1 ? 0 : _calendarDayGap,
            ),
            child: _ContributionSquare(day: days[index]),
          ),
      ],
    );
  }
}

class _ContributionSquare extends StatelessWidget {
  const _ContributionSquare({required this.day});

  final GitHubContributionDay day;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _calendarCellSize,
      height: _calendarCellSize,
      decoration: BoxDecoration(
        color: _colorForLevel(day.contributionLevel, day.contributionCount),
        borderRadius: BorderRadius.circular(2.5),
        border: Border.all(
          color: const Color(0xFFFFFFFF).withValues(alpha: 0.06),
          width: 0.7,
        ),
      ),
    );
  }

  Color _colorForLevel(String level, int contributionCount) {
    switch (level) {
      case 'FIRST_QUARTILE':
        return const Color(0xFF0E4429);
      case 'SECOND_QUARTILE':
        return const Color(0xFF006D32);
      case 'THIRD_QUARTILE':
        return const Color(0xFF26A641);
      case 'FOURTH_QUARTILE':
        return const Color(0xFF39D353);
      default:
        return contributionCount == 0
            ? const Color(0xFF262C36)
            : const Color(0xFF0E4429);
    }
  }
}

List<String?> _buildMonthLabels(List<List<GitHubContributionDay>> weeks) {
  final labels = <String?>[];
  String? previousLabel;

  for (final week in weeks) {
    final currentLabel = _monthLabelForWeek(week);
    if (currentLabel == previousLabel) {
      labels.add(null);
      continue;
    }

    labels.add(currentLabel);
    previousLabel = currentLabel;
  }

  return labels;
}

String _monthLabelForWeek(List<GitHubContributionDay> week) {
  if (week.isEmpty) return '';
  return _calendarMonthNames[week.last.date.month - 1];
}
