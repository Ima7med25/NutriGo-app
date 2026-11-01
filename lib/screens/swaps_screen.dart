import 'package:flutter/material.dart';

import '../data/foods.dart';
import '../l10n/strings.dart';
import '../services/backend.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'main_shell.dart';
import 'swap_logged_screen.dart';

/// 07 · Lighter swaps. Also used as the "Swaps" tab ([asTab] = true).
class SwapsScreen extends StatefulWidget {
  const SwapsScreen({super.key, this.asTab = false});
  final bool asTab;

  @override
  State<SwapsScreen> createState() => _SwapsScreenState();
}

class _SwapsScreenState extends State<SwapsScreen> {
  int _selected = 0;

  // Swaps from the NutriGo server (for foods that have a server id).
  String? _requestKey;
  List<SwapOption>? _remote;
  String? _message;
  String? _error;
  bool _loading = false;

  /// Asks the server again whenever the food, portion or goal changes.
  void _maybeFetch(AppState s, Food food) {
    final id = food.id;
    if (id == null) return;
    final key = '$id|${s.portion}|${s.goal.apiName}';
    if (key == _requestKey) return;
    _requestKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch(s, food, key));
  }

  Future<void> _fetch(AppState s, Food food, String key) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await Backend.recommend(food, s.portion, s.goal);
      if (!mounted || key != _requestKey) return;
      setState(() {
        _remote = r.swaps;
        _message = r.message;
        _loading = false;
        _selected = 0;
      });
    } catch (e) {
      if (!mounted || key != _requestKey) return;
      setState(() {
        _remote = const [];
        _error = tr(Backend.describe(e));
        _loading = false;
      });
    }
  }

  void _choose(AppState s, Food food, SwapOption swap) {
    if (s.currentFood == null) s.startMeal(food);
    final original = s.currentKcal;
    final meal = s.logSwap(swap);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SwapLoggedScreen(
          meal: meal, originalName: food.name, originalKcal: original),
    ));
  }

  void _keep(AppState s, Food food) {
    if (s.currentFood == null) s.startMeal(food);
    s.logOriginal();
    if (widget.asTab) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('{name} logged', {'name': tr(food.name)}))));
    } else {
      goHome(context);
    }
  }

  void _howItWorks() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('How swaps are scored'), style: AppText.sectionTitle),
        content: Text(
          tr('Each swap gets a score out of 100 based on calories saved, how similar it tastes, its category, and how well it fits your goal. The highest score is marked TOP PICK.'),
          style: AppText.body(14.2),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(tr('Got it'))),
        ],
      ),
    );
  }

  /// No meal picked yet: ask the user to snap one.
  Widget _empty(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: kPagePad.copyWith(
              top: 16, bottom: widget.asTab ? kTabBarClearance : 16),
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  if (!widget.asTab)
                    const BackCircleButton()
                  else
                    const SizedBox(width: 44),
                  Expanded(
                    child: Text(tr('Lighter swaps'),
                        textAlign: TextAlign.center, style: AppText.barTitle),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Icon(Icons.swap_horiz_rounded,
                size: 56, color: AppColors.green),
            const SizedBox(height: 14),
            Text(tr('No meal yet'),
                textAlign: TextAlign.center, style: AppText.sectionTitle),
            const SizedBox(height: 6),
            Text(
                tr('Snap a meal and we will show you lighter swaps for it.'),
                textAlign: TextAlign.center,
                style: AppText.body(14.2, color: AppColors.muted)),
            const SizedBox(height: 24),
            PrimaryButton(
              label: tr('Snap a meal'),
              icon: Icons.camera_alt_rounded,
              onPressed: () => openSnap(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final picked = s.currentFood;
    if (picked == null) return _empty(context);
    final food = picked;
    final baseKcal = s.currentKcal;
    _maybeFetch(s, food);
    // Server swaps are already ranked; the built-in demo ones are sorted by score.
    final swaps = food.id != null
        ? (_remote ?? const <SwapOption>[])
        : ([...food.swaps]..sort((a, b) => b.score.compareTo(a.score)));
    if (_selected >= swaps.length) _selected = 0;

    final actions = _BottomActions(
      chooseLabel: _selected == 0 ? tr('Choose top pick') : tr('Choose this swap'),
      onKeep: () => _keep(s, food),
      onChoose:
          swaps.isEmpty ? null : () => _choose(s, food, swaps[_selected]),
    );

    final list = ListView(
      padding: kPagePad.copyWith(
          top: 20, bottom: widget.asTab ? kTabBarClearance : 16),
      children: [
        // ---- You picked ----
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('YOU PICKED'), style: AppText.overline),
                    const SizedBox(height: 4),
                    Text(
                        '${tr(food.name)} · ${tr('{n} kcal', {'n': fmt(baseKcal)})}',
                        style: AppText.body(16.4, weight: FontWeight.w700)),
                  ],
                ),
              ),
              Tag(
                text: tr('Goal: {g}', {'g': tr(s.goal.label)}),
                color: AppColors.dark
                    ? const Color(0xFF90CAF9)
                    : AppColors.navy700,
                background: AppColors.blueTint,
              ),
            ],
          ),
        ),
        const SizedBox(height: 19),
        Row(
          children: [
            Expanded(
              child: Text(
                  tr('{n} swaps · ranked by score', {'n': swaps.length}),
                  style: AppText.body(16.4, weight: FontWeight.w700)),
            ),
            InkWell(
              onTap: _howItWorks,
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 15, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Text(tr('How it works'),
                      style: AppText.body(13.1, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: CircularProgressIndicator(color: AppColors.green)),
          ),
        if (!_loading && _error != null)
          AppCard(
            borderColor: AppColors.orange,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_error!, style: AppText.body(14.2, weight: FontWeight.w600)),
                TextButton(
                  onPressed: () {
                    _requestKey = null;
                    setState(() {});
                  },
                  child: Text(tr('Try again'),
                      style: AppText.body(14.2,
                          color: AppColors.greenText, weight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        if (!_loading && _error == null && swaps.isEmpty && _message != null)
          AppCard(
            child: Text(tr(_message!), style: AppText.body(14.2)),
          ),
        if (!_loading)
        for (var i = 0; i < swaps.length; i++) ...[
          _SwapCard(
            swap: swaps[i],
            saved: baseKcal - swaps[i].kcal,
            topPick: i == 0,
            selected: i == _selected,
            onTap: () => setState(() => _selected = i),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.asTab) ...[const SizedBox(height: 8), actions],
      ],
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: kPagePad.copyWith(top: 16),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    if (!widget.asTab)
                      const BackCircleButton()
                    else
                      const SizedBox(width: 44),
                    Expanded(
                      child: Text(tr('Lighter swaps'),
                          textAlign: TextAlign.center,
                          style: AppText.barTitle),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
            ),
            if (!widget.asTab)
              Padding(
                padding: kPagePad.copyWith(top: 17),
                child: const FlowSteps(current: 4),
              ),
            Expanded(child: list),
            if (!widget.asTab)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                padding: EdgeInsets.fromLTRB(
                    22, 18, 22, 18 + MediaQuery.paddingOf(context).bottom),
                child: actions,
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions(
      {required this.chooseLabel, required this.onKeep, required this.onChoose});
  final String chooseLabel;
  final VoidCallback onKeep;
  final VoidCallback? onChoose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 142,
          child: SecondaryButton(
              label: tr('Keep meal'), onPressed: onKeep, height: 59),
        ),
        const SizedBox(width: 13),
        Expanded(
          flex: 241,
          child: PrimaryButton(
            label: chooseLabel,
            icon: Icons.check_rounded,
            height: 59,
            onPressed: onChoose,
          ),
        ),
      ],
    );
  }
}

class _SwapCard extends StatelessWidget {
  const _SwapCard({
    required this.swap,
    required this.saved,
    required this.topPick,
    required this.selected,
    required this.onTap,
  });

  final SwapOption swap;
  final int saved;
  final bool topPick;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: AppCard(
        onTap: onTap,
        borderColor: selected ? AppColors.green : AppColors.border,
        color: selected ? AppColors.selectedCard : AppColors.surface,
        padding: const EdgeInsets.fromLTRB(17, 16, 17, 14),
        child: Row(
          children: [
            if (swap.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  swap.imageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const SizedBox(width: 56, height: 56),
                ),
              ),
              const SizedBox(width: 13),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(swap.name),
                      style: AppText.body(16.4, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(tr(swap.reason),
                      style: AppText.body(13.1, color: AppColors.muted)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 9,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(tr('{n} kcal', {'n': swap.kcal}),
                          style: AppText.heading(19.7)),
                      Tag(
                          text: saved >= 0
                              ? tr('−{n} kcal', {'n': saved})
                              : tr('+{n} kcal', {'n': -saved})),
                      if (topPick)
                        Tag(
                          text: tr('TOP PICK'),
                          fontSize: 11,
                          color: Colors.white,
                          background: AppColors.green,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _ScoreBadge(score: swap.score),
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 70
        ? AppColors.green
        : (score >= 60 ? const Color(0xFF7CB342) : AppColors.orange);
    return Column(
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 4,
                color: color,
                backgroundColor: AppColors.track,
              ),
              Center(child: Text('$score', style: AppText.heading(16.4))),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(tr('score'), style: AppText.body(11, color: AppColors.muted)),
      ],
    );
  }
}
