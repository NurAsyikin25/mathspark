import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/modul.dart';
import '../models/soal_kuis.dart';
import '../models/hasil_kuis.dart';
import '../models/profil_siswa.dart';
import '../models/reward.dart';
import 'seed_data.dart';

class DatabaseHelper {
  static const String _databaseName = 'mathspark.db';
  static const int _databaseVersion = 1;

  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  factory DatabaseHelper() => instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabel modul
    await db.execute('''
      CREATE TABLE modul (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        judul TEXT NOT NULL,
        deskripsi TEXT NOT NULL,
        isLocked INTEGER NOT NULL DEFAULT 1,
        kontenJson TEXT NOT NULL,
        urutan INTEGER NOT NULL
      )
    ''');

    // 2. Tabel soal_kuis
    await db.execute('''
      CREATE TABLE soal_kuis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        modulId INTEGER NOT NULL,
        pertanyaan TEXT NOT NULL,
        opsiJawaban TEXT NOT NULL,
        kunciJawaban INTEGER NOT NULL,
        FOREIGN KEY (modulId) REFERENCES modul (id) ON DELETE CASCADE
      )
    ''');

    // 3. Tabel hasil_kuis
    await db.execute('''
      CREATE TABLE hasil_kuis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        modulId INTEGER NOT NULL,
        skorTerakhir INTEGER NOT NULL,
        jawabanSiswa TEXT NOT NULL,
        feedbackAI TEXT NOT NULL,
        dikerjakanAt TEXT NOT NULL,
        FOREIGN KEY (modulId) REFERENCES modul (id) ON DELETE CASCADE
      )
    ''');

    // 4. Tabel profil_siswa
    await db.execute('''
      CREATE TABLE profil_siswa (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        namaSiswa TEXT NOT NULL,
        totalXP INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // 5. Tabel reward
    await db.execute('''
      CREATE TABLE reward (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        namaBadge TEXT NOT NULL,
        deskripsi TEXT NOT NULL,
        kondisi TEXT NOT NULL,
        sudahDapat INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Seed data awal
    await SeedData.seed(db);
  }

  // ==========================================
  // CRUD: PROFIL SISWA
  // ==========================================

  /// Mengambil data profil siswa (record pertama jika ada).
  Future<ProfilSiswa?> getProfil() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'profil_siswa',
      limit: 1,
    );

