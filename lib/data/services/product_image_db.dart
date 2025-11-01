import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ProductImage {
  final int? id;
  final String base64Image;
  final String? productId;

  ProductImage({this.id, required this.base64Image, this.productId});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'base64Image': base64Image,
      'productId': productId,
    };
  }

  factory ProductImage.fromMap(Map<String, dynamic> map) {
    return ProductImage(
      id: map['id'],
      base64Image: map['base64Image'],
      productId: map['productId'],
    );
  }
}

class ProductImageDatabase {
  static final ProductImageDatabase instance = ProductImageDatabase._init();
  static Database? _database;

  ProductImageDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('product_images.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE product_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        base64Image TEXT NOT NULL,
        productId TEXT
      )
    ''');
  }

  Future<int> insertImage(ProductImage image) async {
    final db = await instance.database;
    return await db.insert('product_images', image.toMap());
  }

  Future<List<ProductImage>> getImages({String? productId}) async {
    final db = await instance.database;
    final maps = await db.query('product_images',
        where: productId != null ? 'productId = ?' : null,
        whereArgs: productId != null ? [productId] : null);
    return maps.map((e) => ProductImage.fromMap(e)).toList();
  }

  Future<int> deleteImage(int id) async {
    final db = await instance.database;
    return await db.delete('product_images', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
