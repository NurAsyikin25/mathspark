import 'dart:convert';
import 'package:sqflite/sqflite.dart';

class SeedData {
  /// Mengisi data awal ke database saat onCreate pertama kali dipanggil.
  static Future<void> seed(Database db) async {
    await db.transaction((txn) async {
      // =======================================================================
      // 1. SEED MODUL & SOAL KUIS
      // =======================================================================

      // -----------------------------------------------------------------------
      // MODUL 1: Logika Matematika (isLocked: false)
      // -----------------------------------------------------------------------
      final kontenModul1 = jsonEncode([
        {
          'judul': '1. Proposisi dan Negasi dalam Kode Program',
          'isi':
              'Dalam pemrograman, logika proposisi adalah dasar dari ekspresi boolean. Pernyataan (proposisi) adalah kalimat deklaratif yang bernilai Benar (True / 1) atau Salah (False / 0), tetapi tidak keduanya sekaligus.\n\nContoh dalam Dart:\nbool isUserAdmin = true;\n\nNegasi (ingkaran) dilambangkan dengan simbol ~p atau tanda seru (!) dalam pemrograman, yang membalikkan nilai kebenaran. Jika p bernilai Benar, maka ~p bernilai Salah.',
        },
        {
          'judul': '2. Konjungsi (AND) dan Disjungsi (OR)',
          'isi':
              'Konjungsi (p ∧ q atau operator &&):\nBernilai Benar HANYA JIKA kedua proposisi bernilai Benar. Jika salah satu bernilai Salah, maka hasilnya Salah.\n\nDisjungsi (p ∨ q atau operator ||):\nBernilai Benar jika MINIMAL SALAH SATU proposisi bernilai Benar. Hanya bernilai Salah jika kedua proposisi bernilai Salah.\n\nDalam aplikasi, ini digunakan misalnya saat validasi form: validasi = (emailValid && passwordValid);',
        },
        {
          'judul': '3. Implikasi dan Percabangan Kondisional',
          'isi':
              'Implikasi (p → q, dibaca: Jika p maka q):\np disebut anteseden (hipotesis) dan q disebut konsekuen (kesimpulan).\n\nImplikasi HANYA bernilai Salah jika p Benar tetapi q Salah (janji diingkari). Jika anteseden Salah, implikasi otomatis bernilai Benar.\n\nHubungan dengan percabangan:\nif (kondisiP) { jalankanQ(); }',
        },
        {
          'judul': '4. Ekuivalensi Logika dan Hukum De Morgan',
          'isi':
              'Dua pernyataan dikatakan ekuivalen jika memiliki nilai kebenaran yang sama pada semua kondisi.\n\nHukum De Morgan sangat krusial dalam refaktorisasi kode agar lebih efisien dan mudah dibaca:\n1. ~(p ∧ q) ≡ ~p ∨ ~q  =>  !(A && B) ekuivalen dengan (!A || !B)\n2. ~(p ∨ q) ≡ ~p ∧ ~q  =>  !(A || B) ekuivalen dengan (!A && !B)',
        },
      ]);

      final modul1Id = await txn.insert('modul', {
        'judul': 'Logika Matematika',
        'deskripsi':
            'Fondasi logika proposisi, tabel kebenaran, operasi boolean, dan Hukum De Morgan untuk percabangan algoritma pemrograman.',
        'isLocked': 0, // false
        'kontenJson': kontenModul1,
        'urutan': 1,
      });

      // Soal Modul 1 (5 soal)
      final soalModul1 = [
        {
          'modulId': modul1Id,
          'pertanyaan':
              'Manakah ingkaran (negasi) dari pernyataan: "Semua programmer memahami struktur data"?',
          'opsiJawaban': jsonEncode([
            'Tidak ada programmer yang memahami struktur data',
            'Beberapa programmer tidak memahami struktur data',
            'Semua programmer tidak memahami struktur data',
            'Programmer harus memahami struktur data',
          ]),
          'kunciJawaban': 1,
        },
        {
          'modulId': modul1Id,
          'pertanyaan':
              'Jika p bernilai Benar (True) dan q bernilai Salah (False), maka nilai kebenaran dari pernyataan p ∧ q (Konjungsi) adalah...',
          'opsiJawaban': jsonEncode([
            'Benar (True)',
            'Salah (False)',
            'Tidak terdefinisi',
            'Bisa Benar atau Salah',
          ]),
          'kunciJawaban': 1,
        },
        {
          'modulId': modul1Id,
          'pertanyaan':
              'Pernyataan implikasi p → q hanya akan bernilai SALAH apabila...',
          'opsiJawaban': jsonEncode([
            'p Salah dan q Salah',
            'p Salah dan q Benar',
            'p Benar dan q Salah',
            'p Benar dan q Benar',
          ]),
          'kunciJawaban': 2,
        },
        {
          'modulId': modul1Id,
          'pertanyaan':
              'Berdasarkan Hukum De Morgan, ekspresi logika !(isOnline && hasPermission) ekuivalen dengan ekspresi...',
          'opsiJawaban': jsonEncode([
            '!isOnline && !hasPermission',
            '!isOnline || !hasPermission',
            'isOnline || hasPermission',
            '!isOnline == hasPermission',
          ]),
          'kunciJawaban': 1,
        },
        {
          'modulId': modul1Id,
          'pertanyaan':
              'Diberikan p: "Server aktif" (True) dan q: "Koneksi database terputus" (False). Nilai kebenaran dari ~p ∨ ~q adalah...',
          'opsiJawaban': jsonEncode([
            'Benar (True)',
            'Salah (False)',
            'Null',
            'Tidak dapat ditentukan',
          ]),
          'kunciJawaban': 0,
        },
      ];

      for (var soal in soalModul1) {
        await txn.insert('soal_kuis', soal);
      }

      // -----------------------------------------------------------------------
      // MODUL 2: Persamaan dan Pertidaksamaan Linier (isLocked: true)
      // -----------------------------------------------------------------------
      final kontenModul2 = jsonEncode([
        {
          'judul': '1. Persamaan Linier Satu dan Dua Variabel',
          'isi':
              'Persamaan linier adalah persamaan aljabar dengan variabel berpangkat satu. Bentuk umum persamaan linier dua variabel (SPLDV) adalah:\nax + by = c\n\nDalam konteks PPLG, sistem persamaan sering digunakan untuk menghitung konsumsi sumber daya (misal: penggunaan CPU dan RAM dari dua thread berbeda).',
        },
        {
          'judul': '2. Metode Penyelesaian SPLDV',
          'isi':
              'Ada 3 metode utama penyelesaian SPLDV:\n1. Metode Substitusi: Mengganti salah satu variabel ke persamaan lain.\n2. Metode Eliminasi: Menghilangkan satu variabel dengan menyamakan koefisiennya.\n3. Metode Campuran: Menggabungkan eliminasi untuk variabel pertama dan substitusi untuk variabel kedua.',
        },
        {
          'judul': '3. Pertidaksamaan Linier & Boundary Conditions',
          'isi':
              'Pertidaksamaan linier menggunakan tanda <, <=, >, atau >=.\n\nDalam pemrograman, konsep pertidaksamaan linier mendasari boundary condition, seperti pembatasan ukuran resolusi layar, penentuan batas frame per second (FPS), serta deteksi collision kotak pembatas (Bounding Box / AABB).',
        },
        {
          'judul': '4. Penerapan dalam Optimasi Alokasi Resource',
          'isi':
              'Model matematika berbasis pertidaksamaan linier memungkinkan pengembang menentukan alokasi beban server cloud secara optimal demi meminimalkan biaya operasional dengan tetap memenuhi batas minimal performa.',
        },
      ]);

      final modul2Id = await txn.insert('modul', {
        'judul': 'Persamaan dan Pertidaksamaan Linier',
        'deskripsi':
            'Sistem persamaan linier (SPLDV), metode eliminasi-substitusi, dan pertidaksamaan untuk alokasi resource komputasi dan boundary condition.',
        'isLocked': 1, // true
        'kontenJson': kontenModul2,
        'urutan': 2,
      });

      // Soal Modul 2 (5 soal)
      final soalModul2 = [
        {
          'modulId': modul2Id,
          'pertanyaan':
              'Tentukan nilai x yang memenuhi persamaan linier: 4x - 7 = 2x + 9!',
          'opsiJawaban': jsonEncode([
            'x = 6',
            'x = 7',
            'x = 8',
            'x = 9',
          ]),
          'kunciJawaban': 2, // 2x = 16 => x = 8
        },
        {
          'modulId': modul2Id,
          'pertanyaan':
              'Diberikan SPLDV: x + y = 10 dan x - y = 4. Nilai dari perkalian (x × y) adalah...',
          'opsiJawaban': jsonEncode([
            '18',
            '21',
            '24',
            '28',
          ]),
          'kunciJawaban': 1, // x=7, y=3 => 7*3 = 21
        },
        {
          'modulId': modul2Id,
          'pertanyaan':
              'Himpunan penyelesaian dari pertidaksamaan 3x - 5 ≤ 7 + x untuk x bilangan bulat adalah...',
          'opsiJawaban': jsonEncode([
            'x ≤ 4',
            'x ≤ 6',
            'x ≥ 6',
            'x ≤ 12',
          ]),
          'kunciJawaban': 1, // 2x <= 12 => x <= 6
        },
        {
          'modulId': modul2Id,
          'pertanyaan':
              'Sebuah studio gim membeli 3 aset 3D dan 2 audio seharga Rp120.000. Jika harga 1 aset 3D sama dengan harga 2 audio, berapakah harga 1 aset 3D?',
          'opsiJawaban': jsonEncode([
            'Rp20.000',
            'Rp25.000',
            'Rp30.000',
            'Rp40.000',
          ]),
          'kunciJawaban': 2, // 3(2y) + 2y = 8y = 120rb => y=15rb => x = 30rb
        },
        {
          'modulId': modul2Id,
          'pertanyaan':
              'Jika batas frame time gim dibatasi oleh pertidaksamaan: 16.6 ms ≤ t ≤ 33.3 ms, maka kisaran frame rate (FPS = 1000/t) yang dihasilkan adalah...',
          'opsiJawaban': jsonEncode([
            '15 FPS hingga 30 FPS',
            '30 FPS hingga 60 FPS',
            '60 FPS hingga 120 FPS',
            '24 FPS hingga 48 FPS',
          ]),
          'kunciJawaban': 1, // 1000/33.3 ~ 30 fps, 1000/16.6 ~ 60 fps
        },
      ];

      for (var soal in soalModul2) {
        await txn.insert('soal_kuis', soal);
      }

      // -----------------------------------------------------------------------
      // MODUL 3: Matriks (isLocked: true)
      // -----------------------------------------------------------------------
      final kontenModul3 = jsonEncode([
        {
          'judul': '1. Konsep Matriks dan Array 2D',
          'isi':
              'Matriks adalah susunan bilangan dalam bentuk baris dan kolom yang memiliki ukuran (ordo) m × n. Dalam pemrograman, representasi matriks identik dengan array dua dimensi (List<List<int>>).\n\nMatriks adalah tulang punggung grafika komputer, rendering game engine 2D/3D, dan machine learning.',
        },
        {
          'judul': '2. Operasi Penjumlahan dan Perkalian Skalar',
          'isi':
              'Dua matriks dapat dijumlahkan atau dikurangkan HANYA JIKA ordonya sama. Penjumlahan dilakukan dengan menjumlahkan elemen-elemen yang seletak.\n\nPerkalian skalar k × A dilakukan dengan mengalikan setiap elemen matriks A dengan bilangan k. Contoh: memperbesar kecerahan seluruh pixel pada gambar digital.',
        },
        {
          'judul': '3. Perkalian Matriks dengan Matriks',
          'isi':
              'Matriks A (ordo m × n) dapat dikalikan dengan matriks B (ordo p × q) JIKA DAN HANYA JIKA n = p (jumlah kolom A sama dengan jumlah baris B).\n\nHasil kalinya berordo m × q, di mana elemen baris ke-i dan kolom ke-j adalah jumlah dari perkalian elemen baris ke-i matriks A dengan kolom ke-j matriks B.',
        },
        {
          'judul': '4. Determinan, Invers, dan Transformasi Grafika',
          'isi':
              'Untuk matriks 2×2 A = [[a, b], [c, d]]:\nDeterminan det(A) = ad - bc.\nInvers A⁻¹ = (1 / det(A)) × [[d, -b], [-c, a]], dengan syarat det(A) ≠ 0.\n\nDalam game development, perkalian matriks digunakan untuk transformasi koordinat objek (translasi posisi, rotasi sudut, dan scaling ukuran).',
        },
      ]);

      final modul3Id = await txn.insert('modul', {
        'judul': 'Matriks',
        'deskripsi':
            'Ordo matriks, array multidimensi, operasi aljabar matriks, determinan, invers, dan penerapannya pada transformasi grafika gim.',
        'isLocked': 1, // true
        'kontenJson': kontenModul3,
        'urutan': 3,
      });

      // Soal Modul 3 (5 soal)
      final soalModul3 = [
        {
          'modulId': modul3Id,
          'pertanyaan':
              'Jika matriks A = [[2, 3], [1, 4]] dan B = [[3, 1], [4, 2]], maka hasil penjumlahan A + B adalah...',
          'opsiJawaban': jsonEncode([
            '[[5, 4], [5, 6]]',
            '[[6, 3], [4, 8]]',
            '[[5, 4], [6, 5]]',
            '[[1, 2], [3, 2]]',
          ]),
          'kunciJawaban': 0, // [2+3, 3+1], [1+4, 4+2] = [[5, 4], [5, 6]]
        },
        {
          'modulId': modul3Id,
          'pertanyaan':
              'Diberikan matriks P = [[1, 2], [3, 4]]. Berapakah nilai determinan dari matriks P?',
          'opsiJawaban': jsonEncode([
            '-2',
            '2',
            '-5',
            '10',
          ]),
          'kunciJawaban': 0, // (1*4) - (2*3) = 4 - 6 = -2
        },
        {
          'modulId': modul3Id,
          'pertanyaan':
              'Syarat agar dua buah matriks A dan B dapat dikalikan (A × B) adalah...',
          'opsiJawaban': jsonEncode([
            'Keduanya harus berordo bujur sangkar sama',
            'Jumlah baris A harus sama dengan jumlah kolom B',
            'Jumlah kolom A harus sama dengan jumlah baris B',
            'Kedua matriks harus memiliki determinan bukan nol',
          ]),
          'kunciJawaban': 2,
        },
        {
          'modulId': modul3Id,
          'pertanyaan':
              'Hasil perkalian skalar 3 × [[4, -1], [2, 0]] adalah...',
          'opsiJawaban': jsonEncode([
            '[[12, -3], [6, 0]]',
            '[[7, 2], [5, 3]]',
            '[[12, -1], [2, 0]]',
            '[[12, -3], [6, 3]]',
          ]),
          'kunciJawaban': 0,
        },
        {
          'modulId': modul3Id,
          'pertanyaan':
              'Dalam grafika gim 2D, matriks transformasi [[s, 0], [0, s]] digunakan untuk operasi...',
          'opsiJawaban': jsonEncode([
            'Translasi (Pergeseran posisi)',
            'Rotasi (Pemutaran sudut)',
            'Scaling (Penskalaan ukuran seragam)',
            'Shearing (Kemiringan bentuk)',
          ]),
          'kunciJawaban': 2,
        },
      ];

      for (var soal in soalModul3) {
        await txn.insert('soal_kuis', soal);
      }

      // -----------------------------------------------------------------------
      // MODUL 4: Fungsi dan Turunan (isLocked: true)
      // -----------------------------------------------------------------------
      final kontenModul4 = jsonEncode([
        {
          'judul': '1. Konsep Pemetaan Fungsi dalam Pemrograman',
          'isi':
              'Secara matematis, fungsi f: X → Y memetakan setiap elemen x ke tepat satu elemen y = f(x). Dalam paradigma functional programming dan method/function OOP:\nint f(int x) => x * x + 2;\n\nFungsi kuadrat f(x) = ax² + bx + c sering dipakai untuk memodelkan lintasan proyektil parabola (jump trajectory) pada karakter gim.',
        },
        {
          'judul': '2. Konsep Laju Perubahan dan Definisi Turunan',
          'isi':
              'Turunan (diferensial) mengukur sensitivitas perubahan nilai fungsi terhadap perubahan nilai variabel inputnya.\n\nAturan dasar turunan aljabar:\nJika f(x) = a · xⁿ, maka turunan pertamanya adalah:\nf\'(x) = a · n · xⁿ⁻¹\n\nJika f(x) = c (konstanta), maka f\'(x) = 0.',
        },
        {
          'judul': '3. Fisika Gim: Posisi, Kecepatan, dan Percepatan',
          'isi':
              'Hubungan kalkulus diferensial dalam simulasi fisika gim:\n1. Posisi fungsi waktu: s(t)\n2. Kecepatan (velocity) adalah turunan pertama posisi: v(t) = s\'(t) = ds/dt\n3. Percepatan (acceleration) adalah turunan kedua posisi: a(t) = v\'(t) = s\'\'(t)',
        },
        {
          'judul': '4. Optimasi Algoritma: Nilai Ekstrim (Maksimum/Minimum)',
          'isi':
              'Titik stasioner suatu kurva tercapai ketika f\'(x) = 0. Konsep ini digunakan untuk mencari nilai maksimum atau minimum (optimasi), seperti meminimalkan konsumsi bandwidth pengiriman paket data jaringan atau mencari sudut tembak optimal proyektil.',
        },
      ]);

      final modul4Id = await txn.insert('modul', {
        'judul': 'Fungsi dan Turunan',
        'deskripsi':
            'Fungsi kuadrat, aturan turunan aljabar, kalkulasi kecepatan dan percepatan pada game physics, serta nilai ekstrim untuk optimasi.',
        'isLocked': 1, // true
        'kontenJson': kontenModul4,
        'urutan': 4,
      });

      // Soal Modul 4 (5 soal)
      final soalModul4 = [
        {
          'modulId': modul4Id,
          'pertanyaan':
              'Diberikan fungsi f(x) = 2x² - 3x + 5. Berapakah nilai f(3)?',
          'opsiJawaban': jsonEncode([
            '12',
            '14',
            '16',
            '20',
          ]),
          'kunciJawaban': 1, // 2(9) - 9 + 5 = 18 - 9 + 5 = 14
        },
        {
          'modulId': modul4Id,
          'pertanyaan':
              'Turunan pertama dari f(x) = 3x⁴ - 5x² + 7x - 9 adalah f\'(x) = ...',
          'opsiJawaban': jsonEncode([
            '12x³ - 10x + 7',
            '12x⁴ - 10x² + 7',
            '7x³ - 10x + 7',
            '12x³ - 5x + 7',
          ]),
          'kunciJawaban': 0, // 3*4 x^3 - 5*2 x + 7 = 12x^3 - 10x + 7
        },
        {
          'modulId': modul4Id,
          'pertanyaan':
              'Jika posisi karakter gim bergerak menurut s(t) = 3t² + 2t (meter), kecepatan karakter pada detik ke-4 (v(4) = s\'(4)) adalah...',
          'opsiJawaban': jsonEncode([
            '24 m/s',
            '26 m/s',
            '28 m/s',
            '56 m/s',
          ]),
          'kunciJawaban': 1, // s'(t) = 6t + 2 => s'(4) = 24 + 2 = 26
        },
        {
          'modulId': modul4Id,
          'pertanyaan':
              'Titik stasioner dari kurva fungsi f(x) = x² - 6x + 8 dicapai saat nilai x sama dengan...',
          'opsiJawaban': jsonEncode([
            'x = 2',
            'x = 3',
            'x = 4',
            'x = 6',
          ]),
          'kunciJawaban': 1, // f'(x) = 2x - 6 = 0 => x = 3
        },
        {
          'modulId': modul4Id,
          'pertanyaan':
              'Turunan pertama dari f(x) = 5x³ adalah 15x². Aturan turunan apa yang digunakan dalam proses tersebut?',
          'opsiJawaban': jsonEncode([
            'Aturan rantai (chain rule)',
            'Aturan hasil kali (product rule)',
            'Aturan pangkat aljabar (power rule)',
            'Aturan pembagian (quotient rule)',
          ]),
          'kunciJawaban': 2,
        },
      ];

      for (var soal in soalModul4) {
        await txn.insert('soal_kuis', soal);
      }

      // =======================================================================
      // 2. SEED REWARD AWAL (4 Reward)
      // =======================================================================
      final rewards = [
        {
          'namaBadge': 'Langkah Pertama',
          'deskripsi': 'Menyelesaikan kuis pertama kamu di MathSpark!',
          'kondisi': 'Selesaikan minimal 1 kuis pada modul apapun',
          'sudahDapat': 0, // false
        },
        {
          'namaBadge': 'Ahli Logika',
          'deskripsi':
              'Mendapatkan skor membanggakan pada materi Logika Matematika.',
          'kondisi': 'Raih skor minimal 80 pada kuis Modul 1 (Logika Matematika)',
          'sudahDapat': 0, // false
        },
        {
          'namaBadge': 'Penjelajah Aljabar',
          'deskripsi':
              'Menuntaskan tantangan persamaan linier dan matriks dengan baik.',
          'kondisi': 'Selesaikan kuis Modul 2 dan Modul 3',
          'sudahDapat': 0, // false
        },
        {
          'namaBadge': 'Master MathSpark',
          'deskripsi':
              'Menguasai seluruh modul pembelajaran matematika SMK PPLG.',
          'kondisi':
              'Buka dan selesaikan semua modul dengan skor masing-masing ≥ 80',
          'sudahDapat': 0, // false
        },
      ];

      for (var reward in rewards) {
        await txn.insert('reward', reward);
      }
    });
  }
}
