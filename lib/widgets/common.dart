import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';

/// 1240 -> "1,240"
String fmt(num n) {
  final s = n.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return n < 0 ? '−$b' : b.toString();
}

/// Horizontal page padding used across the design (22px).
const kPagePad = EdgeInsets.symmetric(horizontal: 22);

/// NutriGo apple mark (transparent PNG).
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 96});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/nutrigo_mark.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'NutriGo',
    );
  }
}

/// "NutriGo" wordmark: "Nutri" + green "Go".
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.size = 36, this.onDark = false});
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontFamily: 'Montserrat',
      fontSize: size,
      fontWeight: FontWeight.w800,
      height: 1.1,
    );
    return Text.rich(
      TextSpan(children: [
        TextSpan(
            text: 'Nutri',
            style: base.copyWith(
                color: onDark || AppColors.dark
                    ? Colors.white
                    : const Color(0xFF0E4A33))),
        TextSpan(
            text: 'Go',
            style: base.copyWith(color: const Color(0xFF5DBB2E))),
      ]),
      textDirection: TextDirection.ltr,
      semanticsLabel: 'NutriGo',
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.height = 61,
    this.color = AppColors.green,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(label,
                  style: AppText.button, overflow: TextOverflow.ellipsis),
            ),
            if (icon != null) ...[
              const SizedBox(width: 14),
              Icon(icon, color: Colors.white, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton(
      {super.key, required this.label, this.onPressed, this.height = 61});

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: BorderSide(color: AppColors.border, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label, style: AppText.body(17.5, weight: FontWeight.w700)),
      ),
    );
  }
}

/// 44×44 round back button.
class BackCircleButton extends StatelessWidget {
  const BackCircleButton({super.key, this.onDark = false, this.onTap});
  final bool onDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CircleIconButton(
      icon: Icons.chevron_left_rounded,
      onDark: onDark,
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
      semanticLabel: tr('Back'),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.onDark = false,
    this.size = 44,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool onDark;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: onDark ? Colors.white.withValues(alpha: 0.15) : AppColors.surface,
        shape: CircleBorder(
          side: onDark ? BorderSide.none : BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon,
                color: onDark ? Colors.white : AppColors.ink, size: size * 0.6),
          ),
        ),
      ),
    );
  }
}

/// Rounded card with a hairline border (surface color by default).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(17),
    this.radius = 18,
    this.color,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor ?? AppColors.border),
    );
    return Material(
      color: color ?? AppColors.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Text input styled like the Figma "Input" component (57px, icon prefix).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.icon,
    required this.hint,
    this.controller,
    this.obscure = false,
    this.keyboardType,
    this.onChanged,
    this.textInputAction,
  });

  final IconData icon;
  final String hint;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      controller: widget.controller,
      obscureText: _hidden,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      style: AppText.body(16.4),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppText.body(16.4, color: AppColors.muted),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 17),
        prefixIcon: Icon(widget.icon, color: AppColors.muted, size: 20),
        suffixIcon: widget.obscure
            ? IconButton(
                tooltip: _hidden ? tr('Show password') : tr('Hide password'),
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.muted,
                  size: 20,
                ),
              )
            : null,
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.green, 1.6),
        border: border(AppColors.border),
      ),
    );
  }
}

/// Pill chip used for goals / activity level.
class SelectChip extends StatelessWidget {
  const SelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.height = 37,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.green : AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(
              color: selected ? AppColors.green : AppColors.border, width: 1.2),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppText.body(14.2,
                  weight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.ink),
            ),
          ),
        ),
      ),
    );
  }
}

/// "1 · Snap  2 · Confirm  3 · Adjust  4 · Swap" progress bar.
class FlowSteps extends StatelessWidget {
  const FlowSteps({super.key, required this.current, this.onDark = false});
  final int current; // 1..4
  final bool onDark;

  static const _labels = ['Snap', 'Confirm', 'Adjust', 'Swap'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < current
                        ? AppColors.green
                        : (onDark
                            ? Colors.white.withValues(alpha: 0.25)
                            : AppColors.track),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${i + 1} · ${tr(_labels[i])}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(12,
                      weight:
                          i + 1 == current ? FontWeight.w700 : FontWeight.w400,
                      color: onDark
                          ? Colors.white
                              .withValues(alpha: i + 1 == current ? 1 : 0.7)
                          : (i + 1 == current
                              ? AppColors.ink
                              : AppColors.muted)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Card with label, big value and −/+ buttons (Daily target, Age).
class StepperCard extends StatelessWidget {
  const StepperCard({
    super.key,
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.valueSize = 19.7,
  });

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(17, 12, 17, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.label),
                const SizedBox(height: 3),
                Text(value, style: AppText.heading(valueSize)),
              ],
            ),
          ),
          _RoundStep(
              icon: Icons.remove_rounded, onTap: onMinus, label: tr('Decrease')),
          const SizedBox(width: 8),
          _RoundStep(
              icon: Icons.add_rounded,
              onTap: onPlus,
              filled: true,
              label: tr('Increase')),
        ],
      ),
    );
  }
}

