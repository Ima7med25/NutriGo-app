class SwapOption {
  const SwapOption({
    required this.name,
    required this.shortName,
    required this.reason,
    required this.kcal,
    required this.score,
    this.id,
    this.imageUrl,
  });

  final String name;
  final String shortName;
  final String reason;
  final int kcal;
  final int score; // 0-100

  /// Set when the swap came from the NutriGo server.
  final String? id;
  final String? imageUrl;
}

class Food {
  const Food({
    required this.name,
    required this.category,
    required this.kcal,
    required this.grams,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sodiumMg,
    required this.portionTip,
    this.swaps = const [],
    this.id,
    this.imageUrl,
  });

  final String name;
  final String category;
  final int kcal; // for 1× portion
  final int grams; // 1× portion weight
  final int protein;
  final int carbs;
  final int fat;
  final int sodiumMg;
  final String portionTip;
  final List<SwapOption> swaps;

  /// Server food_id (e.g. "pizza") when the food came from the NutriGo API.
  /// null for the built-in demo foods below.
  final String? id;
  final String? imageUrl;
}

const hamburger = Food(
  name: 'Hamburger',
  category: 'Fast food',
  kcal: 650,
  grams: 220,
  protein: 34,
  carbs: 45,
  fat: 36,
  sodiumMg: 1100,
  portionTip: 'Tip: one burger is about the size of your palm.',
  swaps: [
    SwapOption(
        name: 'Grilled chicken breast + veg',
        shortName: 'Grilled chicken + veg',
        reason: 'High protein · same plate size',
        kcal: 350,
        score: 78),
    SwapOption(
        name: 'Turkey + avocado sandwich',
        shortName: 'Turkey sandwich',
        reason: 'Similar taste · sandwich',
        kcal: 390,
        score: 66),
    SwapOption(
        name: 'Turkey burger in lettuce wrap',
        shortName: 'Turkey lettuce wrap',
        reason: 'Same category · keeps the burger',
        kcal: 290,
        score: 63),
    SwapOption(
        name: 'Turkey hot dog, whole-wheat bun',
        shortName: 'Turkey hot dog',
        reason: 'Fast food · lighter bun',
        kcal: 260,
        score: 56),
  ],
);

const cheeseburger = Food(
  name: 'Cheeseburger',
  category: 'Fast food',
  kcal: 700,
  grams: 235,
  protein: 37,
  carbs: 46,
  fat: 40,
  sodiumMg: 1250,
  portionTip: 'Tip: one burger is about the size of your palm.',
  swaps: [
    SwapOption(
        name: 'Turkey burger in lettuce wrap',
        shortName: 'Turkey lettuce wrap',
        reason: 'Same category · keeps the burger',
        kcal: 290,
        score: 70),
    SwapOption(
        name: 'Grilled chicken breast + veg',
        shortName: 'Grilled chicken + veg',
        reason: 'High protein · same plate size',
        kcal: 350,
        score: 68),
  ],
);

const pulledPork = Food(
  name: 'Pulled pork sandwich',
  category: 'Sandwich',
  kcal: 560,
  grams: 210,
  protein: 30,
  carbs: 52,
  fat: 24,
  sodiumMg: 980,
  portionTip: 'Tip: one sandwich is about two palms.',
  swaps: [
    SwapOption(
        name: 'Turkey + avocado sandwich',
        shortName: 'Turkey sandwich',
        reason: 'Similar taste · sandwich',
        kcal: 390,
        score: 72),
    SwapOption(
        name: 'Grilled chicken wrap',
        shortName: 'Chicken wrap',
        reason: 'High protein · handheld',
        kcal: 380,
        score: 65),
  ],
);

const koshari = Food(
  name: 'Koshari',
  category: 'Egyptian',
  kcal: 720,
  grams: 400,
  protein: 22,
  carbs: 130,
  fat: 12,
  sodiumMg: 900,
  portionTip: 'Tip: a small bowl is about one fist.',
  swaps: [
    SwapOption(
        name: 'Koshari, small bowl',
        shortName: 'Small koshari',
        reason: 'Same dish · smaller portion',
        kcal: 480,
        score: 74),
    SwapOption(
        name: 'Lentil soup + salad',
        shortName: 'Lentil soup',
        reason: 'Same lentils · lighter',
        kcal: 320,
        score: 62),
  ],
);

const pizza = Food(
  name: 'Pepperoni pizza (2 slices)',
  category: 'Fast food',
  kcal: 620,
  grams: 220,
  protein: 26,
  carbs: 64,
  fat: 28,
  sodiumMg: 1400,
  portionTip: 'Tip: one slice is about your hand.',
  swaps: [
    SwapOption(
        name: 'Thin-crust veggie pizza',
        shortName: 'Veggie pizza',
        reason: 'Same category · thin crust',
        kcal: 410,
        score: 71),
  ],
);

const allFoods = [hamburger, cheeseburger, pulledPork, koshari, pizza];

/// Simulated recognition results: (food, confidence 0-1).
const recognitionGuesses = [
  (hamburger, 0.86),
  (cheeseburger, 0.09),
  (pulledPork, 0.03),
];
