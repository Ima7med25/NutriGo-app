import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'main_shell.dart';
import 'snap_screen.dart';

/// 08 · Swap logged.
class SwapLoggedScreen extends StatelessWidget {
  const SwapLoggedScreen({
    super.key,
    required this.meal,
    required this.originalName,
    required this.originalKcal,
  });

  final LoggedMeal meal;
  final String originalName;
  final int originalKcal;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final saved = originalKcal - meal.kcal;

    Widget compare(String label, int kcal, String name,
            {required bool after}) =>
        Expanded(
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(17, 13, 12, 13),
            decoration: BoxDecoration(
              color: after ? AppColors.greenTint : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: after ? AppColors.greenSoft : AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppText.body(13.1, color: AppColors.muted)),
                Text('$kcal',
                    style: AppText.heading(24,
                        color: after ? AppColors.greenText : AppColors.ink)),
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(13.1, weight: FontWeight.w600)),
              ],
            ),
          ),
        );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goHome(context);
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: kPagePad.copyWith(top: 40, bottom: 20),
            children: [
              const Center(child: _SuccessBadge()),
              const SizedBox(height: 8),
              Text(tr('Swap logged!'),
                  textAlign: TextAlign.center, style: AppText.screenTitle),
              const SizedBox(height: 8),
              Text(
                  tr('{meal} added to {slot}', {
                    'meal': tr(meal.name),
                    'slot': tr(meal.slot).toLowerCase(),
                  }),
                  textAlign: TextAlign.center,
                  style: AppText.subtitle),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.greenTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(tr('YOU SAVED'),
                        style: AppText.overline
                            .copyWith(color: AppColors.greenText)),
                    Text(tr('−{n} kcal', {'n': saved}),
                        style:
                            AppText.heading(46, color: AppColors.greenText)),
                    Text(
                        tr('compared with the {name}',
                            {'name': tr(originalName)}),
                        style: AppText.body(13.1, color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(height: 17),
              Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    children: [
                      compare(tr('Before'), originalKcal, tr(originalName),
                          after: false),
                      const SizedBox(width: 24),
                      compare(tr('After'), meal.kcal, tr(meal.name),
                          after: true),
                    ],
                  ),
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.background, width: 3),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(tr('Today'),
                            style:
                                AppText.body(15.3, weight: FontWeight.w700)),
                        const Spacer(),
                        Text(
                            '${fmt(s.consumedToday)} / ${tr('{n} kcal', {'n': fmt(s.calorieTarget)})}',
                            style:
                                AppText.body(14.2, weight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ProgressBar(value: s.progressToday),
                    const SizedBox(height: 7),
                    Text(
                        tr('{n} kcal left for today',
                            {'n': fmt(s.leftToday)}),
                        style: AppText.caption),
                  ],
                ),
              ),
              const SizedBox(height: 27),
              PrimaryButton(
                  label: tr('Back to home'), onPressed: () => goHome(context)),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    final nav = Navigator.of(context);
                    nav.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MainShell()),
                        (_) => false);
                    nav.push(MaterialPageRoute(
                        builder: (_) => const SnapScreen()));
                  },
                  child: Text(tr('Snap another meal'),
                      style: AppText.body(16.4,
                          color: AppColors.greenText,
                          weight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green.withValues(alpha: 0.06),
            ),
          ),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green.withValues(alpha: 0.14),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 105,
              height: 105,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.green),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 52),
            ),
          ),
        ],
      ),
    );
  }
}
