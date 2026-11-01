import 'package:flutter/widgets.dart';

import '../data/foods.dart';

enum Gender { male, female }

enum ActivityLevel {
  sedentary('Sedentary', 1.2),
  lightlyActive('Lightly active', 1.375),
  veryActive('Very active', 1.725);

  const ActivityLevel(this.label, this.factor);
  final String label;
  final double factor;
}

enum Goal {
  loseWeight('Lose weight'),
  balanced('Balanced'),
  highProtein('High protein'),
  lowCarb('Low carb'),
  vegetarian('Vegetarian');

  const Goal(this.label);
  final String label;

  /// Name used by the NutriGo API.
  String get apiName => switch (this) {
        Goal.loseWeight => 'lose_weight',
        Goal.balanced => 'balanced',
        Goal.highProtein => 'high_protein',
        Goal.lowCarb => 'low_carb',
        Goal.vegetarian => 'vegetarian',
      };
}

class LoggedMeal {
  LoggedMeal({
    this.id,
    required this.name,
    required this.kcal,
    required this.slot,
    required this.time,
    required this.date,
    this.savedKcal = 0,
    this.foodId,
    this.swappedFrom,
  });

  /// Server id once saved (null while it is being sent).
  int? id;
  final String name;
  final int kcal;
  final String slot; // Breakfast / Lunch / Dinner / Snack
  final String time; // "12:30"
  final DateTime date; // the day it was eaten (no time part)
  final int savedKcal; // > 0 when this meal was a swap
  final String? foodId; // server food_id (for swaps of the day)
  final String? swappedFrom; // name of the dish it replaced

  bool get swapped => savedKcal > 0;
}

/// Simple in-memory app state shared through [AppScope].
class AppState extends ChangeNotifier {
  // ---- Profile ----
  // Starting values of the sign-up form; replaced by the account's real profile.
  String name = '';
  String email = '';
  String? studentId;
  Gender gender = Gender.male;
  int age = 21;
  int weightKg = 80;
  int heightCm = 178;
  int goalWeightKg = 75;

  /// First weight recorded on the account (for the goal progress bar).
  int? startWeightKg;

  /// Kilograms moved towards the goal since the first recorded weight.
  double get progressKg {
    final start = startWeightKg ?? weightKg;
    final done = goalWeightKg < start ? start - weightKg : weightKg - start;
    return done < 0 ? 0.0 : done.toDouble();
  }

  /// Total kilograms between the first weight and the goal.
  int get goalTotalKg => ((startWeightKg ?? weightKg) - goalWeightKg).abs();
  ActivityLevel activity = ActivityLevel.lightlyActive;
  Goal goal = Goal.loseWeight;
  Set<Goal> dietPrefs = {Goal.loseWeight};
  bool autoTarget = true;
  int _manualTarget = 2000;
  bool darkMode = false;

  /// 'en' or 'ar'.
  String language = 'en';
  bool get arabic => language == 'ar';

  String get firstName => name.trim().isEmpty ? '' : name.trim().split(' ').first;
  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

  // ---- Calorie maths (Mifflin–St Jeor) ----
  double get bmr {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return gender == Gender.male ? base + 5 : base - 161;
  }

  int get goalAdjustment {
    if (goalWeightKg < weightKg) return -500;
    if (goalWeightKg > weightKg) return 300;
    return 0;
  }

  int get autoTargetKcal {
    final raw = bmr * activity.factor + goalAdjustment;
    return ((raw / 50).round() * 50).clamp(1200, 4000);
  }

  int get calorieTarget => autoTarget ? autoTargetKcal : _manualTarget;

  set calorieTarget(int v) {
    autoTarget = false;
    _manualTarget = v.clamp(1200, 4000);
    notifyListeners();
  }

  int get proteinG => (calorieTarget * 0.30 / 4).round();
  int get carbsG => (calorieTarget * 0.40 / 4).round();
  int get fatG => (calorieTarget * 0.30 / 9).round();

  // ---- Meals (real: logged by the user, loaded from the server) ----

  /// Every logged meal, newest first.
  final List<LoggedMeal> meals = [];

  /// Called after a meal is logged on the phone (Backend saves it on the server).
  void Function(LoggedMeal meal)? onMealLogged;