    if (results.isNotEmpty) {
      return ProfilSiswa.fromMap(results.first);
    }
    return null;
  }

  /// Menyimpan atau memperbarui data profil siswa (upsert).
  /// Jika profil sudah ada di database, akan diperbarui; jika belum, akan dibuat baru.
  Future<int> upsertProfil(ProfilSiswa profil) async {
    final db = await database;

    final List<Map<String, dynamic>> existing = profil.id != null
        ? await db.query('profil_siswa', where: 'id = ?', whereArgs: [profil.id], limit: 1)
        : await db.query('profil_siswa', limit: 1);

    if (existing.isNotEmpty) {
      final existingId = existing.first['id'] as int;
      final data = profil.toMap();
      data['id'] = existingId;

      await db.update(
        'profil_siswa',
        data,
        where: 'id = ?',
        whereArgs: [existingId],
      );
      return existingId;
    } else {
      return await db.insert('profil_siswa', profil.toMap());
    }
  }

  // ==========================================
  // CRUD: MODUL
  // ==========================================

  /// Mengambil seluruh modul terurut berdasarkan kolom urutan ASC.
  Future<List<Modul>> getAllModul() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'modul',
      orderBy: 'urutan ASC',
    );

    return results.map((map) => Modul.fromMap(map)).toList();
  }

  /// Membuka kunci modul (mengubah isLocked menjadi 0 / false).
  Future<int> unlockModul(int modulId) async {
    final db = await database;
    return await db.update(
      'modul',
      {'isLocked': 0},
      where: 'id = ?',
      whereArgs: [modulId],
    );
  }

  /// Menambahkan modul baru.
  Future<int> insertModul(Modul modul) async {
    final db = await database;
    return await db.insert('modul', modul.toMap());
  }

  // ==========================================
  // CRUD: SOAL KUIS
  // ==========================================

  /// Mengambil daftar soal kuis berdasarkan modulId.
  Future<List<SoalKuis>> getSoalByModul(int modulId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'soal_kuis',
      where: 'modulId = ?',
      whereArgs: [modulId],
    );

    return results.map((map) => SoalKuis.fromMap(map)).toList();
  }

  /// Menambahkan soal kuis baru.
  Future<int> insertSoalKuis(SoalKuis soal) async {
    final db = await database;
    return await db.insert('soal_kuis', soal.toMap());
  }

  // ==========================================
  // CRUD: HASIL KUIS
  // ==========================================

  /// Menyimpan atau memperbarui hasil kuis.
  /// Aturan:
  /// - Hanya timpa skorTerakhir jika skor baru lebih tinggi dari skor yang tersimpan.
  /// - Tetap perbarui feedbackAI, jawabanSiswa, dan dikerjakanAt.
  Future<int> simpanAtauUpdateHasilKuis(HasilKuis hasilKuis) async {
    final db = await database;

    final List<Map<String, dynamic>> existing = hasilKuis.id != null
        ? await db.query(
            'hasil_kuis',
            where: 'id = ?',
            whereArgs: [hasilKuis.id],
            limit: 1,
          )
        : await db.query(
            'hasil_kuis',
            where: 'modulId = ?',
            whereArgs: [hasilKuis.modulId],
            limit: 1,
          );

    if (existing.isNotEmpty) {
      final existingRecord = existing.first;
      final existingId = existingRecord['id'] as int;
      final existingSkor = existingRecord['skorTerakhir'] as int? ?? 0;

      // Hanya timpa skor jika skor baru lebih tinggi
      final finalSkor = hasilKuis.skorTerakhir > existingSkor
          ? hasilKuis.skorTerakhir
          : existingSkor;

      final dataToUpdate = hasilKuis.toMap();
      dataToUpdate['id'] = existingId;
      dataToUpdate['skorTerakhir'] = finalSkor;

      await db.update(
        'hasil_kuis',
        dataToUpdate,
        where: 'id = ?',
        whereArgs: [existingId],
      );
      return existingId;
    } else {
      return await db.insert('hasil_kuis', hasilKuis.toMap());
    }
  }

  /// Mengambil seluruh riwayat hasil kuis.
  Future<List<HasilKuis>> getAllHasilKuis() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query('hasil_kuis');

    return results.map((map) => HasilKuis.fromMap(map)).toList();
  }

  /// Mengambil hasil kuis untuk modul tertentu jika ada.
  Future<HasilKuis?> getHasilKuisByModul(int modulId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'hasil_kuis',
      where: 'modulId = ?',
      whereArgs: [modulId],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return HasilKuis.fromMap(results.first);
    }
    return null;
  }

  // ==========================================
  // CRUD: REWARD
  // ==========================================

  /// Mengambil seluruh daftar reward/badge.
  Future<List<Reward>> getAllReward() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query('reward');

    return results.map((map) => Reward.fromMap(map)).toList();
  }

  /// Membuka / mengklaim reward (mengubah sudahDapat menjadi 1 / true).
  Future<int> unlockReward(int rewardId) async {
    final db = await database;
    return await db.update(
      'reward',
      {'sudahDapat': 1},
      where: 'id = ?',
      whereArgs: [rewardId],
    );
  }

  /// Menambahkan reward baru.
  Future<int> insertReward(Reward reward) async {
    final db = await database;
    return await db.insert('reward', reward.toMap());
  }

  // ==========================================
  // UTILITY / CLOSE
  // ==========================================

  /// Menutup koneksi database.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
