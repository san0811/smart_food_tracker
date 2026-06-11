import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/food_item.dart';
import '../models/nutrition.dart';
import '../services/barcode_service.dart';
import '../services/nutrition_service.dart';

class FoodProvider extends ChangeNotifier {
  FoodProvider({
    DatabaseHelper? databaseHelper,
    BarcodeService? barcodeService,
    NutritionService? nutritionService,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       _barcodeService = barcodeService ?? BarcodeService(),
       _nutritionService = nutritionService ?? NutritionService();

  final DatabaseHelper _databaseHelper;
  final BarcodeService _barcodeService;
  final NutritionService _nutritionService;

  final List<FoodItem> _items = [];

  bool _isLoading = false;
  String? _errorMessage;
  FoodItem? _latestLookup;

  List<FoodItem> get items => List.unmodifiable(_items);

  List<FoodItem> get availableItems =>
      _items.where((item) => item.isInInventory).toList();

  List<FoodItem> get archivedItems =>
      _items.where((item) => !item.isInInventory).toList();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  FoodItem? get latestLookup => _latestLookup;

  int get activeInventoryCount => availableItems.length;
  int get outOfStockCount => archivedItems.length;

  int get expiringSoonCount {
    final now = DateTime.now();
    return availableItems.where((item) {
      final expiry = DateTime.tryParse(item.expiryDate ?? '');
      if (expiry == null) {
        return false;
      }
      final difference = expiry.difference(now).inDays;
      return difference >= 0 && difference <= 2;
    }).length;
  }

  double get totalCalories => _nutritionService.dailyCalories(availableItems);
  double get totalProtein => _nutritionService.totalProtein(availableItems);
  double get totalCarbs => _nutritionService.totalCarbs(availableItems);
  double get totalFat => _nutritionService.totalFat(availableItems);

  Future<void> loadItems() async {
    _setLoading(true);
    try {
      _items
        ..clear()
        ..addAll(await _databaseHelper.getFoodItems());
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<FoodItem?> lookupBarcode(String barcode) async {
    _setLoading(true);
    try {
      final item = await _barcodeService.fetchProduct(barcode);
      _latestLookup = item;
      _errorMessage = null;
      return item;
    } catch (error) {
      _latestLookup = null;
      _errorMessage = error.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveLatestLookup() async {
    final lookup = _latestLookup;
    if (lookup == null) {
      return;
    }

    _setLoading(true);
    try {
      final saved = await _databaseHelper.saveScannedItem(lookup);
      final index = _items.indexWhere((item) => item.id == saved.id);
      if (index == -1) {
        _items.insert(0, saved);
      } else {
        _items[index] = saved;
      }
      _latestLookup = saved;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<FoodItem?> addManualItem({
    required String name,
    required String category,
    required String quantityLabel,
    String? brand,
    String? expiryDate,
    double calories = 0,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
  }) async {
    final now = DateTime.now();
    final manualItem = FoodItem(
      name: name,
      category: category,
      quantityLabel: quantityLabel,
      source: 'manual',
      createdAt: now,
      updatedAt: now,
      brand: brand,
      expiryDate: expiryDate,
      nutrition: Nutrition(
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      ),
      isInInventory: true,
    );

    _setLoading(true);
    try {
      final id = await _databaseHelper.insertFoodItem(manualItem);
      final saved = manualItem.copyWith(id: id);
      _items.insert(0, saved);
      _errorMessage = null;
      notifyListeners();
      return saved;
    } catch (error) {
      _errorMessage = error.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleInventoryStatus(FoodItem item) async {
    if (item.id == null) {
      return;
    }

    final updated = item.copyWith(
      isInInventory: !item.isInInventory,
      updatedAt: DateTime.now(),
    );

    await _databaseHelper.updateInventoryStatus(
      id: item.id!,
      isInInventory: updated.isInInventory,
    );

    final index = _items.indexWhere((entry) => entry.id == item.id);
    if (index != -1) {
      _items[index] = updated;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
