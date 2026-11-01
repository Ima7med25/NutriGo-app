import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../services/backend.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'main_shell.dart';
import 'login_screen.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
 
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
 
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
 
class _ProfileScreenState extends State<ProfileScreen> {
  static const _languages = {'en': 'English', 'ar': 'العربية'};
 
  File? _avatarImage;
 
  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        imageQuality: 80,
      );
      if (picked == null || !mounted) return;
      setState(() => _avatarImage = File(picked.path));
      if (Backend.signedIn) {
        unawaited(Backend.client.setAvatar(File(picked.path)).then((_) {}, onError: (_) {}));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Could not open gallery'))),
      );
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final start = s.startWeightKg ?? s.weightKg;
    final goalKg = s.goalTotalKg;
    final goalTitle = s.goalWeightKg < start
        ? tr('Lose {n} kg', {'n': goalKg})
        : (s.goalWeightKg > start
            ? tr('Gain {n} kg', {'n': goalKg})
            : tr('Maintain weight'));
    final done = s.progressKg;
    final progress = goalKg == 0 ? 1.0 : (done / goalKg).clamp(0.0, 1.0);
    final doneText = done == done.roundToDouble()
        ? '${done.toInt()}'
        : done.toStringAsFixed(1);
 
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: kPagePad.copyWith(top: 40, bottom: kTabBarClearance),
        children: [
          Text(tr('Profile'), style: AppText.screenTitle),
          const SizedBox(height: 20),
          // ---- User ----
          AppCard(
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 33,
                        backgroundColor: AppColors.green,
                        backgroundImage: _avatarImage != null
                            ? FileImage(_avatarImage!)
                            : null,
                        child: _avatarImage == null
                            ? Text(s.initial,
                                style:
                                    AppText.heading(24, color: Colors.white))
                            : null,
                      ),
                      // أيقونة كاميرا صغيرة توضح إن الصورة قابلة للتغيير
                      PositionedDirectional(
                        end: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 13, color: AppColors.green),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: AppText.heading(20.5)),
                      const SizedBox(height: 3),
                      Text(
                          s.studentId != null
                              ? tr('{age} · Student ID {id}',
                                  {'age': s.age, 'id': s.studentId!})
                              : (s.email.isEmpty
                                  ? tr('{age} years', {'age': s.age})
                                  : '${s.age} · ${s.email}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(14.2, color: AppColors.muted)),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _editName(context, s),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border),
                    shape: const StadiumBorder(),
                    minimumSize: const Size(57, 33),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text(tr('Edit'),
                      style: AppText.body(14.2, weight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          // ---- Goal ----
          AppCard(
            padding: const EdgeInsets.fromLTRB(17, 20, 17, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('MY GOAL'), style: AppText.overline),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                        child: Text(goalTitle, style: AppText.heading(26))),
                    Text('$doneText / $goalKg ${tr('kg')}',
                        style: AppText.body(15.3,
                            color: AppColors.greenText,
                            weight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                ProgressBar(value: progress),
                const SizedBox(height: 15),
                Text(
                    tr('Daily target {n} kcal · {goal} swaps', {
                      'n': fmt(s.calorieTarget),
                      'goal': tr(s.goal.label),
                    }),
                    style: AppText.body(13.1, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Text(tr('PREFERENCES'),
              style: AppText.overline.copyWith(fontSize: 13.1)),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 4),
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.track_changes_rounded,
                  title: tr('Goal preference'),
                  value: tr(s.goal.label),
                  onTap: () => _pickGoal(context, s),
                ),
                const _Sep(),
                _SettingRow(
                  icon: Icons.local_fire_department_rounded,
                  title: tr('Daily calorie target'),
                  value: tr('{n} kcal', {'n': fmt(s.calorieTarget)}),
                  onTap: () => _editTarget(context, s),
                ),
                const _Sep(),
                _SettingRow(
                  icon: Icons.language_rounded,
                  title: tr('Language'),
                  value: _languages[s.language] ?? s.language,
                  onTap: () => _pickLanguage(context, s),
                ),
                const _Sep(),
                // _SettingRow(
                //   icon: Icons.dns_outlined,
                //   title: tr('Server'),
                //   value: Backend.baseUrl.replaceFirst('http://', ''),
                //   onTap: () => _editServer(context),
                // ),
                // const _Sep(),
                _SettingRow(
                  icon: Icons.dark_mode_outlined,
                  title: tr('Dark mode'),
                  onTap: () => s.update(() => s.darkMode = !s.darkMode),
                  trailing: Switch(
                    value: s.darkMode,
                    activeTrackColor: AppColors.green,
                    onChanged: (v) => s.update(() => s.darkMode = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            onTap: () async {
              await Backend.logout(s);
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: Row(
              children: [
                const Icon(Icons.logout_rounded,
                    color: AppColors.red, size: 18),
                const SizedBox(width: 16),
                Text(tr('Log out'),
                    style: AppText.body(15.3,
                        color: AppColors.red, weight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  /// Address of the laptop that runs the NutriGo backend.
  Future<void> _editServer(BuildContext context) async {
    final c = TextEditingController(text: Backend.baseUrl);
    String? status;
    bool testing = false;
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(tr('Server'), style: AppText.sectionTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: c,
                autofocus: true,
                keyboardType: TextInputType.url,
                style: AppText.body(15.3),
                decoration:
                    const InputDecoration(hintText: 'http://192.168.1.20:5000'),
              ),
              const SizedBox(height: 8),
              Text(
                  tr('IP of the laptop running the backend (ipconfig → IPv4). Emulator on the same PC: 10.0.2.2'),
                  style: AppText.body(12, color: AppColors.muted)),
              if (testing || status != null) ...[
                const SizedBox(height: 10),
                Text(testing ? tr('Testing…') : status!,
                    style: AppText.body(13.1, weight: FontWeight.w600)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: testing
                  ? null
                  : () async {
                      setD(() {
                        testing = true;
                        status = null;
                      });
                      final err = await Backend.check(c.text);
                      setD(() {
                        testing = false;
                        status = err == null ? tr('Connected ✓') : tr(err);
                      });
                    },
              child: Text(tr('Test')),
            ),
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr('Cancel'))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, c.text),
                child: Text(tr('Save'))),
          ],
        ),
      ),
    );
    if (saved == null) return;
    await Backend.setUrl(saved);
    if (mounted) setState(() {});
  }

  Future<void> _editName(BuildContext context, AppState s) async {
    final c = TextEditingController(text: s.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Edit name'), style: AppText.sectionTitle),
        content: TextField(
            controller: c, autofocus: true, style: AppText.body(16.4)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(tr('Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: Text(tr('Save'))),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      s.update(() => s.name = name);
      unawaited(Backend.syncProfile(s));
    }
  }
 
  void _pickGoal(BuildContext context, AppState s) {
    _sheet(context, tr('Goal preference'), [
      for (final g in Goal.values)
        (tr(g.label), s.goal == g, () {
          s.update(() => s.goal = g);
          unawaited(Backend.syncProfile(s));
        }),
    ]);
  }
 
  void _pickLanguage(BuildContext context, AppState s) {
    _sheet(context, tr('Language'), [
      for (final e in _languages.entries)
        (e.value, s.language == e.key, () => s.update(() => s.language = e.key)),
    ]);
  }
 
  void _sheet(BuildContext context, String title,
      List<(String, bool, VoidCallback)> options) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: kPagePad.copyWith(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.sectionTitle),
              const SizedBox(height: 8),
              for (final o in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(o.$1, style: AppText.body(15.3)),
                  trailing: o.$2
                      ? const Icon(Icons.check_rounded, color: AppColors.green)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    o.$3();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
 
  void _editTarget(BuildContext context, AppState s) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListenableBuilder(
        listenable: s,
        builder: (ctx, _) => SafeArea(
          child: Padding(
            padding: kPagePad.copyWith(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Daily calorie target'), style: AppText.sectionTitle),
                const SizedBox(height: 14),
                StepperCard(
                  label: s.autoTarget
                      ? tr('Calculated for you')
                      : tr('Custom target'),
                  value: tr('{n} kcal', {'n': fmt(s.calorieTarget)}),
                  onMinus: () => s.calorieTarget = s.calorieTarget - 50,
                  onPlus: () => s.calorieTarget = s.calorieTarget + 50,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => s.update(() => s.autoTarget = true),
                  child: Text(
                      tr('Reset to automatic ({n} kcal)',
                          {'n': fmt(s.autoTargetKcal)}),
                      style: AppText.body(14.2,
                          color: AppColors.greenText,
                          weight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 49),
        child: Divider(height: 1, thickness: 1, color: AppColors.border),
      );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: AppColors.greenTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.greenText),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: AppText.body(15.3, weight: FontWeight.w600)),
            ),
            if (value != null) ...[
              Text(value!, style: AppText.body(14.2, color: AppColors.muted)),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.muted, size: 20),
            ],
            ?trailing,
          ],
        ),
      ),
    );
  }
}
