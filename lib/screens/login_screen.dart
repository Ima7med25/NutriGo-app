import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/backend.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'details_screen.dart';
import 'main_shell.dart';
import 'signup_screen.dart';
import 'splash_screen.dart' show DecorCircle;

/// 02 · Login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final _email =
      TextEditingController(text: AppScope.read(context).email);
  final _password = TextEditingController();
  bool _remember = true;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy) return;
    if (!_email.text.contains('@') || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Enter your email and password'))),
      );
      return;
    }
    final s = AppScope.read(context);
    setState(() => _busy = true);
    try {
      await Backend.login(s, _email.text.trim(), _password.text);
      if (mounted) _afterSignIn();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(Backend.describe(e)))),
      );
    }
  }

  /// New Google / Student ID accounts fill in their details first.
  void _afterSignIn() {
    if (Backend.needsDetails) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DetailsScreen()), (_) => false);
    } else {
      goHome(context);
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text)));

  Future<void> _google() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await Backend.googleLogin(AppScope.read(context));
      if (!mounted) return;
      setState(() => _busy = false);
      if (ok) _afterSignIn();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(tr(Backend.describe(e)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ---- Dark hero ----
            Container(
              height: 459 + top - 52,
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  const DecorCircle(left: 219, top: -98, size: 350),
                  const DecorCircle(left: -99, top: 273, size: 241),
                  Padding(
                    padding: EdgeInsets.fromLTRB(26, top + 29, 26, 0),
                    child: const _Hero(),
                  ),
                ],
              ),
            ),
            // ---- Sheet ----
            Transform.translate(
              offset: const Offset(0, -52),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: EdgeInsets.fromLTRB(
                    26, 35, 26, 20 + MediaQuery.paddingOf(context).bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('Welcome back'), style: AppText.heading(28.5)),
                    const SizedBox(height: 4),
                    Text(tr('Log in to keep tracking your swaps.'),
                        style: AppText.subtitle),
                    const SizedBox(height: 16),
                    AppTextField(
                      icon: Icons.mail_outline_rounded,
                      hint: tr('Email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      icon: Icons.lock_outline_rounded,
                      hint: tr('Password'),
                      controller: _password,
                      obscure: true,
                    ),
                    const SizedBox(height: 17),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _remember = !_remember),
                          child: Row(
                            children: [
                              CheckBox(checked: _remember),
                              const SizedBox(width: 9),
                              Text(tr('Remember me'),
                                  style: AppText.body(14.2)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(tr('Password reset link sent'))),
                          ),
                          child: Text(tr('Forgot password?'),
                              style: AppText.body(14.2,
                                  color: AppColors.greenText,
                                  weight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    PrimaryButton(
                      label: _busy ? tr('Please wait…') : tr('Log in'),
                      icon: _busy ? null : Icons.arrow_forward_rounded,
                      onPressed: _busy ? null : _login,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(tr('or continue with'),
                              style: AppText.caption.copyWith(fontSize: 13.1)),
                        ),
                        Expanded(child: Divider(color: AppColors.border)),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Center(
                      child: SizedBox(
                        width: 220,
                        child: _SocialButton(
                          leading: Text('G',
                              style: AppText.heading(18,
                                  color: const Color(0xFF4285F4))),
                          label: 'Google',
                          onTap: _google,
                        ),
                      ),
                    ),
                    const SizedBox(height: 19),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const SignUpScreen(fromLogin: true))),
                        child: Text.rich(
                          TextSpan(
                            text: tr('New to NutriGo? '),
                            children: [
                              TextSpan(
                                  text: tr('Sign up'),
                                  style: AppText.body(15.3,
                                      color: AppColors.greenText,
                                      weight: FontWeight.w700)),
                            ],
                          ),
                          style: AppText.body(15.3, color: AppColors.muted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final white70 = Colors.white.withValues(alpha: 0.7);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const LogoMark(size: 50),
            const SizedBox(width: 10),
            const BrandWordmark(size: 32, onDark: true),
          ],
        ),
        const SizedBox(height: 22),
        Text(tr('Snap a meal, see its calories,\nget a healthier swap.'),
            style: AppText.body(16.4,
                color: Colors.white.withValues(alpha: 0.85))),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(tr('1 photo\n→ 3 taps'),
                        style: AppText.heading(28.5, color: Colors.white)),
                  ),
                  const SizedBox(height: 13),
                  Text(tr('No typing. You stay in\ncontrol of every step.'),
                      style: AppText.body(13.1, color: white70)),
                  const SizedBox(height: 16),
                  const _DotGrid(),
                ],
              ),
            ),
            const _NutritionPreview(),
          ],
        ),
      ],
    );
  }
}

class _DotGrid extends StatelessWidget {
  const _DotGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Container(
            margin: const EdgeInsetsDirectional.only(end: 8),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < 3
                  ? AppColors.green
                  : Colors.white.withValues(alpha: 0.25),
            ),
          ),
      ],
    );
  }
}

/// Mini "Nutrition Facts" label card on the login hero (always light).
class _NutritionPreview extends StatelessWidget {
  const _NutritionPreview();

  @override
  Widget build(BuildContext context) {
    const ink = AppColors.inkFixed;
    Widget row(String name, String kcal, {bool strike = false}) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
                child: Text(name, style: AppText.body(11, color: ink))),
            Text(kcal,
                style: AppText.heading(24.6,
                    color: strike ? const Color(0xFF64748B) : ink)),
          ],
        );
    return Container(
      width: 195,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Nutrition Facts'),
              style: AppText.heading(15.3, color: ink, weight: FontWeight.w800)),
          const SizedBox(height: 5),
          Container(height: 3, color: ink),
          const SizedBox(height: 6),
          row(tr('Hamburger'), '650', strike: true),
          row(tr('Turkey wrap'), '290'),
          const SizedBox(height: 5),
          Container(height: 3, color: ink),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: Text(tr('You save'),
                      style: AppText.body(11, color: ink))),
              Text(tr('−{n} kcal', {'n': 360}),
                  style: AppText.body(14.2,
                      color: AppColors.green, weight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton(
      {required this.leading, required this.label, required this.onTap});
  final Widget leading;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.border, width: 1.2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(15.3, weight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

