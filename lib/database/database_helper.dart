import 'dart:convert';
import 'dart:io' show Platform;

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

import '../config/app_constants.dart';
import '../models/food_item.dart';
import '../models/expiry_notification_settings.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  sqflite.Database? _database;

  Future<sqflite.Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<sqflite.Database> _initDatabase() async {
    final dbPath = await _databaseFactory.getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    return _databaseFactory.openDatabase(
      path,
      options: ffi.OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await _createFoodItemsTable(db);
          await _createSettingsTable(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createSettingsTable(db);
          }
        },
      ),
    );
  }

  Future<void> _createFoodItemsTable(sqflite.DatabaseExecutor db) async {
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
  }

  Future<void> _createSettingsTable(sqflite.DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.appSettingsTable} (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  sqflite.DatabaseFactory get _databaseFactory {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return ffi.databaseFactoryFfi;
    }

    return sqflite.databaseFactory;
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
      where: 'barcode = ? AND is_in_inventory = 1',
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

    final mergedQuantity = existing.stockCount + item.stockCount;
    final mergedExpiryDate = _pickExpiryDate(existing.expiryDate, item.expiryDate);
    final merged = item.copyWith(
      id: existing.id,
      quantityLabel: _buildQuantityLabel(existing.packageDetail, mergedQuantity),
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      expiryDate: mergedExpiryDate,
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

  Future<ExpiryNotificationSettings> getExpiryNotificationSettings() async {
    final db = await database;
    final rows = await db.query(AppConstants.appSettingsTable);
    final values = <String, String>{
      for (final row in rows)
        if (row['key'] != null && row['value'] != null)
          row['key'] as String: row['value'] as String,
    };

    final defaults = ExpiryNotificationSettings.defaults();
    final enabled = values['expiry_alerts_enabled'] == null
        ? defaults.enabled
        : values['expiry_alerts_enabled'] == 'true';

    final reminderDays = _parseReminderDays(values['expiry_reminder_days']) ??
        defaults.reminderDays;
    final normalizedReminderDays = enabled
        ? reminderDays.intersection({7, 5, 3})
        : reminderDays.intersection({7, 5, 3});
    final finalReminderDays = normalizedReminderDays.isEmpty
        ? defaults.reminderDays
        : normalizedReminderDays;

    return ExpiryNotificationSettings(
      enabled: enabled,
      reminderDays: finalReminderDays,
    );
  }

  Future<void> saveExpiryNotificationSettings(
    ExpiryNotificationSettings settings,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        AppConstants.appSettingsTable,
        {
          'key': 'expiry_alerts_enabled',
          'value': settings.enabled ? 'true' : 'false',
        },
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );

      final reminderDays = settings.reminderDays.toList()..sort();
      await txn.insert(
        AppConstants.appSettingsTable,
        {
          'key': 'expiry_reminder_days',
          'value': jsonEncode(reminderDays),
        },
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    });
  }

  Set<int>? _parseReminderDays(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) {
        return null;
      }

      final parsed = decoded
          .map((entry) => int.tryParse(entry.toString()))
          .whereType<int>()
          .toSet();
      return parsed.isEmpty ? null : parsed;
    } catch (_) {
      return null;
    }
  }

  String _buildQuantityLabel(String baseDetail, int quantity) {
    final detail = baseDetail.trim().isEmpty ? 'item' : baseDetail.trim();
    return '${quantity.clamp(1, 999)} x $detail';
  }

  String? _pickExpiryDate(String? existing, String? incoming) {
    final existingDate = DateTime.tryParse(existing ?? '');
    final incomingDate = DateTime.tryParse(incoming ?? '');

    if (existingDate == null) {
      return incoming;
    }

    if (incomingDate == null) {
      return existing;
    }

    return incomingDate.isBefore(existingDate) ? incoming : existing;
  }
}
