import 'package:flutter_test/flutter_test.dart';

import 'package:nutrigo/l10n/strings.dart';
import 'package:nutrigo/state/app_state.dart';
import 'package:nutrigo/widgets/common.dart';

void main() {
  test('daily target matches the Figma example (BMR 1,813 → 2,000 kcal)', () {
    final s = AppState();
    expect(s.bmr.round(), 1813);
    expect(s.calorieTarget, 2000);
    expect(s.proteinG, 150);
    expect(s.carbsG, 200);
    expect(s.fatG, 67);
    expect(s.consumedToday, 1240);
    expect(s.leftToday, 760);
  });

  test('number formatting', () {
    expect(fmt(1240), '1,240');
    expect(fmt(650), '650');
    expect(fmt(-1420), '−1,420');
  });

  test('arabic translations and placeholders', () {
    L10n.arabic = true;
    expect(tr('Home'), 'الرئيسية');
    expect(tr('{n} kcal', {'n': 650}), '650 سعرة');
    expect(tr('Some untranslated text'), 'Some untranslated text');
    L10n.arabic = false;
    expect(tr('{n} kcal', {'n': 650}), '650 kcal');
  });
}
