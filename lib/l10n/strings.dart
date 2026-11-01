/// Lightweight English/Arabic strings.
///
/// Every user-facing string is written in English and passed through [tr].
/// When Arabic is active the English text is looked up in [_ar]; anything
/// missing falls back to English. Placeholders like `{n}` are filled from
/// [args].
class L10n {
  L10n._();

  /// Set by the app root when the language changes.
  static bool arabic = false;
}

String tr(String en, [Map<String, Object> args = const {}]) {
  var s = L10n.arabic ? (_ar[en] ?? en) : en;
  args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

const Map<String, String> _ar = {
  // ---- Real data / Student ID ----
  'This email is linked to a Google account. Use the Google button to sign in.': 'الإيميل ده متسجّل بحساب جوجل. ادخل بزرار Google.',
  'Swipe': 'اسحب',
  'Swaps goal': 'هدف البدائل',
  'The model\'s top 5 guesses. Tap to correct.': 'أعلى 5 توقعات من الموديل. دوس لتصحيحها.',
  'Continue': 'متابعة',
  'Enter your password': 'اكتب كلمة المرور',
  '{age} · Student ID {id}': '{age} · رقم الطالب {id}',
  '{age} years': '{age} سنة',
  'Snap or log a meal and your personal lighter swap shows up here.': 'صوّر أو سجّل وجبة، وهيظهرلك هنا بديل أخف مخصوص ليك.',
  'Your meals are already light choices. Nice!': 'وجباتك خفيفة أصلًا. برافو!',
  'No meal yet': 'لسه مفيش وجبة',
  'Snap a meal and we will show you lighter swaps for it.': 'صوّر وجبة وهنوريك بدائل أخف ليها.',
  'Sign in with Student ID': 'الدخول برقم الطالب',
  'Type your university student ID.': 'اكتب رقم الطالب الجامعي بتاعك.',
  'Enter the password of student ID {id}.': 'اكتب كلمة المرور لرقم الطالب {id}.',
  'Create your password': 'اعمل كلمة مرور',
  'First time with student ID {id}: choose a password for next time.': 'أول مرة برقم الطالب {id}: اختار كلمة مرور للمرات الجاية.',
  'New password (8+ characters)': 'كلمة مرور جديدة (8 حروف أو أكتر)',
  'Confirm password': 'تأكيد كلمة المرور',
  'Enter your student ID (3-20 letters or digits).': 'اكتب رقم الطالب (من 3 لـ 20 حرف أو رقم).',
  'The password needs at least 8 characters.': 'كلمة المرور لازم تكون 8 حروف على الأقل.',
  'The two passwords are not the same.': 'كلمتين المرور مش زي بعض.',
  'Google sign-in is not set up yet: run "flutterfire configure" for this app.': 'تسجيل الدخول بجوجل لسه متظبطش: شغّل "flutterfire configure" للأبلكيشن.',
  'Google did not return a sign-in token.': 'جوجل مرجعش بيانات الدخول.',
  // ---- Server accounts ----
  'Please wait…': 'لحظة من فضلك…',
  'The photo is too big (max 4.5 MB).': 'الصورة كبيرة جدًا (الحد الأقصى 4.5 ميجا).',
  'Wrong email or password, or your session ended. Please log in again.':
      'البريد أو كلمة المرور غلط، أو انتهت الجلسة. سجّل الدخول تاني.',
  'An account with this email already exists. Log in instead.':
      'فيه حساب بالبريد ده بالفعل. سجّل الدخول بدلًا من كده.',
  'Too many tries. Wait a few minutes and try again.':
      'محاولات كتير. استنى كام دقيقة وجرّب تاني.',
  // ---- General ----
  'kcal': 'سعرة',
  '{n} kcal': '{n} سعرة',
  '−{n} kcal': '−{n} سعرة',
  '+{n} kcal': '+{n} سعرة',
  '{n} g': '{n} جم',
  '{n} mg': '{n} مجم',
  'kg': 'كجم',
  'cm': 'سم',
  'Back': 'رجوع',
  'Decrease': 'تقليل',
  'Increase': 'زيادة',
  'Show password': 'إظهار كلمة المرور',
  'Hide password': 'إخفاء كلمة المرور',
  'Cancel': 'إلغاء',
  'Save': 'حفظ',
  'Got it': 'تمام',
  'Try again': 'حاول تاني',
  'Today': 'النهارده',
  'Yesterday': 'امبارح',

  // ---- Flow steps ----
  'Snap': 'صوّر',
  'Confirm': 'أكّد',
  'Adjust': 'اضبط',
  'Swap': 'بدّل',
  'Step {a} of 4 · {name}': 'خطوة {a} من 4 · {name}',
  'Step {a} of {b}': 'خطوة {a} من {b}',

  // ---- Splash ----
  'Snap a meal, see its calories,\nget a healthier swap.':
      'صوّر وجبتك، اعرف سعراتها،\nوخد بديل أصح.',
  '1 photo': 'صورة واحدة',
  'Top-3 guess': 'أفضل 3 توقعات',
  'Portion': 'الكمية',
  'Save kcal': 'وفّر سعرات',
  '1 photo → 3 taps': 'صورة ← 3 لمسات',
  'No typing. You stay in control of every step.':
      'من غير كتابة. وانت متحكم في كل خطوة.',
  'Lighter, same taste': 'أخف، بنفس الطعم',
  'Every swap is scored for taste, calories and your goal.':
      'كل بديل متقيّم حسب الطعم والسعرات وهدفك.',
  'See your progress': 'تابع تقدّمك',
  'Track calories saved, streaks and your weekly trend.':
      'تابع السعرات اللي وفّرتها وأيامك المتتالية وأداءك الأسبوعي.',
  'Get started': 'يلا نبدأ',
  'I already have an account': 'عندي حساب بالفعل',

  // ---- Sign up ----
  'Create account': 'إنشاء حساب',
  'Start swapping in under a minute.': 'ابدأ التبديل في أقل من دقيقة.',
  'Full name': 'الاسم بالكامل',
  'Email': 'البريد الإلكتروني',
  'Password': 'كلمة المرور',
  'Too short': 'قصيرة جدًا',
  'Weak password': 'كلمة مرور ضعيفة',
  'Okay password': 'كلمة مرور مقبولة',
  'Good password': 'كلمة مرور جيدة',
  'Strong password': 'كلمة مرور قوية',
  '8+ chars · 1 number': '8 حروف أو أكتر · رقم واحد',
  "What's your goal?": 'إيه هدفك؟',
  'Daily calorie target': 'هدف السعرات اليومي',
  'I agree to the ': 'أوافق على ',
  'Terms': 'الشروط',
  ' and ': ' و',
  'Privacy Policy': 'سياسة الخصوصية',
  'Already have an account? ': 'عندك حساب؟ ',
  'Log in': 'تسجيل الدخول',

  // ---- Login ----
  'Welcome back': 'أهلًا بيك تاني',
  'Log in to keep tracking your swaps.': 'سجّل دخولك عشان تكمّل متابعة بدائلك.',
  'Remember me': 'افتكرني',
  'Forgot password?': 'نسيت كلمة المرور؟',
  'Password reset link sent': 'تم إرسال رابط إعادة تعيين كلمة المرور',
  'Enter your email and password': 'اكتب بريدك الإلكتروني وكلمة المرور',
  'or continue with': 'أو كمّل باستخدام',
  'Student ID': 'كارنيه الطالب',
  'New to NutriGo? ': 'جديد على NutriGo؟ ',
  'Sign up': 'اعمل حساب',
  '1 photo\n→ 3 taps': 'صورة واحدة\n← 3 لمسات',
  'No typing. You stay in\ncontrol of every step.':
      'من غير كتابة. وانت\nمتحكم في كل خطوة.',
  'Nutrition Facts': 'القيمة الغذائية',
  'Turkey wrap': 'راب تركي',
  'You save': 'هتوفّر',

  // ---- Your details ----
  'Tell us about you': 'عرّفنا بنفسك',
  'We use this to calculate your daily calories.':
      'بنستخدم البيانات دي عشان نحسب سعراتك اليومية.',
  'Male': 'ذكر',
  'Female': 'أنثى',
  'Age': 'السن',
  '{n} years': '{n} سنة',
  'Weight': 'الوزن',
  'Height': 'الطول',
  'Goal weight': 'الوزن المستهدف',
  'Maintain': 'ثبات',
  'Activity level': 'مستوى النشاط',
  'Sedentary': 'قليل الحركة',
  'Lightly active': 'نشاط خفيف',
  'Very active': 'نشيط جدًا',
  'YOUR DAILY TARGET': 'هدفك اليومي',
  ' / day': ' / يوم',
  'Auto': 'تلقائي',
  'Manual': 'يدوي',
  'BMR {bmr} × {f} activity {adj}': 'الأيض الأساسي {bmr} × {f} نشاط {adj}',
  'to maintain': 'للثبات',
  '− {n} to lose weight': '− {n} لخسارة الوزن',
  '+ {n} to gain weight': '+ {n} لزيادة الوزن',
  'Protein {n} g': 'بروتين {n} جم',
  'Carbs {n} g': 'كربوهيدرات {n} جم',
  'Fat {n} g': 'دهون {n} جم',
  'Save and continue': 'احفظ وكمّل',

  // ---- Goals ----
  'Lose weight': 'خسارة وزن',
  'Balanced': 'متوازن',
  'High protein': 'بروتين عالي',
  'Low carb': 'كربوهيدرات قليلة',
  'Vegetarian': 'نباتي',

  // ---- Tabs ----
  'Home': 'الرئيسية',
  'History': 'السجل',
  'Swaps': 'البدائل',
  'Profile': 'حسابي',
  'Snap a meal': 'صوّر وجبة',

  // ---- Home ----
  'Good morning,': 'صباح الخير،',
  'Good afternoon,': 'مساء الخير،',
  'Good evening,': 'مساء النور،',
  'Notifications': 'الإشعارات',
  'No new notifications': 'مفيش إشعارات جديدة',
  "TODAY'S CALORIES": 'سعرات النهارده',
  '{n} kcal left · {goal} goal': 'فاضل {n} سعرة · هدف {goal}',
  'kcal saved': 'سعرة اتوفّرت',
  'meals logged': 'وجبات مسجّلة',
  'swaps taken': 'بدائل اتاخدت',
  '1 photo → 3 taps to a lighter swap': 'صورة ← 3 لمسات لبديل أخف',
  'Your goal': 'هدفك',
  'More goals': 'أهداف تانية',
  'Choose your goal': 'اختار هدفك',
  'Smart swap of the day': 'البديل الذكي النهارده',
  'See all': 'عرض الكل',
  'Same taste · score {n} / 100': 'نفس الطعم · تقييم {n} / 100',
  'Choose swap': 'اختار البديل',
  'Recent meals': 'آخر الوجبات',
  'Nothing logged yet today.': 'لسه مفيش حاجة مسجّلة النهارده.',
  'swapped': 'اتبدّلت',
  'Breakfast': 'فطار',
  'Lunch': 'غدا',
  'Dinner': 'عشا',
  'Snack': 'سناك',

  // ---- Snap ----
  'Flash': 'الفلاش',
  'Camera ready': 'الكاميرا جاهزة',
  'Camera off': 'الكاميرا مقفولة',
  'Center your meal in the frame': 'خلّي وجبتك في نص الإطار',
  'No camera found on this device.': 'مفيش كاميرا على الجهاز ده.',
  'Camera access is off. Allow it in Settings, or upload a photo from your gallery.':
      'إذن الكاميرا مقفول. فعّله من الإعدادات، أو ارفع صورة من الجاليري.',
  'Could not open the camera.': 'مقدرناش نفتح الكاميرا.',
  'Could not take the photo. Try again.': 'الصورة متصورتش. حاول تاني.',
  'Could not open the gallery.': 'مقدرناش نفتح الجاليري.',
  'Upload': 'رفع',
  'Camera': 'الكاميرا',
  'From list': 'من القائمة',
  'Gallery': 'الجاليري',
  'Take photo': 'التقط صورة',
  'Pick from list': 'اختار من القائمة',
  'Search foods': 'دوّر على أكلة',
  'e.g. burger, koshari…': 'مثلًا برجر، كشري…',
  'No foods match "{q}"': 'مفيش أكل مطابق لـ "{q}"',

  // ---- Confirm ----
  'Is this your meal?': 'هي دي وجبتك؟',
  'Our top 3 guesses. Tap to correct.': 'أفضل 3 توقعات عندنا. دوس عشان تصحّح.',
  'Not here? ': 'مش موجودة؟ ',
  'Search all {n} foods': 'دوّر في كل الـ {n} أكلة',
  'Confirm {name}': 'تأكيد {name}',

  // ---- Adjust ----
  'Adjust portion': 'اضبط الكمية',
  '{cat} · recognised {n}%': '{cat} · اتعرفت بنسبة {n}%',
  'Change': 'تغيير',
  '{p} · about {g} g': '{p} · حوالي {g} جم',
  'Calories': 'السعرات',
  'Protein': 'بروتين',
  'Carbs': 'كربوهيدرات',
  'Fat': 'دهون',
  'Sodium': 'صوديوم',
  ' = {pct}% of your {t} kcal day': ' = {pct}% من يومك ({t} سعرة)',
  'Find lighter swaps': 'دوّر على بدائل أخف',

  // ---- Swaps ----
  'Lighter swaps': 'بدائل أخف',
  'YOU PICKED': 'اختيارك',
  'Goal: {g}': 'الهدف: {g}',
  '{n} swaps · ranked by score': '{n} بدائل · مرتبة بالتقييم',
  'How it works': 'بتشتغل إزاي',
  'How swaps are scored': 'إزاي البدائل بتتقيّم',
  'Each swap gets a score out of 100 based on calories saved, how similar it tastes, its category, and how well it fits your goal. The highest score is marked TOP PICK.':
      'كل بديل بياخد تقييم من 100 حسب السعرات اللي بيوفرها، وقد إيه طعمه قريب، ونوعه، ومناسب لهدفك قد إيه. أعلى تقييم بيتعلّم عليه "أفضل اختيار".',
  'TOP PICK': 'أفضل اختيار',
  'score': 'تقييم',
  'Keep meal': 'خلّي الوجبة',
  'Choose top pick': 'اختار الأفضل',
  'Choose this swap': 'اختار البديل ده',
  '{name} logged': 'اتسجّل {name}',

  // ---- Swap logged ----
  'Swap logged!': 'البديل اتسجّل!',
  '{meal} added to {slot}': '{meal} اتضاف لـ {slot}',
  'YOU SAVED': 'وفّرت',
  'compared with the {name}': 'مقارنة بـ {name}',
  'Before': 'قبل',
  'After': 'بعد',
  '{n} kcal left for today': 'فاضل {n} سعرة النهارده',
  'Back to home': 'رجوع للرئيسية',
  'Snap another meal': 'صوّر وجبة تانية',

  // ---- History ----
  'This week': 'الأسبوع ده',
  'This month · daily avg': 'الشهر ده · متوسط يومي',
  'Wk {n}': 'أ{n}',
  '−{n} kcal saved': 'وفّرت {n} سعرة',
  '{n}-day streak': '{n} أيام ورا بعض',
  'Week': 'أسبوع',
  'Month': 'شهر',
  'goal {n}': 'الهدف {n}',
  'Mon': 'اتنين',
  'Tue': 'تلات',
  'Wed': 'أربع',
  'Thu': 'خميس',
  'Fri': 'جمعة',
  'Sat': 'سبت',
  'Sun': 'حد',

  // ---- Profile ----
  '{age} · University student': '{age} · طالب جامعي',
  'Edit': 'تعديل',
  'Edit name': 'تعديل الاسم',
  'MY GOAL': 'هدفي',
  'Lose {n} kg': 'خسارة {n} كجم',
  'Gain {n} kg': 'زيادة {n} كجم',
  'Maintain weight': 'ثبات الوزن',
  'Daily target {n} kcal · {goal} swaps': 'الهدف اليومي {n} سعرة · بدائل {goal}',
  'PREFERENCES': 'التفضيلات',
  'Goal preference': 'الهدف',
  'Language': 'اللغة',
  'Dark mode': 'الوضع الداكن',
  'Reduced motion': 'تقليل الحركة',
  'Log out': 'تسجيل الخروج',
  'Calculated for you': 'محسوب ليك تلقائي',
  'Custom target': 'هدف مخصّص',
  'Reset to automatic ({n} kcal)': 'رجّعه تلقائي ({n} سعرة)',

  // ---- Foods ----
  'Hamburger': 'هامبرجر',
  'Cheeseburger': 'تشيز برجر',
  'Pulled pork sandwich': 'ساندوتش لحم مفروم',
  'Koshari': 'كشري',
  'Pepperoni pizza (2 slices)': 'بيتزا بيبروني (شريحتين)',
  'Fast food': 'وجبات سريعة',
  'Sandwich': 'ساندوتشات',
  'Egyptian': 'مصري',
  'Tip: one burger is about the size of your palm.':
      'معلومة: البرجر الواحد تقريبًا قد كف إيدك.',
  'Tip: one sandwich is about two palms.':
      'معلومة: الساندوتش الواحد تقريبًا قد كفين.',
  'Tip: a small bowl is about one fist.':
      'معلومة: الطبق الصغير تقريبًا قد قبضة إيدك.',
  'Tip: one slice is about your hand.': 'معلومة: الشريحة الواحدة تقريبًا قد إيدك.',
  'Grilled chicken breast + veg': 'صدر فراخ مشوي + خضار',
  'Grilled chicken + veg': 'فراخ مشوية + خضار',
  'High protein · same plate size': 'بروتين عالي · نفس حجم الطبق',
  'Turkey + avocado sandwich': 'ساندوتش ديك رومي + أفوكادو',
  'Turkey sandwich': 'ساندوتش ديك رومي',
  'Similar taste · sandwich': 'طعم قريب · ساندوتش',
  'Turkey burger in lettuce wrap': 'برجر ديك رومي في خس',
  'Turkey lettuce wrap': 'ديك رومي في خس',
  'Same category · keeps the burger': 'نفس النوع · برجر برضه',
  'Turkey hot dog, whole-wheat bun': 'هوت دوج ديك رومي، عيش أسمر',
  'Turkey hot dog': 'هوت دوج ديك رومي',
  'Fast food · lighter bun': 'وجبات سريعة · عيش أخف',
  'Grilled chicken wrap': 'راب فراخ مشوية',
  'Chicken wrap': 'راب فراخ',
  'High protein · handheld': 'بروتين عالي · سهل في الإيد',
  'Koshari, small bowl': 'كشري، طبق صغير',
  'Small koshari': 'كشري صغير',
  'Same dish · smaller portion': 'نفس الأكلة · كمية أقل',
  'Lentil soup + salad': 'شوربة عدس + سلطة',
  'Lentil soup': 'شوربة عدس',
  'Same lentils · lighter': 'نفس العدس · أخف',
  'Thin-crust veggie pizza': 'بيتزا خضار عجينة رفيعة',
  'Veggie pizza': 'بيتزا خضار',
  'Same category · thin crust': 'نفس النوع · عجينة رفيعة',
  'Ful medames + bread': 'فول مدمس + عيش',
  'Chicken shawarma wrap': 'ساندوتش شاورما فراخ',
  'Grilled fish + rice': 'سمك مشوي + رز',

  // ---- Server (NutriGo API) ----
  'Server': 'السيرفر',
  'Test': 'اختبار',
  'Testing…': 'بنختبر…',
  'Connected ✓': 'متصل ✓',
  'Recognising your meal…': 'بنتعرّف على وجبتك…',
  'Could not recognise this meal.': 'معرفناش نتعرّف على الوجبة دي.',
  'Not sure about this one – please check the guess or search the list.':
      'مش متأكدين منها – راجع التخمين أو دوّر في القايمة.',
  'Showing the offline demo list.': 'بنعرض القايمة التجريبية من غير نت.',
  'IP of the laptop running the backend (ipconfig → IPv4). Emulator on the same PC: 10.0.2.2':
      'الـ IP بتاع اللاب اللي شغّال عليه الباك إند (ipconfig ← IPv4). الإيموليتر على نفس الجهاز: 10.0.2.2',
};
