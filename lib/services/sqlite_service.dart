import 'dart:convert';
import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SqliteService {
  static final SqliteService _instance = SqliteService._internal();
  static Database? _database;

  SqliteService._internal();

  factory SqliteService() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'aikitchen.db');

    return await openDatabase(
      path,
      version: 2, // Subimos versión para añadir la tabla preferences
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE preferences (
              preference TEXT PRIMARY KEY,
              value TEXT
            )
          ''');
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE shopping_list (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        isPurchased INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE fav_recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        tiempo_estimado TEXT NOT NULL,
        ingredientes TEXT NOT NULL,
        preparacion TEXT NOT NULL,
        calorias REAL NOT NULL,
        raciones INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE menu (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        tiempo_estimado TEXT NOT NULL,
        ingredientes TEXT NOT NULL,
        preparacion TEXT NOT NULL,
        calorias REAL NOT NULL,
        raciones INTEGER NOT NULL,
        dia TEXT NOT NULL,
        tipo_comida TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE preferences (
        preference TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // --- DAO Preferences ---
  Future<String?> getByPreference(String preference) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'preferences',
      where: 'preference = ?',
      whereArgs: [preference],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<int> editPreference(String preference, String value) async {
    final db = await database;
    return await db.insert(
      'preferences',
      {'preference': preference, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteByPreference(String preference) async {
    final db = await database;
    return await db.delete(
      'preferences',
      where: 'preference = ?',
      whereArgs: [preference],
    );
  }

  Future<int> deletePreference() async {
    final db = await database;
    return await db.delete('preferences');
  }

  // --- DAO Shopping List ---
  Future<int> insertCartItem(CartItem item) async {
    final db = await database;
    return await db.insert('shopping_list', item.toMap());
  }

  Future<List<CartItem>> getCartItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('shopping_list');
    return maps.map((map) => CartItem.fromMap(map)).toList();
  }

  Future<int> updateCartItem(CartItem item) async {
    final db = await database;
    return await db.update(
      'shopping_list',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteCartItem(int id) async {
    final db = await database;
    return await db.delete('shopping_list', where: 'id = ?', whereArgs: [id]);
  }

  // --- DAO Favorite Recipes ---
  Future<int> insertFavRecipe(Recipe recipe) async {
    final db = await database;
    return await db.insert('fav_recipes', recipe.toMap());
  }

  Future<List<Recipe>> getFavRecipes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('fav_recipes');
    return maps.map((map) => Recipe.fromMap(map)).toList();
  }

  Future<int> updateFavRecipe(Recipe recipe) async {
    final db = await database;
    return await db.update(
      'fav_recipes',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  Future<int> deleteFavRecipe(int id) async {
    final db = await database;
    return await db.delete('fav_recipes', where: 'id = ?', whereArgs: [id]);
  }

  // --- DAO Menu ---
  Future<int> insertMenuRecipe(Recipe recipe, String dia, String tipoComida) async {
    final db = await database;
    final map = recipe.toMap();
    map['dia'] = dia;
    map['tipo_comida'] = tipoComida;
    return await db.insert('menu', map);
  }

  Future<Map<String, List<Recipe>>> getWeeklyMenu() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('menu');
    
    Map<String, List<Recipe>> weeklyMenu = {};
    for (var map in maps) {
      final dia = map['dia'] as String;
      final recipe = Recipe.fromMap(map);
      if (!weeklyMenu.containsKey(dia)) {
        weeklyMenu[dia] = [];
      }
      weeklyMenu[dia]!.add(recipe);
    }
    return weeklyMenu;
  }

  Future<void> clearMenu() async {
    final db = await database;
    await db.delete('menu');
  }
}
