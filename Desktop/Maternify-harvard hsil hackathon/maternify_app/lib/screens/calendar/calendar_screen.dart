import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/calendar/calendar_bloc.dart';

// ─── Milestone data ──────────────────────────────────────────────────────────

class _Milestone {
  final int week;
  final String bangla;
  final String english;
  final String emoji;
  const _Milestone(this.week, this.bangla, this.english, this.emoji);
}

const _milestones = [
  _Milestone(8, 'হৃদস্পন্দন শোনা যায়', 'Heartbeat detectable', '💓'),
  _Milestone(12, 'প্রথম ত্রৈমাসিক শেষ', 'End of 1st trimester', '🎉'),
  _Milestone(16, 'লিঙ্গ নির্ধারণ সম্ভব', 'Gender can be determined', '👶'),
  _Milestone(20, 'অ্যানাটমি স্ক্যান', 'Anatomy scan', '🔬'),
  _Milestone(24, 'বেঁচে থাকার সীমা', 'Viability threshold', '🌱'),
  _Milestone(28, 'তৃতীয় ত্রৈমাসিক শুরু', '3rd trimester begins', '⭐'),
  _Milestone(36, 'শিশু প্রায় প্রস্তুত', 'Baby nearly ready', '🌟'),
  _Milestone(40, 'প্রত্যাশিত প্রসব তারিখ', 'Expected due date', '🎊'),
];

// ─── Baby size by week (rounded to nearest even) ─────────────────────────────

const _babySizes = {
  4: ('তিল বীজ', 'Poppy seed', '🌱'),
  6: ('মটরশুটি', 'Sweet pea', '🫘'),
  8: ('রাস্পবেরি', 'Raspberry', '🫐'),
  10: ('স্ট্রবেরি', 'Strawberry', '🍓'),
  12: ('লেবু', 'Lime', '🍋'),
  14: ('কমলা', 'Orange', '🍊'),
  16: ('আভোকাডো', 'Avocado', '🥑'),
  18: ('মিষ্টি আলু', 'Sweet potato', '🍠'),
  20: ('কলা', 'Banana', '🍌'),
  22: ('নারিকেল', 'Coconut', '🥥'),
  24: ('ভুট্টা', 'Corn', '🌽'),
  26: ('লেটুস', 'Lettuce', '🥬'),
  28: ('বাঁধাকপি', 'Cabbage', '🥦'),
  30: ('শসা', 'Cucumber', '🥒'),
  32: ('স্কোয়াশ', 'Squash', '🧡'),
  34: ('তরমুজ', 'Cantaloupe', '🍈'),
  36: ('রোমেইন', 'Romaine', '🥗'),
  38: ('লিক', 'Leek', '🌿'),
  40: ('ছোট কুমড়া', 'Small pumpkin', '🎃'),
};

(String, String, String) _babySize(int week) {
  final rounded = (week ~/ 2) * 2;
  final clamped = rounded.clamp(4, 40);
  return _babySizes[clamped] ?? ('শিশু বড় হচ্ছে', 'Baby growing', '🍼');
}

// ─── Tier colours ─────────────────────────────────────────────────────────────

Color _tierColour(String tier) => switch (tier) {
      'red' => const Color(0xFFD32F2F),
      'yellow' => const Color(0xFFF9A825),
      _ => const Color(0xFF388E3C),
    };

// ─── Screen ───────────────────────────────────────────────────────────────────

class CalendarScreen extends StatelessWidget {
  final String patientId;
  final int weeksGestation;

  const CalendarScreen({
    super.key,
    required this.patientId,
    required this.weeksGestation,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CalendarBloc()
        ..add(CalendarLoadRequested(
          patientId: patientId,
          weeksGestation: weeksGestation,
        )),
      child: const _CalendarView(),
    );
  }
}

