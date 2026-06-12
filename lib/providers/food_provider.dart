import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../services/expiry_notification_service.dart';
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

  Future<void> saveLatestLookup({String? expiryDate, int quantity = 1}) async {
    final lookup = _latestLookup;
    if (lookup == null) {
      return;
    }

    final itemToSave = lookup.copyWith(
      expiryDate: expiryDate ?? lookup.expiryDate,
      quantityLabel: _buildQuantityLabel(lookup.quantityLabel, quantity),
      updatedAt: DateTime.now(),
    );

    _setLoading(true);
    try {
      final saved = await _databaseHelper.saveScannedItem(itemToSave);
      final index = _items.indexWhere((item) => item.id == saved.id);
      if (index == -1) {
        _items.insert(0, saved);
      } else {
        _items[index] = saved;
      }
      _latestLookup = saved;
      _errorMessage = null;
      await refreshExpiryNotifications();
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
      await refreshExpiryNotifications();
      return saved;
    } catch (error) {
      _errorMessage = error.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<FoodItem?> updateFoodItem({
    required FoodItem item,
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
    if (item.id == null) {
      return null;
    }

    final updated = FoodItem(
      id: item.id,
      name: name,
      category: category,
      quantityLabel: quantityLabel,
      source: item.source,
      createdAt: item.createdAt,
      updatedAt: DateTime.now(),
      barcode: item.barcode,
      brand: brand,
      expiryDate: expiryDate,
      imageUrl: item.imageUrl,
      nutrition: Nutrition(
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      ),
      isInInventory: item.isInInventory,
    );

    _setLoading(true);
    try {
      await _databaseHelper.updateFoodItem(updated);
      final index = _items.indexWhere((entry) => entry.id == item.id);
      if (index != -1) {
        _items[index] = updated;
      }
      _items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _errorMessage = null;
      notifyListeners();
      await refreshExpiryNotifications();
      return updated;
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

    if (!updated.isInInventory) {
      await refreshExpiryNotifications();
    }

    final index = _items.indexWhere((entry) => entry.id == item.id);
    if (index != -1) {
      _items[index] = updated;
      notifyListeners();
      await refreshExpiryNotifications();
    }
  }

  Future<FoodItem?> useInventoryItem({
    required FoodItem item,
    required int quantityUsed,
  }) async {
    if (item.id == null) {
      return null;
    }

    final usedQuantity = quantityUsed.clamp(1, item.stockCount);
    final now = DateTime.now();
    final detail = _quantityDetail(item);
    final remainingQuantity = item.stockCount - usedQuantity;

    _setLoading(true);
    try {
      if (remainingQuantity <= 0) {
        await _databaseHelper.updateInventoryStatus(
          id: item.id!,
          isInInventory: false,
        );
      await loadItems();
      await refreshExpiryNotifications();
        _errorMessage = null;
        return item.copyWith(isInInventory: false, updatedAt: now);
      }

      final updatedActive = item.copyWith(
        quantityLabel: _buildQuantityLabel(detail, remainingQuantity),
        updatedAt: now,
      );
      await _databaseHelper.updateFoodItem(updatedActive);

      final usedEntry = FoodItem(
        name: item.name,
        category: item.category,
        quantityLabel: _buildQuantityLabel(detail, usedQuantity),
        source: item.source,
        createdAt: now,
        updatedAt: now,
        barcode: item.barcode,
        brand: item.brand,
        expiryDate: item.expiryDate,
        imageUrl: item.imageUrl,
        nutrition: item.nutrition,
        isInInventory: false,
      );
      final usedId = await _databaseHelper.insertFoodItem(usedEntry);
      final archivedUsed = usedEntry.copyWith(id: usedId);

      await loadItems();
      _errorMessage = null;
      return archivedUsed;
    } catch (error) {
      _errorMessage = error.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> refreshExpiryNotifications() async {
    try {
      await ExpiryNotificationService.instance.syncFromInventory(_items);
    } catch (_) {
      // Notification sync should never break inventory updates.
    }
  }

  String _buildQuantityLabel(String baseLabel, int quantity) {
    final normalizedBase = baseLabel.replaceFirst(
      RegExp(r'^\d+\s*x\s+', caseSensitive: false),
      '',
    );
    return '${quantity.clamp(1, 999)} x $normalizedBase';
  }

  String _quantityDetail(FoodItem item) {
    final match = RegExp(
      r'^\s*\d+\s*x\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(item.quantityLabel);
    final detail = match?.group(1)?.trim();
    if (detail != null && detail.isNotEmpty) {
      return detail;
    }

    final fallback = item.packageDetail.trim();
    if (fallback.isEmpty || fallback == 'Item detail not set') {
      return 'item';
    }

    return fallback;
  }
}
