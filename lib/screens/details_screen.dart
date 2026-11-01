import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/backend.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'main_shell.dart';

/// 02b · Your details.
class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key, this.password});

  /// Set when coming from sign-up: the account is created on the server on save.
  final String? password;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final diff = s.goalWeightKg - s.weightKg;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: kPagePad.copyWith(top: 16, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BackCircleButton(),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 129,
                          child: Row(
                            children: [
                              Expanded(child: _seg()),
                              const SizedBox(width: 5),
                              Expanded(child: _seg()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(tr('Step {a} of {b}', {'a': 2, 'b': 2}),
                            style: AppText.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(tr('Tell us about you'), style: AppText.screenTitle),
              const SizedBox(height: 6),
              Text(tr('We use this to calculate your daily calories.'),
                  style: AppText.subtitle),
              const SizedBox(height: 16),
              _GenderToggle(
                value: s.gender,
                onChanged: (g) => s.update(() => s.gender = g),
              ),
              const SizedBox(height: 16),
              StepperCard(
                label: tr('Age'),
                value: tr('{n} years', {'n': s.age}),
                valueSize: 24,
                onMinus: () =>
                    s.update(() => s.age = (s.age - 1).clamp(13, 100)),
                onPlus: () =>
                    s.update(() => s.age = (s.age + 1).clamp(13, 100)),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: _DragValueCard(
                      label: tr('Weight'),
                      value: s.weightKg,
                      unit: tr('kg'),
                      min: 35,
                      max: 250,
                      onChanged: (v) => s.update(() => s.weightKg = v),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: _DragValueCard(
                      label: tr('Height'),
                      value: s.heightCm,
                      unit: tr('cm'),
                      min: 120,
                      max: 230,
                      onChanged: (v) => s.update(() => s.heightCm = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              _GoalWeightCard(
                value: s.goalWeightKg,
                diff: diff,
                onChanged: (v) => s.update(() => s.goalWeightKg = v),
              ),
              const SizedBox(height: 14),
              Text(tr('Activity level'),
                  style: AppText.body(16.4, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (final a in ActivityLevel.values)
                    SelectChip(
                      label: tr(a.label),
                      selected: s.activity == a,
                      onTap: () => s.update(() => s.activity = a),
                    ),
                ],
              ),
              const SizedBox(height: 17),
              const DailyTargetCard(),
              const SizedBox(height: 22),
              _SaveButton(password: password),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _seg() => Container(
        height: 7,
        decoration: BoxDecoration(
            color: AppColors.green, borderRadius: BorderRadius.circular(4)),
      );
}

class _GenderToggle extends StatelessWidget {
  const _GenderToggle({required this.value, required this.onChanged});
  final Gender value;
  final ValueChanged<Gender> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget opt(Gender g, String label) {
      final sel = g == value;
      return Expanded(
        child: Semantics(
          selected: sel,
          button: true,
          child: GestureDetector(
            onTap: () => onChanged(g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? AppColors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(label,
                  style: AppText.body(15.3,
                      weight: FontWeight.w700,
                      color: sel ? Colors.white : AppColors.muted)),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        opt(Gender.male, tr('Male')),
        const SizedBox(width: 4),
        opt(Gender.female, tr('Female')),
      ]),
    );
  }
}

/// Card whose value changes by dragging horizontally across it.
class _DragValueCard extends StatefulWidget {
  const _DragValueCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final String unit;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  State<_DragValueCard> createState() => _DragValueCardState();
}

class _DragValueCardState extends State<_DragValueCard> {
  double _acc = 0;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final value = w.value, unit = w.unit, label = w.label;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      label: label,
      value: '$value $unit',
      increasedValue: '${value + 1} $unit',
      decreasedValue: '${value - 1} $unit',
      onIncrease: () => w.onChanged((value + 1).clamp(w.min, w.max)),
      onDecrease: () => w.onChanged((value - 1).clamp(w.min, w.max)),
      child: GestureDetector(
        onHorizontalDragStart: (_) => _acc = 0,
        onHorizontalDragUpdate: (d) {
          _acc += rtl ? -d.delta.dx : d.delta.dx;
          var steps = 0;
          while (_acc.abs() >= 8) {
            final step = _acc > 0 ? 1 : -1;
            _acc -= step * 8;
            steps += step;
          }
          if (steps != 0) {
            widget.onChanged((widget.value + steps).clamp(w.min, w.max));
          }
        },
        child: AppCard(
          padding: const EdgeInsetsDirectional.fromSTEB(17, 12, 14, 12),
          child: SizedBox(
            height: 66,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppText.label),
                    const SizedBox(height: 2),
                    Text.rich(TextSpan(children: [
                      TextSpan(text: '$value', style: AppText.heading(30)),
                      TextSpan(text: ' $unit', style: AppText.heading(20)),
                    ])),
                  ],
                ),
                // Arrows: show that the card can be swiped, and tap to change by 1.
                PositionedDirectional(
                  end: 0,
                  top: 0,
                  child: Row(
                    textDirection: TextDirection.ltr,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ArrowButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => w.onChanged(
                            (value + (rtl ? 1 : -1)).clamp(w.min, w.max)),
                      ),
                      Icon(Icons.swipe_rounded,
                          size: 15,
                          color: AppColors.muted.withValues(alpha: 0.7)),
                      _ArrowButton(
                        icon: Icons.chevron_right_rounded,
                        onTap: () => w.onChanged(
                            (value + (rtl ? -1 : 1)).clamp(w.min, w.max)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small round arrow used on the weight / height cards.
class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: 22, color: AppColors.greenText),
      ),
    );
  }
}

class _GoalWeightCard extends StatelessWidget {
  const _GoalWeightCard(
      {required this.value, required this.diff, required this.onChanged});
  final int value;
  final int diff;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final diffText = diff == 0
        ? tr('Maintain')
        : '${diff < 0 ? '−' : '+'}${diff.abs()} ${tr('kg')}';
    return AppCard(
      padding: const EdgeInsetsDirectional.fromSTEB(17, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Goal weight'), style: AppText.label),
                const SizedBox(height: 3),
                Text('$value ${tr('kg')}', style: AppText.heading(19.7)),
              ],
            ),
          ),
          IconButton(
            tooltip: tr('Decrease'),
            onPressed: () => onChanged((value - 1).clamp(35, 250)),
            icon: Icon(Icons.remove_rounded, color: AppColors.muted, size: 18),
          ),
          Tag(text: diffText, fontSize: 14.2),
          IconButton(
            tooltip: tr('Increase'),
            onPressed: () => onChanged((value + 1).clamp(35, 250)),
            icon: Icon(Icons.add_rounded, color: AppColors.muted, size: 18),
          ),
        ],
      ),
    );
  }
}

/// Dark card with the computed daily target and macro split.
class DailyTargetCard extends StatelessWidget {
  const DailyTargetCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final adj = s.goalAdjustment;
    final adjText = adj == 0
        ? tr('to maintain')
        : (adj < 0
            ? tr('− {n} to lose weight', {'n': -adj})
            : tr('+ {n} to gain weight', {'n': adj}));
    const pC = Color(0xFF66BB6A), cC = Color(0xFF42A5F5), fC = Color(0xFFFFB74D);
    final white70 = Colors.white.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.fromLTRB(17, 19, 17, 17),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(18),
      ),
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
                    Text(tr('YOUR DAILY TARGET'),
                        style: AppText.overline.copyWith(color: white70)),
                    const SizedBox(height: 2),
                    Text.rich(TextSpan(children: [
                      TextSpan(
                          text: tr('{n} kcal', {'n': fmt(s.calorieTarget)}),
                          style: AppText.heading(30, color: Colors.white)),
                      TextSpan(
                          text: tr(' / day'),
                          style: AppText.heading(20, color: white70)),
                    ])),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => s.update(() => s.autoTarget = true),
                child: Tag(
                  text: s.autoTarget ? tr('Auto') : tr('Manual'),
                  color: Colors.white,
                  background: s.autoTarget
                      ? AppColors.green
                      : Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            tr('BMR {bmr} × {f} activity {adj}', {
              'bmr': fmt(s.bmr),
              'f': s.activity.factor,
              'adj': adjText,
            }),
            style: AppText.body(12, color: white70),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(flex: 108, child: _bar(pC)),
              const SizedBox(width: 3),
              Expanded(flex: 144, child: _bar(cC)),
              const SizedBox(width: 3),
              Expanded(flex: 104, child: _bar(fC)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            children: [
              _legend(pC, tr('Protein {n} g', {'n': s.proteinG})),
              _legend(cC, tr('Carbs {n} g', {'n': s.carbsG})),
              _legend(fC, tr('Fat {n} g', {'n': s.fatG})),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _bar(Color c) => Container(
      height: 7,
      decoration:
          BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)));

  static Widget _legend(Color c, String t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(t, style: AppText.body(12, color: Colors.white)),
        ],
      );
}

/// "Save and continue": creates the account (after sign-up) or saves the
/// profile on the server, then opens Home.
class _SaveButton extends StatefulWidget {
  const _SaveButton({this.password});
  final String? password;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _busy = false;

  Future<void> _save() async {
    final s = AppScope.read(context);
    final password = widget.password;
    if (password == null) {
      unawaited(Backend.syncProfile(s));
      goHome(context);
      return;
    }
    setState(() => _busy = true);
    try {
      await Backend.register(s, password);
      unawaited(Backend.syncProfile(s)); // also creates the 7-day plan
      if (mounted) goHome(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(Backend.describe(e)))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: _busy ? tr('Please wait…') : tr('Save and continue'),
      icon: _busy ? null : Icons.arrow_forward_rounded,
      onPressed: _busy ? null : _save,
    );
  }
}
