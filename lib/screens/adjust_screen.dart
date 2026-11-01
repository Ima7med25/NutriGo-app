import 'dart:io';

import 'package:flutter/material.dart';

import '../data/foods.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'swaps_screen.dart';

/// 06 · Adjust portion.
class AdjustScreen extends StatelessWidget {
  const AdjustScreen({super.key});

  static String portionLabel(double p) =>
      p == p.roundToDouble() ? '${p.toInt()}×' : '$p×';

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final picked = s.currentFood;
    if (picked == null) {
      return const Scaffold(body: SafeArea(child: BackCircleButton()));
    }
    final food = picked;
    final p = s.portion;
    final kcal = (food.kcal * p).round();
    final pct = (kcal / s.calorieTarget * 100).round();
    final confidence = s.confidenceFor(food);
    final photo = s.photoPath;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: kPagePad.copyWith(top: 16),
              child: Row(
                children: [
                  const BackCircleButton(),
                  Expanded(
                    child: Text(tr('Adjust portion'),
                        textAlign: TextAlign.center, style: AppText.barTitle),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Padding(
              padding: kPagePad.copyWith(top: 17),
              child: const FlowSteps(current: 3),
            ),
            Expanded(
              child: ListView(
                padding: kPagePad.copyWith(top: 20, bottom: 16),
                children: [
                  // ---- Food ----
                  AppCard(
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 70,
                            height: 70,
                            color: AppColors.orangeTint,
                            child: photo != null
                                ? Image.file(File(photo),
                                    fit: BoxFit.cover,
                                    cacheWidth: 210,
                                    errorBuilder: (_, _, _) =>
                                        const _FoodIcon())
                                : const _FoodIcon(),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr(food.name), style: AppText.heading(20.5)),
                              const SizedBox(height: 3),
                              Text(
                                confidence == null
                                    ? tr(food.category)
                                    : tr('{cat} · recognised {n}%', {
                                        'cat': tr(food.category),
                                        'n': (confidence * 100).round(),
                                      }),
                                style:
                                    AppText.body(13.1, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: Text(tr('Change'),
                              style: AppText.body(14.2,
                                  color: AppColors.greenText,
                                  weight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // ---- Portion ----
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(tr('Portion'), style: AppText.heading(18)),
                            const Spacer(),
                            Text(
                                tr('{p} · about {g} g', {
                                  'p': portionLabel(p),
                                  'g': (food.grams * p).round(),
                                }),
                                style: AppText.body(14.2,
                                    color: AppColors.greenText,
                                    weight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 7,
                            activeTrackColor: AppColors.green,
                            inactiveTrackColor: AppColors.track,
                            thumbColor: Colors.white,
                            overlayColor:
                                AppColors.green.withValues(alpha: 0.12),
                            thumbShape: const _RingThumb(),
                            tickMarkShape: SliderTickMarkShape.noTickMark,
                            trackShape: const RoundedRectSliderTrackShape(),
                          ),
                          child: Slider(
                            min: 0.5,
                            max: 2,
                            divisions: 3,
                            value: p,
                            onChanged: s.setPortion,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (final v in const [0.5, 1.0, 1.5, 2.0])
                                Text(portionLabel(v),
                                    style: AppText.body(12,
                                        color: v == p
                                            ? AppColors.ink
                                            : AppColors.muted,
                                        weight: v == p
                                            ? FontWeight.w700
                                            : FontWeight.w400)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(tr(food.portionTip), style: AppText.caption),
                      ],
                    ),
                  ),
                  const SizedBox(height: 17),
                  _NutritionFacts(food: food, portion: p),
                  const SizedBox(height: 17),
                  // ---- Live total ----
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 20),
                    decoration: BoxDecoration(
                      color: AppColors.orangeTint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            color: AppColors.orange, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                    text: tr('{n} kcal', {'n': kcal}),
                                    style: AppText.body(14.2,
                                        weight: FontWeight.w800)),
                                TextSpan(
                                    text: tr(' = {pct}% of your {t} kcal day', {
                                  'pct': pct,
                                  't': fmt(s.calorieTarget),
                                })),
                              ],
                            ),
                            style: AppText.body(14.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: kPagePad.copyWith(bottom: 16),
              child: PrimaryButton(
                label: tr('Find lighter swaps'),
                icon: Icons.swap_horiz_rounded,
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SwapsScreen())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodIcon extends StatelessWidget {
  const _FoodIcon();

  @override
  Widget build(BuildContext context) => const Icon(Icons.lunch_dining_rounded,
      color: Color(0xFF8D4E1F), size: 40);
}

class _NutritionFacts extends StatelessWidget {
  const _NutritionFacts({required this.food, required this.portion});
  final Food food;
  final double portion;

  @override
  Widget build(BuildContext context) {
    int sc(int v) => (v * portion).round();
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Text(k, style: AppText.body(14.2, weight: FontWeight.w600)),
              const Spacer(),
              Text(v, style: AppText.body(14.2, weight: FontWeight.w700)),
            ],
          ),
        );
    final thin = Divider(height: 1, thickness: 1, color: AppColors.border);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Nutrition Facts'),
              style: AppText.heading(19.7, weight: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(height: 4, color: AppColors.ink),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(tr('Calories'),
                  style: AppText.heading(19.7, weight: FontWeight.w800)),
              const Spacer(),
              Text('${sc(food.kcal)}',
                  style: AppText.heading(30, weight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 2, color: AppColors.ink),
          const SizedBox(height: 4),
          row(tr('Protein'), tr('{n} g', {'n': sc(food.protein)})),
          thin,
          row(tr('Carbs'), tr('{n} g', {'n': sc(food.carbs)})),
          thin,
          row(tr('Fat'), tr('{n} g', {'n': sc(food.fat)})),
          thin,
          row(tr('Sodium'), tr('{n} mg', {'n': fmt(sc(food.sodiumMg))})),
        ],
      ),
    );
  }
}

/// White thumb with green ring (28px).
class _RingThumb extends SliderComponentShape {
  const _RingThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(28, 28);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final c = context.canvas;
    c.drawCircle(center + const Offset(0, 2), 14,
        Paint()..color = Colors.black.withValues(alpha: 0.12));
    c.drawCircle(center, 14, Paint()..color = Colors.white);
    c.drawCircle(
        center,
        12,
        Paint()
          ..color = AppColors.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
  }
}
