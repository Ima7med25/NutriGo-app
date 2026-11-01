import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/strings.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/backend.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
const _kDarkPref = 'dark_mode';
const _kLangPref = 'language';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final state = AppState();
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
    state.darkMode = prefs.getBool(_kDarkPref) ?? false;
    state.language = prefs.getString(_kLangPref) ?? 'en';
  } catch (_) {
    // Preferences unavailable – start with defaults.
  }

  await Backend.initFirebase(); // Google sign-in (Firebase Auth)
  await Backend.load();
  // Every meal logged on the phone is saved to the account on the server.
  state.onMealLogged = (meal) {
    Backend.saveMeal(meal);
    Backend.saveCache(state); // also kept on the phone (survives logout)
  };

  runApp(NutriGoApp(state: state, prefs: prefs));
}

class NutriGoApp extends StatefulWidget {
  const NutriGoApp({super.key, required this.state, this.prefs});
  final AppState state;
  final SharedPreferences? prefs;

  @override
  State<NutriGoApp> createState() => _NutriGoAppState();
}

class _NutriGoAppState extends State<NutriGoApp> {
  late bool _dark = widget.state.darkMode;
  late String _lang = widget.state.language;

  @override
  void initState() {
    super.initState();
    _apply();
    widget.state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _apply() {
    AppColors.dark = _dark;
    L10n.arabic = _lang == 'ar';
  }

  void _onStateChanged() {
    final s = widget.state;
    if (s.darkMode == _dark && s.language == _lang) return;
    _dark = s.darkMode;
    _lang = s.language;
    _apply();
    widget.prefs?.setBool(_kDarkPref, _dark);
    widget.prefs?.setString(_kLangPref, _lang);
    setState(() {});
  
    void rebuild(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: MaterialApp(
        title: 'NutriGo',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        locale: Locale(_lang),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // Saved login → check it; onboarding only the first time; else Login.
        home: Backend.signedIn
            ? const LaunchScreen()
            : (Backend.onboardingSeen
                ? const LoginScreen()
                : const SplashScreen()),
      ),
    );
  }
}
