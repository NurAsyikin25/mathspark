import 'package:flutter_test/flutter_test.dart';
import 'package:mathspark/services/gamification_service.dart';

void main() {
  group('GamificationService - Perhitungan Skor & XP Tests', () {
    late GamificationService gamificationService;

    setUp(() {
      gamificationService = GamificationService();
    });

    test('hitungSkor menghasilkan persentase 0-100 dengan tepat', () {
      expect(gamificationService.hitungSkor(totalBenar: 5, totalSoal: 5), 100);
      expect(gamificationService.hitungSkor(totalBenar: 4, totalSoal: 5), 80);
      expect(gamificationService.hitungSkor(totalBenar: 3, totalSoal: 5), 60);
      expect(gamificationService.hitungSkor(totalBenar: 0, totalSoal: 5), 0);
      expect(gamificationService.hitungSkor(totalBenar: 0, totalSoal: 0), 0);
    });

    test('hitungSkor menangani pembulatan desimal dengan baik', () {
      // 2 dari 3 soal = 66.666% -> round to 67
      expect(gamificationService.hitungSkor(totalBenar: 2, totalSoal: 3), 67);
      // 1 dari 3 soal = 33.333% -> round to 33
      expect(gamificationService.hitungSkor(totalBenar: 1, totalSoal: 3), 33);
    });

    test('Batas lulus kuis adalah skor >= 70', () {
      final skorLulus1 = gamificationService.hitungSkor(totalBenar: 4, totalSoal: 5); // 80
      final skorLulus2 = gamificationService.hitungSkor(totalBenar: 7, totalSoal: 10); // 70
      final skorGagal = gamificationService.hitungSkor(totalBenar: 3, totalSoal: 5); // 60

      expect(skorLulus1 >= 70, isTrue);
      expect(skorLulus2 >= 70, isTrue);
      expect(skorGagal >= 70, isFalse);
    });
  });
}
