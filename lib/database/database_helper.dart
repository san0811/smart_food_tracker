import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../config/app_constants.dart';
import '../models/food_item.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${AppConstants.foodItemsTable} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            barcode TEXT,
            brand TEXT,
            category TEXT NOT NULL,
            quantity_label TEXT NOT NULL,
            expiry_date TEXT,
            image_url TEXT,
            calories REAL NOT NULL DEFAULT 0,
            protein REAL NOT NULL DEFAULT 0,
            carbs REAL NOT NULL DEFAULT 0,
            fat REAL NOT NULL DEFAULT 0,
            is_in_inventory INTEGER NOT NULL DEFAULT 1,
            source TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<FoodItem>> getFoodItems() async {
    final db = await database;
    final maps = await db.query(
      AppConstants.foodItemsTable,
      orderBy: 'updated_at DESC',
    );

    return maps.map(FoodItem.fromMap).toList();
  }

  Future<int> insertFoodItem(FoodItem item) async {
    final db = await database;
    return db.insert(AppConstants.foodItemsTable, item.toMap());
  }

  Future<int> updateFoodItem(FoodItem item) async {
    final db = await database;
    return db.update(
      AppConstants.foodItemsTable,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<FoodItem?> findByBarcode(String barcode) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.foodItemsTable,
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return FoodItem.fromMap(maps.first);
  }

  Future<FoodItem> saveScannedItem(FoodItem item) async {
    final existing = item.barcode == null
        ? null
        : await findByBarcode(item.barcode!);

    if (existing == null) {
      final id = await insertFoodItem(item);
      return item.copyWith(id: id);
    }

    final merged = item.copyWith(
      id: existing.id,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      isInInventory: true,
    );
    await updateFoodItem(merged);
    return merged;
  }

  Future<void> updateInventoryStatus({
    required int id,
    required bool isInInventory,
  }) async {
    final db = await database;
    await db.update(
      AppConstants.foodItemsTable,
      {
        'is_in_inventory': isInInventory ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
