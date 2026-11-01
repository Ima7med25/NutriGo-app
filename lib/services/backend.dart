import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/foods.dart';
import '../firebase_options.dart';
import '../state/app_state.dart';
import 'nutrigo_api.dart' as api;

/// Connects the app to the NutriGo backend (hosted on Vercel).
///
/// The server address is saved on the phone and can be changed from
/// Profile → Server. Examples:
///   Hosted (default, works from any phone):    https://nutrigo-tau.vercel.app
///   Android emulator, backend on the same PC:  http://10.0.2.2:5000
///   Backend on another laptop (same Wi-Fi):    http://192.168.1.20:5000
class Backend {
  Backend._();

  /// New key: addresses saved by the old app version (old tunnel) are ignored.
  static const _kUrlPref = 'server_url_v2';
  static const _kTokenPref = 'auth_token';
  static const _kOnboardingPref = 'onboarding_seen';

  /// true once the onboarding (splash slides) was shown on this phone.
  static bool onboardingSeen = false;

  static Future<void> markOnboardingSeen() async {
    if (onboardingSeen) return;
    onboardingSeen = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kOnboardingPref, true);
    } catch (_) {}
  }

  /// The hosted NutriGo backend.
  static const defaultUrl = 'https://nutrigo-tau.vercel.app';

  /// Google Sign-In goes through Firebase Auth. On Android the Web client id is
  /// read from google-services.json (made by `flutterfire configure`); only set
  /// this if Google says "serverClientId missing":
  /// `--dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com`
  /// (Firebase console → Authentication → Google → Web SDK configuration).
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  /// true once Firebase.initializeApp() worked (google-services.json present).
  static bool firebaseReady = false;

  /// Call once in main(), before runApp().
  static Future<void> initFirebase() async {
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      firebaseReady = true;
    } catch (_) {
      firebaseReady = false; // not configured yet: Google button explains it
    }
  }

  /// Signed-in user (null when logged out).
  static api.NutriGoUser? user;
  static bool get signedIn => client.token != null;

  static String baseUrl = defaultUrl;
  static api.NutriGoApi client = _make(defaultUrl);

  static List<Food>? _foods;

  /// Number of dishes on the server once loaded (101), else null.
  static int? get foodCount => _foods?.length;

  static api.NutriGoApi _make(String url, {String? token}) =>
      api.NutriGoApi(url, token: token, timeout: const Duration(seconds: 40));

  /// Reads the saved server address and login token. Call once in main().
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kUrlPref);
      if (saved != null && saved.isNotEmpty) _use(saved);
      await prefs.remove('server_url'); // old version's address
      onboardingSeen = prefs.getBool(_kOnboardingPref) ?? false;
      final token = prefs.getString(_kTokenPref);
      if (token != null && token.isNotEmpty) client.token = token;
    } catch (_) {
      // Keep the default.
    }
  }

  /// "192.168.1.20" → "http://192.168.1.20:5000".
  /// "abc.trycloudflare.com" → "https://abc.trycloudflare.com" (tunnel, no port).
  static String normalise(String raw) {
    var u = raw.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    if (u.isEmpty) return defaultUrl;
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      final host = u.split('/').first.split(':').first;
      u = _isLocalHost(host) ? 'http://$u' : 'https://$u';
    }
    final uri = Uri.tryParse(u);
    if (uri != null && !uri.hasPort && uri.scheme == 'http' && _isLocalHost(uri.host)) {
      u = '$u:5000';
    }
    return u;
  }

  /// IP addresses and localhost get port 5000; domain names (tunnels) do not.
  static bool _isLocalHost(String host) =>
      host == 'localhost' || RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host);

  /// The server builds image URLs from what it sees (behind a tunnel that can be
  /// http://localhost:5000/...). Point them at the address the app really uses.
  static String fixUrl(String url) {
    final u = Uri.tryParse(url);
    final base = Uri.tryParse(baseUrl);
    if (u == null || base == null || url.isEmpty) return url;
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : (base.scheme == 'https' ? 443 : 80),
      path: u.path,
      query: u.hasQuery ? u.query : null,
    ).toString();
  }

  static Future<void> setUrl(String raw) async {
    _use(normalise(raw));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUrlPref, baseUrl);
    } catch (_) {}
  }

  static void _use(String url) {
    final token = client.token;
    baseUrl = url;
    client = _make(url, token: token);
    _foods = null;
  }

  /// null when the server answers, else a short reason.
  static Future<String?> check([String? url]) async {
    final c = url == null ? client : _make(normalise(url));
    try {
      final s = await c.status().timeout(const Duration(seconds: 6));
      if (s['model_ready'] == false) {
        return 'Connected, but the server has no recognition model loaded.';
      }
      return null;
    } catch (e) {
      return describe(e);
    }
  }

  /// Human-readable error for a failed call.
  static String describe(Object e) {
    if (e is _SetupError) return e.message;
    if (e is api.NutriGoException) {
      if (e.statusCode == 503) {
        return 'The server has no recognition model. Pick your meal from the list.';
      }
      if (e.statusCode == 413) return 'The photo is too big (max 4.5 MB).';
      if ((e.statusCode == 401 || e.statusCode == 409) && e.message.contains('Google')) {
        return 'This email is linked to a Google account. Use the Google button to sign in.';
      }
      if (e.statusCode == 401) return 'Wrong email or password, or your session ended. Please log in again.';
      if (e.statusCode == 409) return 'An account with this email already exists. Log in instead.';
      if (e.statusCode == 429) return 'Too many tries. Wait a few minutes and try again.';
      return e.message;
    }
    if (e is TimeoutException) {
      return 'The server did not answer in time ($baseUrl).';
    }
    if (e is SocketException || e is HttpException) {
      return 'Cannot reach the server at $baseUrl. Check the address and that both devices are on the same Wi-Fi.';
    }
    return 'Something went wrong: $e';
  }

  // ---------- accounts ----------

  static Future<void> _saveToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final t = client.token;
      if (t == null) {
        await prefs.remove(_kTokenPref);
      } else {
        await prefs.setString(_kTokenPref, t);
      }
    } catch (_) {}
  }

  static String _sexName(Gender g) => g == Gender.male ? 'male' : 'female';

  static String _activityName(ActivityLevel a) => switch (a) {
        ActivityLevel.sedentary => 'sedentary',
        ActivityLevel.lightlyActive => 'light',
        ActivityLevel.veryActive => 'very_active',
      };

  static Goal _goalFrom(String? g) => Goal.values.firstWhere(
        (x) => x.apiName == g,
        orElse: () => Goal.balanced,
      );

  static ActivityLevel _activityFrom(String? a) => switch (a) {
        'sedentary' => ActivityLevel.sedentary,
        'active' || 'very_active' => ActivityLevel.veryActive,
        _ => ActivityLevel.lightlyActive,
      };

  /// Copies the server profile into the app state.
  static void applyUser(AppState s, api.NutriGoUser u) {
    user = u;
    s.update(() {
      s.name = u.name;
      s.email = u.email;
      if (u.sex != null) s.gender = u.sex == 'female' ? Gender.female : Gender.male;
      if (u.age != null) s.age = u.age!.round();
      if (u.heightCm != null) s.heightCm = u.heightCm!.round();
      if (u.weightKg != null) s.weightKg = u.weightKg!.round();
      if (u.activity != null) s.activity = _activityFrom(u.activity);
      if (u.goal != null) {
        s.goal = _goalFrom(u.goal);
        s.dietPrefs = {s.goal};
      }
      s.studentId = u.studentId;
      if (u.goalWeightKg != null) s.goalWeightKg = u.goalWeightKg!.round();
      s.startWeightKg = u.startWeightKg?.round();
    });
  }

  /// true when sex, age, height and weight are still missing (new Google /
  /// Student ID account): show the details form before Home.
  static bool get needsDetails => user != null && user!.dailyTarget == null;

  /// The profile fields the server keeps, taken from the app state.
  static Map<String, dynamic> profileOf(AppState s) => {
        'name': s.name,
        'sex': _sexName(s.gender),
        'age': s.age,
        'height_cm': s.heightCm,
        'weight_kg': s.weightKg,
        'activity': _activityName(s.activity),
        'goal': s.goal.apiName,
        'goal_weight_kg': s.goalWeightKg,
      };

  /// New account on the server. Throws NutriGoException (409 = email exists).
  static Future<void> register(AppState s, String password) async {
    final p = profileOf(s);
    final u = await client.register(
      name: s.name,
      email: s.email,
      password: password,
      sex: p['sex'] as String,
      age: s.age,
      heightCm: s.heightCm,
      weightKg: s.weightKg,
      activity: p['activity'] as String,
      goal: s.goal.apiName,
    );
    await _saveToken();
    user = u;
    s.update(() => s.startWeightKg = u.startWeightKg?.round() ?? s.weightKg);
  }

  /// Throws NutriGoException (401 wrong password, 429 too many tries).
  static Future<void> login(AppState s, String email, String password) async {
    final u = await _loginOrRecreate(email.trim(), password);
    await _signedInAs(s, u);
  }

  /// The free server can lose its accounts. If the login fails but this phone
  /// has the account saved, it is made again on the server (same email and
  /// password) and filled back from the phone.
  static Future<api.NutriGoUser> _loginOrRecreate(String email, String password) async {
    try {
      return await client.login(email, password);
    } on api.NutriGoException catch (e) {
      if (e.statusCode != 401 || e.message.contains('Google')) rethrow;
      final cache = await _readCache(email);
      if (cache == null) rethrow;
      final p = cache['profile'] as Map<String, dynamic>? ?? const {};
      final saved = (p['name'] as String?) ?? '';
      try {
        return await client.register(
            name: saved.trim().isEmpty ? email.split('@').first : saved,
            email: email,
            password: password);
      } catch (_) {
        throw e; // the account exists: the password really is wrong
      }
    }
  }

  static Future<void> _signedInAs(AppState s, api.NutriGoUser u) async {
    await _saveToken();
    s.reset();
    applyUser(s, u);
    await loadMeals(s);
    await _restoreFromCache(s);
    unawaited(ensurePlan());
    unawaited(saveCache(s));
  }

  // ---------- account copy on the phone (kept after logout) ----------

  static const _kCachePrefix = 'account_cache_';

  static String _cacheKey(String email) => '$_kCachePrefix${email.trim().toLowerCase()}';

  static Future<Map<String, dynamic>?> _readCache(String email) async {
    if (email.trim().isEmpty) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(email));
      return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static String _sig(LoggedMeal m) => '${_date(m.date)}|${m.time}|${m.name}|${m.kcal}';

  /// Saves the account's profile and meal history on this phone, so they are
  /// still there after logout (and can refill the server if it lost them).
  static Future<void> saveCache(AppState s) async {
    if (s.email.trim().isEmpty) return;
    final data = {
      'profile': {
        'name': s.name,
        'sex': _sexName(s.gender),
        'age': s.age,
        'height_cm': s.heightCm,
        'weight_kg': s.weightKg,
        'activity': _activityName(s.activity),
        'goal': s.goal.apiName,
        'goal_weight_kg': s.goalWeightKg,
        'start_weight_kg': s.startWeightKg,
        'auto_target': s.autoTarget,
        'target': s.calorieTarget,
      },
      'meals': [
        for (final m in s.meals)
          {
            'date': _date(m.date),
            'time': m.time,
            'slot': m.slot,
            'name': m.name,
            'kcal': m.kcal,
            'saved': m.savedKcal,
            'food_id': m.foodId,
            'from': m.swappedFrom,
          }
      ],
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey(s.email), jsonEncode(data));
    } catch (_) {}
  }

  /// After sign-in: puts back what the server is missing from the phone's copy.
  static Future<void> _restoreFromCache(AppState s) async {
    final cache = await _readCache(s.email);
    if (cache == null) return;
    final p = cache['profile'] as Map<String, dynamic>?;
    if (p != null) {
      if (needsDetails) {
        // The server has no profile for this account any more: send it back.
        s.update(() {
          final name = p['name'] as String?;
          if (name != null && name.trim().isNotEmpty) s.name = name;
          s.gender = p['sex'] == 'female' ? Gender.female : Gender.male;
          s.age = (p['age'] as num?)?.round() ?? s.age;
          s.heightCm = (p['height_cm'] as num?)?.round() ?? s.heightCm;
          s.weightKg = (p['weight_kg'] as num?)?.round() ?? s.weightKg;
          s.activity = _activityFrom(p['activity'] as String?);
          s.goal = _goalFrom(p['goal'] as String?);
          s.dietPrefs = {s.goal};
          s.goalWeightKg = (p['goal_weight_kg'] as num?)?.round() ?? s.goalWeightKg;
          s.startWeightKg = (p['start_weight_kg'] as num?)?.round();
        });
        await syncProfile(s);
      }
      if (p['auto_target'] == false && p['target'] is num) {
        s.calorieTarget = (p['target'] as num).round();
      }
    }
    final have = {for (final m in s.meals) _sig(m)};
    final missing = <LoggedMeal>[];
    for (final j in (cache['meals'] as List? ?? const [])) {
      try {
        final m = j as Map<String, dynamic>;
        final d = (m['date'] as String).split('-').map(int.parse).toList();
        final meal = LoggedMeal(
          name: m['name'] as String,
          kcal: (m['kcal'] as num).round(),
          slot: m['slot'] as String,
          time: m['time'] as String,
          date: DateTime(d[0], d[1], d[2]),
          savedKcal: (m['saved'] as num?)?.round() ?? 0,
          foodId: m['food_id'] as String?,
          swappedFrom: m['from'] as String?,
        );
        if (have.add(_sig(meal))) missing.add(meal);
      } catch (_) {}
    }
    if (missing.isEmpty) return;
    final all = [...s.meals, ...missing]
      ..sort((a, b) {
        final c = b.date.compareTo(a.date);
        return c != 0 ? c : b.time.compareTo(a.time);
      });
    s.setMeals(all);
    unawaited(Future.forEach(missing, saveMeal)); // refill the server
  }

  static bool _googleReady = false;

  /// Google Sign-In (Google account picker → Firebase Auth → NutriGo account).
  /// Returns false if the user closed the Google window.
  static Future<bool> googleLogin(AppState s) async {
    if (!firebaseReady) {
      throw const _SetupError(
          'Google sign-in is not set up yet: run "flutterfire configure" for this app.');
    }
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize(
          serverClientId: googleWebClientId.isEmpty ? null : googleWebClientId);
      _googleReady = true; // initialize() may only run once
    }
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      throw _SetupError('Google sign-in failed: ${e.description ?? e.code.name}');
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) throw const _SetupError('Google did not return a sign-in token.');
    // Also sign in to Firebase Auth (the user shows in the Firebase console).
    try {
      await FirebaseAuth.instance
          .signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
    } catch (_) {
      // Not needed by the NutriGo server; it checks the Google token itself.
    }
    final u = await client.loginWithGoogle(idToken);
    await _signedInAs(s, u);
    return true;
  }

  /// true if an account with this student id exists.
  static Future<bool> studentExists(String studentId) =>
      client.studentExists(studentId.trim());

  /// Signs in with a student id; the first time it creates the account.
  static Future<void> studentLogin(AppState s, String studentId, String password,
      {String? name}) async {
    final u = await client.studentLogin(studentId.trim(), password, name: name);
    await _signedInAs(s, u);
  }

  // ---------- meal log ----------

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static LoggedMeal _mealFrom(api.LoggedMealRecord r) {
    final p = r.date.split('-').map(int.parse).toList();
    return LoggedMeal(
      id: r.id,
      name: r.name,
      kcal: r.kcal,
      slot: r.slot,
      time: r.time,
      date: DateTime(p[0], p[1], p[2]),
      savedKcal: r.savedKcal,
      foodId: r.foodId,
      swappedFrom: r.swappedFrom,
    );
  }

  /// The account's meals of the last 60 days → the home ring, history and stats.
  static Future<void> loadMeals(AppState s) async {
    if (!signedIn) return;
    try {
      final since = DateTime.now().subtract(const Duration(days: 60));
      final list = await client.meals(since: _date(since));
      s.setMeals(list.map(_mealFrom).toList());
    } catch (_) {
      // Keep what is on the phone; retried on the next start.
    }
  }

  /// Saves a meal the user just logged (hooked to AppState.onMealLogged).
  static Future<void> saveMeal(LoggedMeal m) async {
    if (!signedIn) return;
    try {
      final r = await client.addMeal(
        date: _date(m.date),
        time: m.time,
        slot: m.slot,
        name: m.name,
        kcal: m.kcal,
        foodId: m.foodId,
        savedKcal: m.savedKcal,
        swappedFrom: m.swappedFrom,
      );
      m.id = r.id;
    } catch (_) {}
  }

  static Future<void> deleteMeal(AppState s, LoggedMeal m) async {
    s.removeMeal(m);
    unawaited(saveCache(s));
    final id = m.id;
    if (id != null && signedIn) {
      try {
        await client.deleteMeal(id);
      } catch (_) {}
    }
  }

  /// On start-up: true when the saved token still works (the state is filled in).
  static Future<bool> restoreSession(AppState s) async {
    if (client.token == null) return false;
    try {
      final u = await client.me().timeout(const Duration(seconds: 20));
      applyUser(s, u);
      await loadMeals(s);
      await _restoreFromCache(s);
      unawaited(ensurePlan());
      unawaited(saveCache(s));
      return true;
    } on api.NutriGoException catch (e) {
      if (e.statusCode == 401) {
        client.token = null;
        user = null;
        await _saveToken();
      }
      return false;
    } catch (_) {
      return false; // offline: show the login screen
    }
  }

  /// Sends the profile to the server and keeps the plan on the new target.
  static Future<void> syncProfile(AppState s) async {
    if (!signedIn) return;
    try {
      final u = await client.updateMe(profileOf(s));
      user = u;
      if (s.startWeightKg == null && u.startWeightKg != null) {
        s.update(() => s.startWeightKg = u.startWeightKg!.round());
      }
      unawaited(saveCache(s));
      final t = u.dailyTarget;
      if (t == null) return;
      final plan = await client.plan('me');
      if (plan == null) {
        await client.createPlan('me', kcalTarget: t.planKcal, goal: u.goal ?? 'balanced');
      } else if (plan.kcalTarget != t.planKcal || plan.goal != u.goal) {
        await client.updatePlan('me', kcalTarget: t.planKcal, goal: u.goal);
      }
    } catch (_) {
      // Not critical for the app; it is retried on the next change.
    }
  }

  /// Creates the 7-day plan if the user has none yet.
  static Future<void> ensurePlan() async {
    if (!signedIn) return;
    try {
      final u = user ?? await client.me();
      final t = u.dailyTarget;
      if (t == null) return;
      if (await client.plan('me') == null) {
        await client.createPlan('me', kcalTarget: t.planKcal, goal: u.goal ?? 'balanced');
      }
    } catch (_) {}
  }

  static Future<void> logout([AppState? s]) async {
    try {
      if (signedIn) await client.logout().timeout(const Duration(seconds: 10));
    } catch (_) {}
    try {
      if (firebaseReady) await FirebaseAuth.instance.signOut();
      if (_googleReady) await GoogleSignIn.instance.signOut();
    } catch (_) {}
    if (s != null) await saveCache(s); // keep the account's data on the phone
    client.token = null;
    user = null;
    await _saveToken();
    s?.reset();
  }

  // ---------- conversions to the app's own models ----------

  static Food foodFromApi(api.Food f) => Food(
        id: f.id,
        imageUrl: fixUrl(f.imageUrl),
        name: f.name,
        category: f.category,
        kcal: f.kcal.round(),
        grams: f.servingG.round(),
        protein: f.proteinG.round(),
        carbs: f.carbsG.round(),
        fat: f.fatG.round(),
        sodiumMg: f.sodiumMg.round(),
        portionTip: f.serving.isEmpty ? '' : 'One serving: ${f.serving}',
      );

  static SwapOption swapFromApi(api.Food s) => SwapOption(
        id: s.id,
        imageUrl: fixUrl(s.imageUrl),
        name: s.name,
        shortName: s.name,
        reason: s.why.isNotEmpty ? s.why.take(2).join(' · ') : s.category,
        kcal: s.kcal.round(),
        score: s.healthScore,
      );

  // ---------- calls used by the screens ----------

  /// All dishes on the server (cached).
  static Future<List<Food>> foods() async {
    final cached = _foods;
    if (cached != null) return cached;
    final list = (await client.foods()).map(foodFromApi).toList();
    _foods = list;
    return list;
  }

  /// Photo → the model's top-5 guesses with full nutrition.
  static Future<Recognition> recognise(String photoPath, Goal goal) async {
    final r = await client.predict(File(photoPath), goal: goal.apiName);
    List<Food> all;
    try {
      all = await foods();
    } catch (_) {
      all = const [];
    }
    final guesses = <(Food, double)>[];
    for (final p in r.predictions.take(5)) {
      Food? f;
      for (final x in all) {
        if (x.id == p.id) {
          f = x;
          break;
        }
      }
      if (f == null) {
        try {
          f = foodFromApi(await client.food(p.id));
        } catch (_) {
          continue;
        }
      }
      guesses.add((f, p.confidence));
    }
    return Recognition(guesses, r.lowConfidence);
  }

  /// Healthier swaps for [food] eaten at [portion].
  static Future<SwapResult> recommend(Food food, double portion, Goal goal) async {
    final r = await client.recommend(food.id!,
        portion: portion.clamp(0.5, 2.0).toDouble(), goal: goal.apiName, limit: 4);
    return SwapResult(r.swaps.map(swapFromApi).toList(), r.message);
  }
}

class _SetupError implements Exception {
  const _SetupError(this.message);
  final String message;
}

class Recognition {
  Recognition(this.guesses, this.lowConfidence);
  final List<(Food, double)> guesses;
  final bool lowConfidence;
}

class SwapResult {
  SwapResult(this.swaps, this.message);
  final List<SwapOption> swaps;
  final String? message;
}