class _RoundStep extends StatelessWidget {
  const _RoundStep(
      {required this.icon,
      required this.onTap,
      required this.label,
      this.filled = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: filled ? AppColors.green : AppColors.greenTint,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 35,
            height: 35,
            child: Icon(icon,
                size: 18, color: filled ? Colors.white : AppColors.greenText),
          ),
        ),
      ),
    );
  }
}

/// Row used in "Recent meals" and History.
class MealTile extends StatelessWidget {
  const MealTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.kcal,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final int kcal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      radius: 16,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.greenTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.restaurant_rounded,
                color: AppColors.greenText, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppText.body(15.3, weight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppText.body(13.1, color: AppColors.muted)),
              ],
            ),
          ),
          Text(fmt(kcal), style: AppText.heading(16.4)),
          const SizedBox(width: 6),
          Text(tr('kcal'), style: AppText.caption),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// Section title with optional trailing link.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
      {super.key, required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Text(title, style: AppText.sectionTitle)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!,
                style: AppText.body(14.2,
                    color: AppColors.greenText, weight: FontWeight.w700)),
          ),
      ],
    );
  }
}

/// Small rounded tag (e.g. "−300 kcal", "TOP PICK", "Auto").
class Tag extends StatelessWidget {
  const Tag({
    super.key,
    required this.text,
    this.color,
    this.background,
    this.icon,
    this.fontSize = 13.1,
  });

  final String text;
  final Color? color;
  final Color? background;
  final IconData? icon;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.greenText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? AppColors.greenTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 6),
          ],
          Text(text,
              style: AppText.body(fontSize, color: fg, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Rounded linear progress bar.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.height = 9,
    this.color = AppColors.green,
    this.track,
  });

  final double value;
  final double height;
  final Color color;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        color: color,
        backgroundColor: track ?? AppColors.track,
      ),
    );
  }
}

/// Meal picture: the user's photo when there is one, otherwise a
/// stylised illustration.
class MealIllustration extends StatelessWidget {
  const MealIllustration({super.key, this.size = 220, this.photoPath});
  final double size;
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    if (path != null) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black26, blurRadius: 24, offset: Offset(0, 10)),
          ],
        ),
        child: ClipOval(
          child: Image.file(
            File(path),
            width: size,
            height: size,
            fit: BoxFit.cover,
            cacheWidth: (size * 3).round(),
            errorBuilder: (_, _, _) => _placeholder(),
          ),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0xFFFFE0B2), Color(0xFFFFB74D)],
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black26, blurRadius: 24, offset: Offset(0, 10)),
          ],
        ),
        child: Center(
          child: Container(
            width: size * 0.8,
            height: size * 0.8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(Icons.lunch_dining_rounded,
                size: size * 0.5, color: const Color(0xFF8D4E1F)),
          ),
        ),
      );
}

/// Green check box.
class CheckBox extends StatelessWidget {
  const CheckBox({super.key, required this.checked, this.size = 20});
  final bool checked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: checked ? AppColors.green : AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: checked ? AppColors.green : AppColors.border, width: 1.5),
      ),
      child: checked
          ? Icon(Icons.check_rounded, color: Colors.white, size: size * 0.7)
          : null,
    );
  }
}

/// Compact "EN | ع" language switch.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle(
      {super.key, required this.arabic, required this.onChanged, this.onDark = false});
  final bool arabic;
  final ValueChanged<bool> onChanged;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : AppColors.ink;
    Widget opt(String t, bool ar) {
      final sel = ar == arabic;
      return GestureDetector(
        onTap: () => onChanged(ar),
        child: Container(
          height: 30,
          constraints: const BoxConstraints(minWidth: 38),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: sel ? AppColors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(t,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : fg)),
        ),
      );
    }

    return Semantics(
      label: 'Language',
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: onDark ? Colors.white.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: onDark ? null : Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr,
          children: [opt('EN', false), opt('ع', true)],
        ),
      ),
    );
  }
}