  static DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);
  DateTime get _today => dayOf(DateTime.now());

  List<LoggedMeal> mealsOn(DateTime day) =>
      meals.where((m) => m.date == dayOf(day)).toList();

  List<LoggedMeal> get today => mealsOn(_today);
  List<LoggedMeal> get yesterday =>
      mealsOn(_today.subtract(const Duration(days: 1)));

  int kcalOn(DateTime day) => mealsOn(day).fold(0, (s, m) => s + m.kcal);
  int savedOn(DateTime day) => mealsOn(day).fold(0, (s, m) => s + m.savedKcal);

  int get consumedToday => kcalOn(_today);
  int get savedToday => savedOn(_today);
  int get swapsToday => today.where((m) => m.swapped).length;
  int get leftToday => (calorieTarget - consumedToday).clamp(0, 99999);
  double get progressToday =>
      (consumedToday / calorieTarget).clamp(0.0, 1.0).toDouble();

  int get yesterdayKcal => kcalOn(_today.subtract(const Duration(days: 1)));
  int get yesterdaySaved => savedOn(_today.subtract(const Duration(days: 1)));

  /// The last 7 days, oldest first (the last one is today).
  List<DateTime> get weekDays =>
      [for (var i = 6; i >= 0; i--) _today.subtract(Duration(days: i))];

  List<int> get weekKcal => [for (final d in weekDays) kcalOn(d)];
  int get weekSaved => weekDays.fold(0, (s, d) => s + savedOn(d));

  /// Daily average of the last 4 weeks (7-day blocks), oldest first.
  List<int> get monthDailyAvg => [
        for (var w = 3; w >= 0; w--)
          [
            for (var i = 0; i < 7; i++)
              kcalOn(_today.subtract(Duration(days: w * 7 + i)))
          ].fold(0, (a, b) => a + b) ~/
              7
      ];
  int get monthSaved => [
        for (var i = 0; i < 28; i++) savedOn(_today.subtract(Duration(days: i)))
      ].fold(0, (a, b) => a + b);

  /// Days in a row (up to today, or yesterday if nothing yet today) with a logged meal.
  int get streakDays {
    var day = today.isEmpty ? _today.subtract(const Duration(days: 1)) : _today;
    var n = 0;
    while (mealsOn(day).isNotEmpty) {
      n++;
      day = day.subtract(const Duration(days: 1));
    }
    return n;
  }

  void setMeals(List<LoggedMeal> list) {
    meals
      ..clear()
      ..addAll(list);
    notifyListeners();
  }

  void removeMeal(LoggedMeal m) {
    meals.remove(m);
    notifyListeners();
  }

  /// Logout: forget the account's data on this phone.
  void reset() {
    meals.clear();
    name = '';
    email = '';
    studentId = null;
    startWeightKg = null;
    currentFood = null;
    photoPath = null;
    guesses = [];
    notifyListeners();
  }

  // ---- Snap → Confirm → Adjust → Swap flow ----
  Food? currentFood;
  double portion = 1.0;

  /// Path of the photo taken / picked for the current meal (null when the
  /// food was picked from the list).
  String? photoPath;

  /// Top-3 guesses from the server for [photoPath]: (food, confidence 0-1).
  List<(Food, double)> guesses = [];
  bool lowConfidence = false;

  double? confidenceFor(Food food) {
    for (final g in guesses) {
      if (g.$1.name == food.name) return g.$2;
    }
    return null;
  }

  void setGuesses(List<(Food, double)> g, {bool low = false}) {
    guesses = g;
    lowConfidence = low;
    notifyListeners();
  }

  int get currentKcal =>
      currentFood == null ? 0 : (currentFood!.kcal * portion).round();

  void startMeal(Food food, {String? photo, bool keepPhoto = false}) {
    currentFood = food;
    portion = 1.0;
    if (!keepPhoto) photoPath = photo;
    notifyListeners();
  }

  void setPhoto(String? path) {
    photoPath = path;
    guesses = [];
    lowConfidence = false;
    notifyListeners();
  }

  void setPortion(double p) {
    portion = p;
    notifyListeners();
  }

  String get _slotForNow {
    final h = DateTime.now().hour;
    if (h < 11) return 'Breakfast';
    if (h < 16) return 'Lunch';
    if (h < 18) return 'Snack';
    return 'Dinner';
  }

  String get _timeNow {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  void _add(LoggedMeal meal) {
    meals.insert(0, meal);
    notifyListeners();
    onMealLogged?.call(meal);
  }

  /// Logs a swap; returns the logged meal.
  LoggedMeal logSwap(SwapOption swap) {
    final saved = (currentKcal - swap.kcal).clamp(0, 99999);
    final meal = LoggedMeal(
      name: swap.name,
      kcal: swap.kcal,
      slot: _slotForNow,
      time: _timeNow,
      date: _today,
      savedKcal: saved,
      foodId: swap.id,
      swappedFrom: currentFood?.name,
    );
    _add(meal);
    return meal;
  }

  void logOriginal() {
    final f = currentFood;
    if (f == null) return;
    _add(LoggedMeal(
      name: f.name,
      kcal: currentKcal,
      slot: _slotForNow,
      time: _timeNow,
      date: _today,
      foodId: f.id,
    ));
  }

  // ---- Profile setters ----
  void update(VoidCallback change) {
    change();
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
