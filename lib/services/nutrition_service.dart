import '../models/food_item.dart';
import '../models/nutrition.dart';

class NutritionService {
  Nutrition nutritionForItem(FoodItem item) => item.nutrition;

  double dailyCalories(Iterable<FoodItem> items) {
    return items.fold<double>(
      0,
      (sum, item) => sum + nutritionForItem(item).calories,
    );
  }

  double totalProtein(Iterable<FoodItem> items) {
    return items.fold<double>(
      0,
      (sum, item) => sum + nutritionForItem(item).protein,
    );
  }

  double totalCarbs(Iterable<FoodItem> items) {
    return items.fold<double>(
      0,
      (sum, item) => sum + nutritionForItem(item).carbs,
    );
  }

  double totalFat(Iterable<FoodItem> items) {
    return items.fold<double>(
      0,
      (sum, item) => sum + nutritionForItem(item).fat,
    );
  }
}