class _CalendarView extends StatelessWidget {
  const _CalendarView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        if (state is CalendarLoading || state is CalendarInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is CalendarError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        if (state is CalendarLoaded) {
          return _LoadedView(state: state);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _LoadedView extends StatelessWidget {
  final CalendarLoaded state;
  const _LoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final daysLeft = state.dueDate.difference(today).inDays;
    final week = state.weeksGestation;
    final trimester = week <= 12 ? 1 : (week <= 27 ? 2 : 3);
    final progress = (week / 40.0).clamp(0.0, 1.0);
    final babySize = _babySize(week);

    // Upcoming milestone
    final upcomingMilestone = _milestones
        .where((m) => m.week >= week)
        .fold<_Milestone?>(null, (acc, m) => acc ?? m);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProgressCard(
            week: week,
            trimester: trimester,
            progress: progress,
            daysLeft: daysLeft,
            dueDate: state.dueDate,
          ),
          const SizedBox(height: 12),
          _BabySizeCard(week: week, babySize: babySize),
          const SizedBox(height: 12),
          if (upcomingMilestone != null)
            _NextMilestoneCard(milestone: upcomingMilestone, currentWeek: week),
          const SizedBox(height: 12),
          _MonthCalendar(state: state),
          const SizedBox(height: 12),
          _MilestoneTimeline(currentWeek: week),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Progress card ────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final int week;
  final int trimester;
  final double progress;
  final int daysLeft;
  final DateTime dueDate;

  const _ProgressCard({
    required this.week,
    required this.trimester,
    required this.progress,
    required this.daysLeft,
    required this.dueDate,
  });

  @override
  Widget build(BuildContext context) {
    final trimesterLabel = ['প্রথম', 'দ্বিতীয়', 'তৃতীয়'][trimester - 1];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF993556), Color(0xFFBF4070)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$week',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'সপ্তাহ',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$trimesterLabel ত্রৈমাসিক',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    daysLeft > 0
                        ? 'আর $daysLeft দিন বাকি'
                        : 'প্রসব তারিখ পার হয়েছে',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMM yyyy', 'en').format(dueDate),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% সম্পন্ন',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Baby size card ───────────────────────────────────────────────────────────

class _BabySizeCard extends StatelessWidget {
  final int week;
  final (String, String, String) babySize;

  const _BabySizeCard({required this.week, required this.babySize});

  @override
  Widget build(BuildContext context) {
    final (bangla, english, emoji) = babySize;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('শিশুর বর্তমান আকার',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                  Text(bangla,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(english,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'সপ্তাহ $week / 40',
                style: const TextStyle(
                    color: Color(0xFF993556), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Next milestone card ──────────────────────────────────────────────────────

class _NextMilestoneCard extends StatelessWidget {
  final _Milestone milestone;
  final int currentWeek;

  const _NextMilestoneCard(
      {required this.milestone, required this.currentWeek});

  @override
  Widget build(BuildContext context) {
    final weeksAway = milestone.week - currentWeek;
    return Card(
      elevation: 2,
      color: const Color(0xFFF3E5F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Text(milestone.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('পরবর্তী মাইলস্টোন',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                          fontWeight: FontWeight.w500)),
                  Text(milestone.bangla,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(milestone.english,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            if (weeksAway > 0)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                    color: Color(0xFF7B1FA2), shape: BoxShape.circle),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$weeksAway',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const Text('সপ্তাহ',
                        style: TextStyle(color: Colors.white70, fontSize: 9)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Month calendar ───────────────────────────────────────────────────────────

class _MonthCalendar extends StatelessWidget {
  final CalendarLoaded state;
  const _MonthCalendar({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CalendarBloc>();
    final month = state.displayMonth;
    final prevMonth = DateTime(month.year, month.month - 1);
    final nextMonth = DateTime(month.year, month.month + 1);

    final firstDay = DateTime(month.year, month.month, 1);
    // weekday: 1=Mon … 7=Sun → we want Sun=0 offset
    final startOffset = (firstDay.weekday % 7);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final today = DateTime.now();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () =>
                      bloc.add(CalendarMonthChanged(prevMonth)),
                ),
                Text(
                  DateFormat('MMMM yyyy', 'en').format(month),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () =>
                      bloc.add(CalendarMonthChanged(nextMonth)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Day-of-week headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                  .map((d) => SizedBox(
                        width: 36,
                        child: Center(
                          child: Text(d,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black45)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 4),
            // Day cells
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: startOffset + daysInMonth,
              itemBuilder: (context, index) {
                if (index < startOffset) return const SizedBox.shrink();
                final day = index - startOffset + 1;
                final date = DateTime(month.year, month.month, day);
                final normDate = DateTime(date.year, date.month, date.day);
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final hasVitals = state.vitalsDates.contains(normDate);
                final triageTier = state.triageDates[normDate];

                return _DayCell(
                  day: day,
                  isToday: isToday,
                  hasVitals: hasVitals,
                  triageTier: triageTier,
                );
              },
            ),
            const SizedBox(height: 8),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: const Color(0xFF993556), label: 'ভাইটালস'),
                const SizedBox(width: 12),
                _LegendDot(
                    color: const Color(0xFF388E3C), label: 'ট্রায়াজ (সবুজ)'),
                const SizedBox(width: 12),
                _LegendDot(
                    color: const Color(0xFFF9A825), label: 'ট্রায়াজ (হলুদ)'),
                const SizedBox(width: 12),
                _LegendDot(
                    color: const Color(0xFFD32F2F), label: 'ট্রায়াজ (লাল)'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool hasVitals;
  final String? triageTier;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.hasVitals,
    this.triageTier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: isToday
          ? BoxDecoration(
              color: const Color(0xFF993556),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday ? Colors.white : Colors.black87,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasVitals)
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: const BoxDecoration(
                    color: Color(0xFF993556),
                    shape: BoxShape.circle,
                  ),
                ),
              if (triageTier != null)
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: _tierColour(triageTier!),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ],
    );
  }
}

// ─── Milestone timeline ───────────────────────────────────────────────────────

class _MilestoneTimeline extends StatelessWidget {
  final int currentWeek;
  const _MilestoneTimeline({required this.currentWeek});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('গর্ভাবস্থার মাইলস্টোন',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._milestones.map((m) => _MilestoneRow(
                  milestone: m,
                  isDone: m.week <= currentWeek,
                  isCurrent: m.week == _milestones
                      .where((x) => x.week >= currentWeek)
                      .fold<_Milestone?>(_milestones.last, (acc, x) => acc!.week < x.week ? acc : x)
                      ?.week,
                )),
          ],
        ),
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final _Milestone milestone;
  final bool isDone;
  final bool? isCurrent;

  const _MilestoneRow(
      {required this.milestone, required this.isDone, this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final isNext = isCurrent == milestone.week;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDone
                  ? const Color(0xFF993556)
                  : isNext
                      ? const Color(0xFFFCE4EC)
                      : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      milestone.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${milestone.bangla} (সপ্তাহ ${milestone.week})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isNext ? FontWeight.bold : FontWeight.normal,
                    color: isDone ? Colors.black54 : Colors.black87,
                    decoration:
                        isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  milestone.english,
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
          if (isNext)
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: Color(0xFF993556)),
        ],
      ),
    );
  }
}
