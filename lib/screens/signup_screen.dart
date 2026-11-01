import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'details_screen.dart';
import 'login_screen.dart';

/// 01 · Sign up.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.fromLogin = false});

  /// Opened from the Login page: "Log in" and Back just go back to it.
  final bool fromLogin;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _agreed = true;
  final Set<Goal> _goals = {Goal.loseWeight};
  int _target = 2000;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// 0..4
  int get _strength {
    final p = _password.text;
    var s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'\d').hasMatch(p)) s++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p) || p.length >= 12) s++;
    return s;
  }

  String get _strengthLabel => tr(switch (_strength) {
        0 => 'Too short',
        1 => 'Weak password',
        2 => 'Okay password',
        3 => 'Good password',
        _ => 'Strong password',
      });

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _email.text.contains('@') &&
      _password.text.length >= 8 &&
      _agreed;

  void _submit() {
    final s = AppScope.read(context);
    s.update(() {
      s.name = _name.text.trim();
      s.email = _email.text.trim();
      s.dietPrefs = {..._goals};
      if (_goals.isNotEmpty) s.goal = _goals.first;
    });
    if (_target != s.calorieTarget) s.calorieTarget = _target;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DetailsScreen(password: _password.text)));
  }

  /// Back: the page before (Login or the onboarding); if there is none, Login.
  void _back(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = _strength;
    final strengthColor = strength >= 3
        ? AppColors.green
        : (strength == 2 ? AppColors.orange : AppColors.red);
    final link = AppText.body(14.2,
        color: AppColors.greenText, weight: FontWeight.w700);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: kPagePad.copyWith(top: 16, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackCircleButton(onTap: () => _back(context)),
              const SizedBox(height: 32),
              Text(tr('Create account'), style: AppText.screenTitle),
              const SizedBox(height: 6),
              Text(tr('Start swapping in under a minute.'),
                  style: AppText.subtitle),
              const SizedBox(height: 21),
              AppTextField(
                icon: Icons.person_outline_rounded,
                hint: tr('Full name'),
                controller: _name,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 15),
              AppTextField(
                icon: Icons.mail_outline_rounded,
                hint: tr('Email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 15),
              AppTextField(
                icon: Icons.lock_outline_rounded,
                hint: tr('Password'),
                controller: _password,
                obscure: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 7),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: i < strength ? strengthColor : AppColors.track,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Text(_strengthLabel,
                      style: AppText.body(13.1,
                          color: _password.text.isEmpty
                              ? AppColors.muted
                              : strengthColor,
                          weight: FontWeight.w700)),
                  const Spacer(),
                  Text(tr('8+ chars · 1 number'),
                      style: AppText.body(13.1, color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 24),
              Text(tr("What's your goal?"),
                  style: AppText.body(17.5, weight: FontWeight.w700)),
              const SizedBox(height: 9),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (final g in Goal.values)
                    SelectChip(
                      label: tr(g.label),
                      selected: _goals.contains(g),
                      onTap: () => setState(() {
                        _goals.contains(g) ? _goals.remove(g) : _goals.add(g);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              StepperCard(
                label: tr('Daily calorie target'),
                value: tr('{n} kcal', {'n': fmt(_target)}),
                onMinus: () =>
                    setState(() => _target = (_target - 50).clamp(1200, 4000)),
                onPlus: () =>
                    setState(() => _target = (_target + 50).clamp(1200, 4000)),
              ),
              const SizedBox(height: 22),
              InkWell(
                onTap: () => setState(() => _agreed = !_agreed),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    CheckBox(checked: _agreed, size: 22),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: tr('I agree to the '),
                          children: [
                            TextSpan(text: tr('Terms'), style: link),
                            TextSpan(text: tr(' and ')),
                            TextSpan(text: tr('Privacy Policy'), style: link),
                          ],
                        ),
                        style: AppText.body(14.2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 31),
              PrimaryButton(
                label: tr('Create account'),
                icon: Icons.arrow_forward_rounded,
                onPressed: _valid ? _submit : null,
              ),
              const SizedBox(height: 22),
              Center(
                child: GestureDetector(
                  onTap: () => widget.fromLogin
                      ? Navigator.of(context).pop()
                      : Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (_) => const LoginScreen())),
                  child: Text.rich(
                    TextSpan(
                      text: tr('Already have an account? '),
                      children: [
                        TextSpan(
                            text: tr('Log in'),
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
    );
  }
}
