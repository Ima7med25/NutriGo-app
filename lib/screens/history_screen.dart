import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'home_screen.dart' show mealSubtitle;
import 'main_shell.dart';

/// 09 · History.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _week = true;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);

    final List<int> values;
    final List<String> labels;
    final String title;
    final int saved;
    if (_week) {
      const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      values = s.weekKcal;
      labels = [for (final d in s.weekDays) tr(names[d.weekday - 1])];
      title = tr('This week');
      saved = s.weekSaved;
    } else {
      values = s.monthDailyAvg;
      labels = [for (var i = 1; i <= 4; i++) tr('Wk {n}', {'n': i})];
      title = tr('This month · daily avg');
      saved = s.monthSaved;
    }
    // Earlier days (before yesterday) that have meals, newest first.
    final yesterdayDay =
        AppState.dayOf(DateTime.now()).subtract(const Duration(days: 1));
    final earlierDays = <DateTime>{
      for (final m in s.meals)
        if (m.date.isBefore(yesterdayDay)) m.date
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: kPagePad.copyWith(top: 40, bottom: kTabBarClearance),
        children: [
          Row(
            children: [
              Expanded(child: Text(tr('History'), style: AppText.screenTitle)),
              _Segment(
                week: _week,
                onChanged: (w) => setState(() => _week = w),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.fromLTRB(17, 16, 17, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppText.label),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                                tr('−{n} kcal saved', {'n': fmt(saved)}),
                                style: AppText.heading(24,
                                    color: AppColors.greenText)),
                          ),
                        ],
                      ),
                    ),
                    Tag(
                      text: tr('{n}-day streak', {'n': s.streakDays}),
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.orange,
                      background: AppColors.orangeTint,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _BarChart(
                  values: values,
                  labels: labels,
                  goal: s.calorieTarget,
                  highlightLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DayHeader(label: tr('Today'), kcal: s.consumedToday),
          const SizedBox(height: 8),
          if (s.today.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child:
                  Text(tr('Nothing logged yet today.'), style: AppText.label),
            ),
          for (final m in s.today) ...[
            MealTile(
                title: tr(m.name), subtitle: mealSubtitle(m), kcal: m.kcal),
            const SizedBox(height: 9),
          ],
          const SizedBox(height: 8),
          if (s.yesterday.isNotEmpty) ...[
            _DayHeader(label: tr('Yesterday'), kcal: s.yesterdayKcal),
            const SizedBox(height: 8),
            for (final m in s.yesterday) ...[
              MealTile(
                  title: tr(m.name), subtitle: mealSubtitle(m), kcal: m.kcal),
              const SizedBox(height: 9),
            ],
          ],
          for (final d in earlierDays) ...[
            const SizedBox(height: 8),
            _DayHeader(
                label: '${d.day}/${d.month}/${d.year}', kcal: s.kcalOn(d)),
            const SizedBox(height: 8),
            for (final m in s.mealsOn(d)) ...[
              MealTile(
                  title: tr(m.name), subtitle: mealSubtitle(m), kcal: m.kcal),
              const SizedBox(height: 9),
            ],
          ],
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label, required this.kcal});
  final String label;
  final int kcal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppText.heading(18))),
        Text(tr('{n} kcal', {'n': fmt(kcal)}),
            style: AppText.body(14.2,
                color: AppColors.muted, weight: FontWeight.w700)),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.week, required this.onChanged});
  final bool week;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget opt(String t, bool v) {
      final sel = v == week;
      return GestureDetector(
        onTap: () => onChanged(v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 31,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? AppColors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(t,
              style: AppText.body(14.2,
                  weight: FontWeight.w700,
                  color: sel ? Colors.white : AppColors.muted)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [opt(tr('Week'), true), opt(tr('Month'), false)],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.values,
    required this.labels,
    required this.goal,
    this.highlightLast = false,
  });

  final List<int> values;
  final List<String> labels;
  final int goal;
  final bool highlightLast;

  static const _area = 120.0;

  @override
  Widget build(BuildContext context) {
    final maxV = math.max(goal * 1.15, values.reduce(math.max).toDouble());
    final goalY = _area * (1 - goal / maxV);

    return SizedBox(
      height: _area + 30,
      child: Stack(
        children: [
          // goal line
          Positioned(
            left: 0,
            right: 0,
            top: goalY + 6,
            child: CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _DashedLine(AppColors.muted.withValues(alpha: 0.5)),
            ),
          ),
          PositionedDirectional(
            end: 0,
            top: goalY - 11,
            child: Text(tr('goal {n}', {'n': fmt(goal)}),
                style: AppText.body(11, color: AppColors.muted)),
          ),
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Tooltip(
                          message: tr('{n} kcal', {'n': fmt(values[i])}),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: values[i] / maxV),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, _) => Container(
                              width: 24,
                              height: _area * v,
                              decoration: BoxDecoration(
                                color: _color(i),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(labels[i],
                            maxLines: 1,
                            style: AppText.body(12,
                                    color: highlightLast &&
                                            i == values.length - 1
                                        ? AppColors.ink
                                        : AppColors.muted,
                                    weight: highlightLast &&
                                            i == values.length - 1
                                        ? FontWeight.w700
                                        : FontWeight.w400)
                                .copyWith(height: 1.3)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _color(int i) {
    if (highlightLast && i == values.length - 1) return AppColors.green;
    if (values[i] > goal) {
      return AppColors.dark ? const Color(0xFF8A5A1E) : const Color(0xFFFFCC80);
    }
    return AppColors.greenSoft;
  }
}

class _DashedLine extends CustomPainter {
  _DashedLine(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(
          Offset(x, 0), Offset(math.min(x + 4, size.width), 0), p);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLine oldDelegate) =>
      oldDelegate.color != color;
}
