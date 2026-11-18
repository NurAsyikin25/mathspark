import 'package:flutter_test/flutter_test.dart';
import 'package:mathspark/models/modul.dart';
import 'package:mathspark/models/soal_kuis.dart';
import 'package:mathspark/models/hasil_kuis.dart';
import 'package:mathspark/models/profil_siswa.dart';
import 'package:mathspark/models/reward.dart';

void main() {
  group('Model Serialization Tests', () {
    test('Modul toMap and fromMap', () {
      final modul = Modul(
        id: 1,
        judul: 'Logika Proposisi',
        deskripsi: 'Belajar tabel kebenaran',
        isLocked: false,
        kontenJson: '{"section": 1}',
        urutan: 1,
      );

      final map = modul.toMap();
      expect(map['isLocked'], 0);
      expect(map['judul'], 'Logika Proposisi');

      final fromMap = Modul.fromMap(map);
      expect(fromMap.id, 1);
      expect(fromMap.isLocked, false);
      expect(fromMap.kontenJson, '{"section": 1}');
    });

    test('SoalKuis toMap and fromMap', () {
      final soal = SoalKuis(
        id: 10,
        modulId: 1,
        pertanyaan: 'Apa itu negasi?',
        opsiJawaban: ['Pembalikan', 'Penggabungan', 'Implikasi', 'Disjungsi'],
        kunciJawaban: 0,
      );

      final map = soal.toMap();
      expect(map['opsiJawaban'], isA<String>());

      final fromMap = SoalKuis.fromMap(map);
      expect(fromMap.opsiJawaban.length, 4);
      expect(fromMap.opsiJawaban[0], 'Pembalikan');
      expect(fromMap.kunciJawaban, 0);
    });

    test('HasilKuis toMap and fromMap', () {
      final now = DateTime.now();
      final hasil = HasilKuis(
        id: 5,
        modulId: 1,
        skorTerakhir: 85,
        jawabanSiswa: {0: 1, 1: 0, 2: 3},
        feedbackAI: 'Hebat, pemahaman logika sudah baik!',
        dikerjakanAt: now,
      );

      final map = hasil.toMap();
      expect(map['jawabanSiswa'], isA<String>());
      expect(map['dikerjakanAt'], isA<String>());

      final fromMap = HasilKuis.fromMap(map);
      expect(fromMap.jawabanSiswa[0], 1);
      expect(fromMap.jawabanSiswa[2], 3);
      expect(fromMap.skorTerakhir, 85);
      expect(fromMap.feedbackAI, 'Hebat, pemahaman logika sudah baik!');
    });

    test('ProfilSiswa toMap and fromMap', () {
      final now = DateTime.now();
      final profil = ProfilSiswa(
        id: 1,
        namaSiswa: 'Budi PPLG',
        totalXP: 250,
        createdAt: now,
      );

      final map = profil.toMap();
      final fromMap = ProfilSiswa.fromMap(map);
      expect(fromMap.namaSiswa, 'Budi PPLG');
      expect(fromMap.totalXP, 250);
    });

    test('Reward toMap and fromMap', () {
      final reward = Reward(
        id: 1,
        namaBadge: 'Logika Master',
        deskripsi: 'Menyelesaikan modul logika',
        kondisi: 'skor >= 80',
        sudahDapat: true,
      );

      final map = reward.toMap();
      expect(map['sudahDapat'], 1);

      final fromMap = Reward.fromMap(map);
      expect(fromMap.sudahDapat, true);
      expect(fromMap.namaBadge, 'Logika Master');
    });
  });
}
