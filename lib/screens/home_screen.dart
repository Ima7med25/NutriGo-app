import 'package:flutter/material.dart';

import '../data/foods.dart';
import '../l10n/strings.dart';
import '../services/backend.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'main_shell.dart';
import 'swap_logged_screen.dart';
import 'swaps_screen.dart';

/// 03 · Home.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return tr('Good morning,');
    if (h < 18) return tr('Good afternoon,');
    return tr('Good evening,');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: kPagePad.copyWith(top: 22, bottom: kTabBarClearance),
        children: [
          // ---- Header ----
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(),
                        style: AppText.label.copyWith(fontSize: 15.3)),
                    Text(s.firstName, style: AppText.heading(26.3)),
                  ],
                ),
              ),
              CircleIconButton(
                icon: Icons.notifications_none_rounded,
                size: 48,
                semanticLabel: tr('Notifications'),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('No new notifications'))),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => MainShell.maybeOf(context)?.selectTab(3),
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: AppColors.green,
                  child: Text(s.initial,
                      style: AppText.heading(19, color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DailyCard(state: s),
          const SizedBox(height: 20),
          _SnapCta(onTap: () => openSnap(context)),
          const SizedBox(height: 24),
          // ---- Goal ----
          Text(tr('Your goal'), style: AppText.sectionTitle),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final g in [
                  Goal.balanced,
                  Goal.loseWeight,
                  Goal.highProtein
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 9),
                    child: SelectChip(
                      label: tr(g.label),
                      height: 35,
                      selected: s.goal == g,
                      onTap: () => s.update(() => s.goal = g),
                    ),
                  ),
                CircleIconButton(
                  icon: Icons.more_horiz_rounded,
                  size: 35,
                  semanticLabel: tr('More goals'),
                  onTap: () => _showGoals(context, s),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // ---- Swap of the day (from the user's own meals) ----
          _SwapOfTheDaySection(state: s),
          const SizedBox(height: 22),
          // ---- Recent meals ----
          SectionHeader(
            title: tr('Recent meals'),
            action: tr('History'),
            onAction: () => MainShell.maybeOf(context)?.selectTab(1),
          ),
          const SizedBox(height: 10),
          if (s.today.isEmpty)
            Text(tr('Nothing logged yet today.'), style: AppText.label)
          else
            for (final m in s.today.take(2)) ...[
              MealTile(
                title: tr(m.name),
                subtitle: mealSubtitle(m, showSaved: false),
                kcal: m.kcal,
              ),
              const SizedBox(height: 9),
            ],
        ],
      ),
    );
  }

  void _showGoals(BuildContext context, AppState s) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: kPagePad.copyWith(bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('Choose your goal'), style: AppText.sectionTitle),
              const SizedBox(height: 14),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (final g in Goal.values)
                    SelectChip(
                      label: tr(g.label),
                      selected: s.goal == g,
                      onTap: () {
                        s.update(() => s.goal = g);
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Lunch · 12:30 · swapped −300"
String mealSubtitle(LoggedMeal m, {bool showSaved = true}) {
  final base = '${tr(m.slot)} · ${m.time}';
  if (!m.swapped) return base;
  return showSaved
      ? '$base · ${tr('swapped')} −${m.savedKcal}'
      : '$base · ${tr('swapped')}';
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final white70 = Colors.white.withValues(alpha: 0.7);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Stack(
          children: [
            PositionedDirectional(
              end: -119,
              top: -131,
              child: Container(
                width: 241,
                height: 241,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 25, 22, 22),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr("TODAY'S CALORIES"),
                                style:
                                    AppText.overline.copyWith(color: white70)),
                            const SizedBox(height: 3),
                            Text.rich(TextSpan(children: [
                              TextSpan(
                                  text: fmt(s.consumedToday),
                                  style: AppText.heading(37,
                                      color: Colors.white)),
                              TextSpan(
                                  text:
                                      '  / ${tr('{n} kcal', {'n': fmt(s.calorieTarget)})}',
                                  style: AppText.body(15.3, color: white70)),
                            ])),
                            const SizedBox(height: 3),
                            Text(
                                tr('{n} kcal left · {goal} goal', {
                                  'n': fmt(s.leftToday),
                                  'goal': tr(s.goal.label),
                                }),
                                style: AppText.body(13.1,
                                    color: const Color(0xFFA5D6A7),
                                    weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      _ProgressRing(value: s.progressToday),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      _stat(s.savedToday == 0 ? '0' : '−${fmt(s.savedToday)}',
                          tr('kcal saved')),
                      const SizedBox(width: 11),
                      _stat('${s.today.length}', tr('meals logged')),
                      const SizedBox(width: 11),
                      _stat('${s.swapsToday}', tr('swaps taken')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: AppText.heading(19.7, color: Colors.white)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    style: AppText.body(12,
                        color: Colors.white.withValues(alpha: 0.7))),
              ),
            ],
          ),
        ),
      );
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 81,
      height: 81,
      child: Stack(
        fit: StackFit.expand,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => CircularProgressIndicator(
              value: v,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              color: AppColors.greenLight,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Center(
            child: Text('${(value * 100).round()}%',
                style: AppText.heading(19, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SnapCta extends StatelessWidget {
  const _SnapCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      radius: 20,
      color: AppColors.greenTint,
      borderColor: AppColors.greenSoft,
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          Container(
            width: 57,
            height: 57,
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.photo_camera_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Snap a meal'), style: AppText.heading(20.5)),
                const SizedBox(height: 3),
                Text(tr('1 photo → 3 taps to a lighter swap'),
                    style: AppText.body(13.1, color: AppColors.muted)),
              ],
            ),
          ),
          Container(
            width: 37,
            height: 37,
            decoration: const BoxDecoration(
                color: AppColors.green, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

class _SwapOfTheDay extends StatelessWidget {
  const _SwapOfTheDay(
      {required this.food, required this.swap, required this.onChoose});
  final Food food;
  final SwapOption swap;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    Widget panel(String name, int kcal, {required bool better}) => Expanded(
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: better ? AppColors.greenTint : AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(13.1, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: '$kcal',
                      style: AppText.heading(24,
                          color:
                              better ? AppColors.greenText : AppColors.ink)),
                  TextSpan(text: '  ${tr('kcal')}', style: AppText.caption),
                ])),
              ],
            ),
          ),
        );

    final saved = food.kcal - swap.kcal;
    return AppCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        children: [
          Row(
            children: [
              panel(tr(food.name), food.kcal, better: false),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: const BoxDecoration(
                      color: AppColors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
              panel(tr(swap.shortName), swap.kcal, better: true),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(TextSpan(
                      text: '${tr('You save')} ',
                      style: AppText.body(15.3, weight: FontWeight.w700),
                      children: [
                        TextSpan(
                            text: tr('−{n} kcal', {'n': saved}),
                            style: AppText.body(15.3,
                                color: AppColors.greenText,
                                weight: FontWeight.w800)),
                      ],
                    )),
                    Text(tr('Same taste · score {n} / 100', {'n': swap.score}),
                        style: AppText.body(13.1, color: AppColors.muted)),
                  ],
                ),
              ),
              SizedBox(
                height: 39,
                child: FilledButton(
                  onPressed: onChoose,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(tr('Choose swap'),
                      style: AppText.body(14.2,
                          color: Colors.white, weight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Smart swap of the day": a lighter swap for the heaviest dish the user
/// logged in the last 7 days. Empty until they log a meal.
class _SwapOfTheDaySection extends StatefulWidget {
  const _SwapOfTheDaySection({required this.state});
  final AppState state;

  @override
  State<_SwapOfTheDaySection> createState() => _SwapOfTheDaySectionState();
}

class _SwapOfTheDaySectionState extends State<_SwapOfTheDaySection> {
  String? _key;
  Food? _food;
  SwapOption? _swap;
  bool _loading = false;

  /// The heaviest non-swap meal with a server food id in the last 7 days.
  LoggedMeal? _candidate(AppState s) {
    final since = AppState.dayOf(DateTime.now()).subtract(const Duration(days: 6));
    LoggedMeal? best;
    for (final m in s.meals) {
      if (m.foodId == null || m.swapped || m.date.isBefore(since)) continue;
      if (best == null || m.kcal > best.kcal) best = m;
    }
    return best;
  }

  Future<void> _load(String foodId, AppState s, String key) async {
    setState(() => _loading = true);
    try {
      final foods = await Backend.foods();
      final food = foods.firstWhere((f) => f.id == foodId);
      final r = await Backend.recommend(food, 1.0, s.goal);
      if (!mounted || key != _key) return;
      setState(() {
        _food = food;
        _swap = r.swaps.isEmpty ? null : r.swaps.first;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || key != _key) return;
      setState(() {
        _food = null;
        _swap = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final c = _candidate(s);
    final key = c == null ? null : '${c.foodId}|${s.goal.apiName}';
    if (key != _key) {
      _key = key;
      _food = null;
      _swap = null;
      if (c != null) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _load(c.foodId!, s, key!));
      }
    }
    final food = _food;
    final swap = _swap;

    final Widget body;
    if (c == null) {
      body = AppCard(
        child: Text(
            tr('Snap or log a meal and your personal lighter swap shows up here.'),
            style: AppText.body(14.2, color: AppColors.muted)),
      );
    } else if (_loading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: AppColors.green)),
      );
    } else if (food == null || swap == null) {
      body = AppCard(
        child: Text(tr('Your meals are already light choices. Nice!'),
            style: AppText.body(14.2, color: AppColors.muted)),
      );
    } else {
      body = _SwapOfTheDay(
        food: food,
        swap: swap,
        onChoose: () {
          s.startMeal(food);
          final meal = s.logSwap(swap);
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SwapLoggedScreen(
                meal: meal, originalName: food.name, originalKcal: food.kcal),
          ));
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: tr('Smart swap of the day'),
          action: food != null ? tr('See all') : null,
          onAction: food == null
              ? null
              : () {
                  s.startMeal(food);
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SwapsScreen()));
                },
        ),
        const SizedBox(height: 10),
        body,
      ],
    );
  }
}
