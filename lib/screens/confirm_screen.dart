import 'dart:async';

import 'package:flutter/material.dart';

import '../data/foods.dart';
import '../l10n/strings.dart';
import '../services/backend.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'adjust_screen.dart';
import 'snap_screen.dart' show showFoodSearch;

/// 05 · Confirm – the model's top-5 guesses + the swap goal.
class ConfirmScreen extends StatefulWidget {
  const ConfirmScreen({super.key});

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  int _selected = 0;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recognise());
  }

  /// Sends the photo to the NutriGo server and shows its top-5 guesses.
  Future<void> _recognise() async {
    final s = AppScope.read(context);
    final path = s.photoPath;
    if (path == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _selected = 0;
    });
    try {
      final r = await Backend.recognise(path, s.goal);
      if (!mounted) return;
      s.setGuesses(r.guesses, low: r.lowConfidence);
      setState(() {
        _loading = false;
        if (r.guesses.isEmpty) _error = tr('Could not recognise this meal.');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = tr(Backend.describe(e));
      });
    }
  }

  void _go(Food food) {
    AppScope.read(context).startMeal(food, keepPhoto: true);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AdjustScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final guesses = s.guesses;
    if (_selected >= guesses.length) _selected = 0;
    final picked = guesses.isEmpty ? null : guesses[_selected].$1;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // ---- Photo header ----
          Container(
            height: top + 300,
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
            child: SafeArea(
              bottom: false,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 16,
                    left: 22,
                    right: 22,
                    child: Row(
                      children: [
                        const BackCircleButton(onDark: true),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                              tr('Step {a} of 4 · {name}',
                                  {'a': 2, 'name': tr('Confirm')}),
                              style: AppText.body(14.2,
                                  color: Colors.white,
                                  weight: FontWeight.w700)),
                        ),
                        const Spacer(),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 72,
                    child: MealIllustration(size: 180, photoPath: s.photoPath),
                  ),
                ],
              ),
            ),
          ),
          // ---- Sheet ----
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 13),
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: kPagePad.copyWith(top: 22, bottom: 16),
                        children: [
                          Text(tr('Is this your meal?'),
                              style: AppText.heading(24)),
                          const SizedBox(height: 6),
                          Text(tr('The model\'s top 5 guesses. Tap to correct.'),
                              style: AppText.subtitle),
                          const SizedBox(height: 14),
                          // ---- Goal for the healthier swaps (same 5 as the website) ----
                          AppCard(
                            radius: 14,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.track_changes_rounded,
                                    color: AppColors.greenText, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(tr('Swaps goal'),
                                      style: AppText.body(15.3,
                                          weight: FontWeight.w700)),
                                ),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<Goal>(
                                    value: s.goal,
                                    borderRadius: BorderRadius.circular(12),
                                    style: AppText.body(14.2,
                                        weight: FontWeight.w600),
                                    items: [
                                      for (final g in const [
                                        Goal.balanced,
                                        Goal.highProtein,
                                        Goal.loseWeight,
                                        Goal.lowCarb,
                                        Goal.vegetarian,
                                      ])
                                        DropdownMenuItem(
                                            value: g, child: Text(tr(g.label))),
                                    ],
                                    onChanged: (g) {
                                      if (g == null || g == s.goal) return;
                                      s.update(() => s.goal = g);
                                      unawaited(Backend.syncProfile(s));
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (_loading)
                            AppCard(
                              radius: 16,
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: AppColors.green),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(tr('Recognising your meal…'),
                                        style: AppText.body(15.3,
                                            weight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          if (_error != null && !_loading) ...[
                            AppCard(
                              radius: 16,
                              borderColor: AppColors.orange,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_error!,
                                      style: AppText.body(14.2,
                                          weight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed: _recognise,
                                        child: Text(tr('Try again'),
                                            style: AppText.body(14.2,
                                                color: AppColors.greenText,
                                                weight: FontWeight.w700)),
                                      ),
                                      const Spacer(),
                                      Flexible(
                                        child: Text(Backend.baseUrl,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppText.body(12,
                                                color: AppColors.muted)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (s.lowConfidence && !_loading && guesses.isNotEmpty) ...[
                            Text(
                                tr('Not sure about this one – please check the guess or search the list.'),
                                style: AppText.body(13.1,
                                    color: AppColors.orange,
                                    weight: FontWeight.w600)),
                            const SizedBox(height: 12),
                          ],
                          if (!_loading)
                          for (var i = 0;
                              i < guesses.length;
                              i++) ...[
                            _GuessCard(
                              food: guesses[i].$1,
                              confidence: guesses[i].$2,
                              selected: i == _selected,
                              onTap: () => setState(() => _selected = i),
                            ),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 8),
                          AppCard(
                            radius: 14,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 18),
                            onTap: () async {
                              final f = await showFoodSearch(context);
                              if (f != null && mounted) _go(f);
                            },
                            child: Row(
                              children: [
                                Icon(Icons.search_rounded,
                                    color: AppColors.muted, size: 20),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text.rich(TextSpan(
                                    text: tr('Not here? '),
                                    style: AppText.body(15.3,
                                        color: AppColors.muted),
                                    children: [
                                      TextSpan(
                                          text: tr('Search all {n} foods',
                                              {'n': Backend.foodCount ?? 101}),
                                          style: AppText.body(15.3,
                                              weight: FontWeight.w700)),
                                    ],
                                  )),
                                ),
                                Icon(Icons.chevron_right_rounded,
                                    color: AppColors.muted),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: kPagePad.copyWith(
                          bottom: 16 + MediaQuery.paddingOf(context).bottom),
                      child: PrimaryButton(
                        label: picked == null
                            ? tr('Confirm')
                            : tr('Confirm {name}', {'name': tr(picked.name)}),
                        icon: Icons.check_rounded,
                        onPressed: picked == null ? null : () => _go(picked),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuessCard extends StatelessWidget {
  const _GuessCard({
    required this.food,
    required this.confidence,
    required this.selected,
    required this.onTap,
  });

  final Food food;
  final double confidence;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round();
    return Semantics(
      selected: selected,
      child: AppCard(
        onTap: onTap,
        radius: 16,
        color: selected ? AppColors.greenTint : AppColors.surface,
        borderColor: selected ? AppColors.green : AppColors.border,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 17, 16),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected ? AppColors.green : AppColors.border,
                    width: 2),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                          color: AppColors.green, shape: BoxShape.circle),
                    )
                  : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(food.name),
                      style: AppText.body(16.4, weight: FontWeight.w700)),
                  Text(
                      '${tr(food.category)} · ~${tr('{n} kcal', {'n': food.kcal})}',
                      style: AppText.body(13.1, color: AppColors.muted)),
                ],
              ),
            ),
            SizedBox(
              width: 77,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$pct%',
                      style: AppText.body(15.3,
                          weight: FontWeight.w800,
                          color: selected
                              ? AppColors.greenText
                              : AppColors.ink)),
                  const SizedBox(height: 8),
                  ProgressBar(
                    value: confidence,
                    height: 7,
                    color: selected ? AppColors.green : AppColors.muted,
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
