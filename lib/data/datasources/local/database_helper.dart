import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:loker_kabur_aja_dulu/data/models/lowongan_model.dart'; // Model dari API
// import 'package:loker_kabur_aja_dulu/data/models/kos_model.dart';     // Model dari API

// Model Lokal (akan kita buat di file terpisah)
import 'package:loker_kabur_aja_dulu/data/models/lowongan_disimpan_model.dart';
import 'package:loker_kabur_aja_dulu/data/models/kos_disimpan_model.dart';
import 'package:loker_kabur_aja_dulu/data/models/saldo_user_model.dart';
import 'package:loker_kabur_aja_dulu/data/models/kos_dipesan_model.dart';


class DatabaseHelper {
  static const _databaseName = "KaburAjaDulu.db";
  static const _databaseVersion = 1;

  // Nama tabel
  static const String tableLowonganDisimpan = 'lowongan_disimpan';
  static const String tableKosDisimpan = 'kos_disimpan';
  static const String tableSaldoUser = 'saldo_user';
  static const String tableKosDipesan = 'kos_dipesan';

  // Singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableLowonganDisimpan (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        nama_perusahaan TEXT,
        deskripsi_lowongan TEXT,
        rentang_gaji TEXT,
        alamat TEXT,
        latitude REAL,
        longitude REAL,
        jenisPenempatan TEXT,
        contact_email TEXT,
        hrd_yang_post_id TEXT,
        waktu_simpan TEXT NOT NULL 
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableKosDisimpan (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        nama_kos TEXT,
        alamat TEXT,
        harga_perbulan REAL,
        mata_uang_yang_dipakai TEXT,
        foto_kos TEXT,
        latitude REAL,
        longitude REAL,
        waktu_simpan TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableSaldoUser (
        userId TEXT PRIMARY KEY,
        saldo REAL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableKosDipesan (
        id_pemesanan INTEGER PRIMARY KEY AUTOINCREMENT,
        kosId TEXT NOT NULL,
        userId TEXT NOT NULL,
        nama_kos TEXT,
        alamat TEXT,
        harga_perbulan REAL,
        harga_dp_dibayar REAL,
        mata_uang_yang_dipakai TEXT,
        foto_kos TEXT,
        latitude REAL,
        longitude REAL,
        tanggal_pesan TEXT NOT NULL,
        kontak_pemilik_kos TEXT,
        email_pemilik_kos TEXT
      )
    ''');
  }

  // --- Operasi untuk LowonganDisimpan ---
  Future<int> simpanLowongan(LowonganDisimpanModel lowongan) async {
    Database db = await instance.database;
    return await db.insert(tableLowonganDisimpan, lowongan.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<LowonganDisimpanModel>> getLowonganDisimpan(String userId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableLowonganDisimpan, 
      where: 'userId = ?', 
      whereArgs: [userId],
      orderBy: 'waktu_simpan DESC'
    );
    return List.generate(maps.length, (i) => LowonganDisimpanModel.fromMap(maps[i]));
  }

  Future<int> hapusLowonganDisimpan(String id, String userId) async {
    Database db = await instance.database;
    return await db.delete(tableLowonganDisimpan, where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }

  Future<bool> isLowonganDisimpan(String id, String userId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableLowonganDisimpan,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  // --- Operasi untuk KosDisimpan ---
  Future<int> simpanKos(KosDisimpanModel kos) async {
    Database db = await instance.database;
    return await db.insert(tableKosDisimpan, kos.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<KosDisimpanModel>> getKosDisimpan(String userId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableKosDisimpan, 
      where: 'userId = ?', 
      whereArgs: [userId],
      orderBy: 'waktu_simpan DESC'
    );
    return List.generate(maps.length, (i) => KosDisimpanModel.fromMap(maps[i]));
  }

  Future<int> hapusKosDisimpan(String id, String userId) async {
    Database db = await instance.database;
    return await db.delete(tableKosDisimpan, where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }

  Future<bool> isKosDisimpan(String id, String userId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableKosDisimpan,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  // --- Operasi untuk SaldoUser ---
  Future<SaldoUserModel?> getSaldoUser(String userId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(tableSaldoUser, where: 'userId = ?', whereArgs: [userId]);
    if (maps.isNotEmpty) {
      return SaldoUserModel.fromMap(maps.first);
    }
    // Jika user belum ada, buatkan entry saldo awal 0
    await db.insert(tableSaldoUser, SaldoUserModel(userId: userId, saldo: 0).toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    return SaldoUserModel(userId: userId, saldo: 0);
  }

  Future<int> updateSaldoUser(String userId, double jumlahPerubahan) async {
    Database db = await instance.database;
    // Dapatkan saldo saat ini
    SaldoUserModel? saldoSaatIni = await getSaldoUser(userId);
    double saldoBaru = (saldoSaatIni?.saldo ?? 0) + jumlahPerubahan;
    
    if (saldoBaru < 0) {
        // Untuk mencegah saldo negatif jika itu adalah aturan bisnis
        // throw Exception("Saldo tidak mencukupi"); 
        // Atau biarkan negatif jika memang diperbolehkan
    }

    return await db.update(
      tableSaldoUser,
      {'saldo': saldoBaru},
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // --- Operasi untuk KosDipesan ---
  Future<int> pesanKos(KosDipesanModel pesanan) async {
    Database db = await instance.database;
    return await db.insert(tableKosDipesan, pesanan.toMap());
  }

  Future<List<KosDipesanModel>> getKosDipesan(String userId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableKosDipesan, 
      where: 'userId = ?', 
      whereArgs: [userId],
      orderBy: 'tanggal_pesan DESC'
    );
    return List.generate(maps.length, (i) => KosDipesanModel.fromMap(maps[i]));
  }
  
  // Anda bisa menambahkan metode lain seperti update atau delete jika diperlukan
}