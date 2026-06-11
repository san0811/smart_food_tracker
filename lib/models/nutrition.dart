class Nutrition {
  const Nutrition({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  factory Nutrition.fromOpenFoodFacts(Map<String, dynamic>? nutriments) {
    if (nutriments == null) {
      return const Nutrition();
    }

    return Nutrition(
      calories: _readNumber(
        nutriments['energy-kcal_100g'] ?? nutriments['energy-kcal'],
      ),
      protein: _readNumber(
        nutriments['proteins_100g'] ?? nutriments['proteins'],
      ),
      carbs: _readNumber(
        nutriments['carbohydrates_100g'] ?? nutriments['carbohydrates'],
      ),
      fat: _readNumber(nutriments['fat_100g'] ?? nutriments['fat']),
    );
  }

  factory Nutrition.fromMap(Map<String, dynamic> map) {
    return Nutrition(
      calories: _readNumber(map['calories']),
      protein: _readNumber(map['protein']),
      carbs: _readNumber(map['carbs']),
      fat: _readNumber(map['fat']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  static double _readNumber(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? 0;
  }
}
