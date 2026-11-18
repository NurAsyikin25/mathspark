import '../database/database_helper.dart';
import '../models/modul.dart';
import '../models/reward.dart';

/// Hasil eksekusi gamifikasi kuis
class GamificationResult {
  final int skor;
  final bool isLulus;
  final int xpEarned;
  final Modul? unlockedModul;
  final List<Reward> newlyUnlockedRewards;

  GamificationResult({
    required this.skor,
    required this.isLulus,
    required this.xpEarned,
    this.unlockedModul,
    this.newlyUnlockedRewards = const [],
  });
}

class GamificationService {
  final DatabaseHelper _dbHelper;

  GamificationService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Menghitung skor kuis dalam skala 0–100.
  int hitungSkor({required int totalBenar, required int totalSoal}) {
    if (totalSoal <= 0) return 0;
    final double rawSkor = (totalBenar / totalSoal) * 100;
    return rawSkor.round().clamp(0, 100);
  }

  /// Memproses aturan gamifikasi setelah kuis diselesaikan:
  /// 1. Hitung penambahan XP dan update ProfilSiswa.
  /// 2. Jika skor >= 70 (batas lulus), buka kunci modul urutan berikutnya.
  /// 3. Periksa dan buka Reward/Badge baru jika syarat terpenuhi.
  Future<GamificationResult> processQuizCompletion({
    required int modulId,
    required int skor,
    required int urutanModul,
  }) async {
    final bool isLulus = skor >= 70;

    // 1. Hitung perolehan XP
    // Jika lulus: dapat XP sebesar skor penuh (min 70 XP s.d. 100 XP)
    // Jika belum lulus: apresiasi usaha belajar sebesar separuh skor
    final int xpEarned = isLulus ? skor : (skor / 2).round();

    // Update XP di Profil Siswa
    final profil = await _dbHelper.getProfil();
    if (profil != null) {
      final updatedProfil = profil.copyWith(
        totalXP: profil.totalXP + xpEarned,
      );
      await _dbHelper.upsertProfil(updatedProfil);
    }

    // 2. Buka kunci modul urutan berikutnya jika lulus
    Modul? unlockedModul;
    if (isLulus) {
      final allModul = await _dbHelper.getAllModul();
      final nextUrutan = urutanModul + 1;
      final nextModulIndex = allModul.indexWhere((m) => m.urutan == nextUrutan);

      if (nextModulIndex != -1) {
        final targetModul = allModul[nextModulIndex];
        if (targetModul.isLocked && targetModul.id != null) {
          await _dbHelper.unlockModul(targetModul.id!);
          unlockedModul = targetModul.copyWith(isLocked: false);
        }
      }
    }

    // 3. Periksa dan buka Reward baru
    final newlyUnlockedRewards = await _checkAndUnlockRewards();

    return GamificationResult(
      skor: skor,
      isLulus: isLulus,
      xpEarned: xpEarned,
      unlockedModul: unlockedModul,
      newlyUnlockedRewards: newlyUnlockedRewards,
    );
  }

  /// Memeriksa seluruh kondisi reward berdasarkan riwayat hasil kuis dan modul.
  Future<List<Reward>> _checkAndUnlockRewards() async {
    final List<Reward> newlyUnlocked = [];

    final allRewards = await _dbHelper.getAllReward();
    final allHasil = await _dbHelper.getAllHasilKuis();
    final allModul = await _dbHelper.getAllModul();

    for (final reward in allRewards) {
      // Lewati jika reward sudah didapatkan sebelumnya
      if (reward.sudahDapat || reward.id == null) continue;

      bool syaratTerpenuhi = false;

      switch (reward.namaBadge) {
        case 'Langkah Pertama':
          // Selesaikan minimal 1 kuis pada modul apapun
          syaratTerpenuhi = allHasil.isNotEmpty;
          break;

        case 'Ahli Logika':
          // Raih skor minimal 80 pada kuis Modul 1 (Logika Matematika)
          final modul1 = allModul.cast<Modul?>().firstWhere(
                (m) => m?.urutan == 1,
                orElse: () => null,
              );
          if (modul1 != null) {
            syaratTerpenuhi = allHasil.any(
              (h) => h.modulId == modul1.id && h.skorTerakhir >= 80,
            );
          }
          break;

        case 'Penjelajah Aljabar':
          // Selesaikan kuis Modul 2 dan Modul 3 (skor >= 70)
          final modul2 = allModul.cast<Modul?>().firstWhere(
                (m) => m?.urutan == 2,
                orElse: () => null,
              );
          final modul3 = allModul.cast<Modul?>().firstWhere(
                (m) => m?.urutan == 3,
                orElse: () => null,
              );
          if (modul2 != null && modul3 != null) {
            final lulusModul2 = allHasil.any(
              (h) => h.modulId == modul2.id && h.skorTerakhir >= 70,
            );
            final lulusModul3 = allHasil.any(
              (h) => h.modulId == modul3.id && h.skorTerakhir >= 70,
            );
            syaratTerpenuhi = lulusModul2 && lulusModul3;
          }
          break;

        case 'Master MathSpark':
          // Buka dan selesaikan semua modul dengan skor masing-masing >= 80
          if (allModul.isNotEmpty) {
            syaratTerpenuhi = allModul.every((m) => allHasil.any(
                  (h) => h.modulId == m.id && h.skorTerakhir >= 80,
                ));
          }
          break;

        default:
          syaratTerpenuhi = false;
      }

      if (syaratTerpenuhi) {
        await _dbHelper.unlockReward(reward.id!);
        newlyUnlocked.add(reward.copyWith(sudahDapat: true));
      }
    }

    return newlyUnlocked;
  }
}
