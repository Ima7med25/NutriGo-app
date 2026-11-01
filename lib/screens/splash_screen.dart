import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/backend.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'details_screen.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'signup_screen.dart';

/// 00 · Splash / onboarding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _page = 0;

  @override
  void initState() {
    super.initState();
    // The onboarding is shown once; next time the app opens on Login.
    Backend.markOnboardingSeen();
  }

  static const _slides = [
    ('1 photo → 3 taps', 'No typing. You stay in control of every step.'),
    (
      'Lighter, same taste',
      'Every swap is scored for taste, calories and your goal.'
    ),
    (
      'See your progress',
      'Track calories saved, streaks and your weekly trend.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.navy900,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Stack(
          children: [
            const DecorCircle(left: 230, top: -88, size: 372),
            const DecorCircle(left: -208, top: 514, size: 328),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: kPagePad,
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: LanguageToggle(
                                arabic: s.arabic,
                                onDark: true,
                                onChanged: (ar) => s.update(
                                    () => s.language = ar ? 'ar' : 'en'),
                              ),
                            ),
                            const Spacer(flex: 3),
                            const LogoMark(size: 130),
                            const SizedBox(height: 18),
                            const BrandWordmark(size: 42, onDark: true),
                            const SizedBox(height: 12),
                            Text(
                              tr('Snap a meal, see its calories,\nget a healthier swap.'),
                              textAlign: TextAlign.center,
                              style: AppText.body(17.5,
                                  color: Colors.white.withValues(alpha: 0.85)),
                            ),
                            const Spacer(flex: 2),
                            const _FlowCards(),
                            const SizedBox(height: 36),
                            // Swipeable slide text.
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragEnd: (d) {
                                var v = d.primaryVelocity ?? 0;
                                if (Directionality.of(context) ==
                                    TextDirection.rtl) {
                                  v = -v;
                                }
                                if (v < -100 && _page < _slides.length - 1) {
                                  setState(() => _page++);
                                } else if (v > 100 && _page > 0) {
                                  setState(() => _page--);
                                }
                              },
                              child: SizedBox(
                                height: 92,
                                width: double.infinity,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: Column(
                                    key: ValueKey(_page),
                                    children: [
                                      Text(tr(_slides[_page].$1),
                                          textAlign: TextAlign.center,
                                          style: AppText.heading(26.3,
                                              color: Colors.white)),
                                      const SizedBox(height: 10),
                                      Text(tr(_slides[_page].$2),
                                          textAlign: TextAlign.center,
                                          style: AppText.body(14.2,
                                              color: Colors.white
                                                  .withValues(alpha: 0.7))),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _Dots(
                              count: _slides.length,
                              index: _page,
                              onTap: (i) => setState(() => _page = i),
                            ),
                            const Spacer(flex: 2),
                            PrimaryButton(
                              label: tr('Get started'),
                              icon: Icons.arrow_forward_rounded,
                              onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const SignUpScreen())),
                            ),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen())),
                              child: Text(tr('I already have an account'),
                                  style: AppText.body(16.4,
                                      color: Colors.white,
                                      weight: FontWeight.w700)),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft translucent circle used on dark hero backgrounds.
class DecorCircle extends StatelessWidget {
  const DecorCircle(
      {super.key, required this.left, required this.top, required this.size});
  final double left;
  final double top;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
    );
  }
}

class _FlowCards extends StatelessWidget {
  const _FlowCards();

  static const _steps = [
    ('Snap', '1 photo'),
    ('Confirm', 'Top-3 guess'),
    ('Adjust', 'Portion'),
    ('Swap', 'Save kcal'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 114,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: AppColors.green, shape: BoxShape.circle),
                    child: Text('${i + 1}',
                        style: AppText.heading(15.3, color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(tr(_steps[i].$1),
                        style: AppText.body(14.2,
                            color: Colors.white, weight: FontWeight.w700)),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(tr(_steps[i].$2),
                        style: AppText.body(12,
                            color: Colors.white.withValues(alpha: 0.65))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index, required this.onTap});
  final int count;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
              width: i == index ? 24 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == index
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
      ],
    );
  }
}

/// Shown on start-up when a login is saved: checks it, then opens Home
/// (or Login if the session ended). The onboarding is not shown again.
class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await Backend.restoreSession(AppScope.read(context));
      if (!mounted) return;
      final Widget next = !ok
          ? const LoginScreen()
          : (Backend.needsDetails ? const DetailsScreen() : const MainShell());
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => next), (_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy900,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LogoMark(size: 72),
              SizedBox(height: 28),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
