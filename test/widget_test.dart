import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mathspark/main.dart';
import 'package:mathspark/models/modul.dart';
import 'package:mathspark/models/reward.dart';
import 'package:mathspark/screens/chatbot_screen.dart';
import 'package:mathspark/screens/hasil_kuis_screen.dart';
import 'package:mathspark/screens/home_screen.dart';
import 'package:mathspark/screens/kuis_screen.dart';
import 'package:mathspark/screens/main_navigation_screen.dart';
import 'package:mathspark/screens/modul_detail_screen.dart';
import 'package:mathspark/screens/onboarding_screen.dart';
import 'package:mathspark/screens/profil_screen.dart';
import 'package:mathspark/services/gemini_service.dart';
import 'package:mathspark/services/gamification_service.dart';

void main() {
  testWidgets('Menampilkan OnboardingScreen ketika belum ada profil', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MathSparkApp(
        initialScreen: OnboardingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi ikon/logo
    expect(find.byIcon(Icons.auto_awesome), findsWidgets);

    // Verifikasi judul dan subjudul
    expect(find.text('Selamat Datang di MathSpark!'), findsOneWidget);
    expect(
      find.text('Sebelum mulai belajar matematika, siapa nama panggilanmu?'),
      findsOneWidget,
    );

    // Verifikasi input textfield dan tombol
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Mulai Belajar'), findsOneWidget);
  });

  testWidgets('Menampilkan peringatan jika nama kosong saat tombol Mulai Belajar ditekan', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tekan tombol Mulai Belajar tanpa input nama
    await tester.tap(find.text('Mulai Belajar'));
    await tester.pump();

    // Verifikasi muncul SnackBar peringatan
    expect(
      find.text('Silakan masukkan nama panggilanmu terlebih dahulu!'),
      findsOneWidget,
    );
  });

  testWidgets('Menampilkan MainNavigationScreen dengan 3 tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MathSparkApp(
        initialScreen: MainNavigationScreen(),
      ),
    );
    await tester.pump();

    // Verifikasi BottomNavigationBar memiliki 3 item
    final navBarFinder = find.byType(BottomNavigationBar);
    expect(navBarFinder, findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Chatbot'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    // Default tab pertama aktif: Home
    expect(
      find.descendant(of: navBarFinder, matching: find.byIcon(Icons.home_rounded)),
      findsOneWidget,
    );

    // Berpindah ke tab Chatbot
    await tester.tap(find.text('Chatbot'));
    await tester.pump();
    expect(
      find.descendant(of: navBarFinder, matching: find.byIcon(Icons.smart_toy_rounded)),
      findsOneWidget,
    );

    // Berpindah ke tab Profil
    await tester.tap(find.text('Profil'));
    await tester.pump();
    expect(
      find.descendant(of: navBarFinder, matching: find.byIcon(Icons.person_rounded)),
      findsOneWidget,
    );
  });

  testWidgets('HomeScreen memuat komponen dashboard (Header, Grid Modul, Badges)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    await tester.pump();

    // Verifikasi judul appbar
    expect(find.text('MathSpark'), findsOneWidget);

    // Verifikasi teks header dan section
    expect(find.textContaining('Halo'), findsOneWidget);
    expect(find.text('Modul Tersedia'), findsOneWidget);
    expect(find.text('Badges & Pencapaian Saya'), findsOneWidget);

    // Verifikasi komponen LinearProgressIndicator ada di header
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('ModulDetailScreen menampilkan judul di AppBar, progres scroll, materi, dan tombol Mulai Kuis', (WidgetTester tester) async {
    final modul = Modul(
      id: 2,
      judul: 'Matriks & Transformasi',
      deskripsi: 'Operasi matriks dan representasi grafika komputer',
      isLocked: false,
      kontenJson: '[{"judul":"Sub-Bab 1 Konsep Matriks","isi":"Matriks ordo 2x2 dan determinan"}]',
      urutan: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ModulDetailScreen(modul: modul),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verifikasi judul modul di AppBar
    expect(find.widgetWithText(AppBar, 'Matriks & Transformasi'), findsOneWidget);

    // 2. Verifikasi indikator progres scroll membaca
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // 3. Verifikasi label prasyarat untuk urutan > 1
    expect(find.textContaining('Prasyarat:'), findsOneWidget);

    // 4. Verifikasi sub-bab materi diuraikan
    expect(find.text('Sub-Bab 1 Konsep Matriks'), findsOneWidget);
    expect(find.text('Matriks ordo 2x2 dan determinan'), findsOneWidget);

    // 5. Scroll hingga tombol penuh "Mulai Kuis" terlihat
    final mulaiKuisFinder = find.text('Mulai Kuis');
    await tester.ensureVisible(mulaiKuisFinder);
    await tester.pumpAndSettle();
    expect(mulaiKuisFinder, findsOneWidget);

    // 6. Klik tombol "Mulai Kuis" dan verifikasi navigasi ke KuisScreen
    await tester.tap(mulaiKuisFinder);
    await tester.pumpAndSettle();
    expect(find.byType(KuisScreen), findsOneWidget);
    expect(find.text('Kuis: Matriks & Transformasi'), findsOneWidget);
  });

  testWidgets('HasilKuisScreen menampilkan skor kelulusan, XP, modul baru, badge, dan kotak AI', (WidgetTester tester) async {
    final modul = Modul(
      id: 1,
      judul: 'Logika Matematika',
      deskripsi: 'Fondasi logika boolean',
      isLocked: false,
      kontenJson: '[]',
      urutan: 1,
    );

    final gamificationResult = GamificationResult(
      skor: 80,
      isLulus: true,
      xpEarned: 80,
      unlockedModul: Modul(
        id: 2,
        judul: 'Matriks & Transformasi',
        deskripsi: 'Modul lanjutan',
        isLocked: false,
        kontenJson: '[]',
        urutan: 2,
      ),
      newlyUnlockedRewards: [
        Reward(
          id: 1,
          namaBadge: 'Langkah Pertama',
          deskripsi: 'Menyelesaikan kuis pertama',
          kondisi: '1 kuis selesai',
          sudahDapat: true,
        ),
      ],
    );

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: HasilKuisScreen(
          modul: modul,
          skor: 80,
          totalBenar: 4,
          totalSoal: 5,
          feedbackAI: 'Kerja bagus! Pemahaman konsep logika proposisi sudah sangat baik.',
          gamificationResult: gamificationResult,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi Skor dan Status Lulus
    expect(find.text('80'), findsOneWidget);
    expect(find.text('Selamat! Kamu Lulus 🎉'), findsOneWidget);
    expect(find.text('+80 XP Didapatkan'), findsOneWidget);

    // Verifikasi Banner Modul Terbuka & Badge
    expect(find.text('Modul Baru Terbuka!'), findsOneWidget);
    expect(find.text('Matriks & Transformasi'), findsOneWidget);
    expect(find.text('Badge Baru Terbuka!'), findsOneWidget);
    expect(find.textContaining('Langkah Pertama'), findsOneWidget);

    // Verifikasi Kotak Evaluasi AI
    expect(find.text('Evaluasi Tutor AI MathSpark'), findsOneWidget);
    expect(find.textContaining('Kerja bagus! Pemahaman konsep logika proposisi'), findsOneWidget);

    // Verifikasi Tombol Navigasi
    expect(find.text('Ulangi Kuis'), findsOneWidget);
    expect(find.text('Ke Beranda'), findsOneWidget);
  });

  testWidgets('ChatbotScreen menampilkan header, pesan pembuka, dan menolak kueri off-topic secara lokal', (WidgetTester tester) async {
    int apiCallCount = 0;
    final mockClient = MockClient((request) async {
      apiCallCount++;
      return http.Response(
        jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Halo! Mari kita telusuri konsep matematika ini.'}
                ]
              }
            }
          ]
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final geminiService = GeminiService(
      client: mockClient,
      apiKey: 'test-api-key',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChatbotScreen(
          geminiService: geminiService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verifikasi AppBar: Judul "MathSpark Bot" & ikon robot
    expect(find.text('MathSpark Bot'), findsWidgets);
    expect(find.byIcon(Icons.smart_toy_rounded), findsWidgets);

    // 2. Verifikasi gelembung pesan pembuka otomatis
    expect(find.textContaining('Aku siap bantu kamu!'), findsOneWidget);

    // 3. Verifikasi input bar ("Tulis sesuatu..." + tombol kirim)
    expect(find.text('Tulis sesuatu...'), findsOneWidget);
    final sendButtonFinder = find.byIcon(Icons.send_rounded);
    expect(sendButtonFinder, findsOneWidget);

    // 4. Uji kirim pesan out-of-topic (misal resep makanan / game)
    await tester.enterText(find.byType(TextField), 'Resep membuat nasi goreng lezat');
    await tester.tap(sendButtonFinder);
    await tester.pumpAndSettle();

    // Verifikasi bubble siswa tampil di kanan
    expect(find.text('Resep membuat nasi goreng lezat'), findsOneWidget);

    // Verifikasi balasan lokal langsung tampil tanpa memanggil API
    expect(
      find.text('Maaf, saya hanya dirancang untuk menjawab pertanyaan seputar materi Matematika PPLG.'),
      findsOneWidget,
    );
    expect(apiCallCount, 0); // Membuktikan API Gemini TIDAK dipanggil sama sekali!

    // 5. Uji kirim pesan in-topic (misal seputar logika matematika)
    await tester.enterText(
      find.byType(TextField),
      'Bagaimana cara menentukan nilai kebenaran konjungsi dan disjungsi logika matematika?',
    );
    await tester.tap(sendButtonFinder);
    await tester.pumpAndSettle();

    // Verifikasi bubble siswa tampil
    expect(
      find.text('Bagaimana cara menentukan nilai kebenaran konjungsi dan disjungsi logika matematika?'),
      findsOneWidget,
    );

    // Verifikasi API Gemini dipanggil dan jawaban AI ditampilkan
    expect(apiCallCount, 1);
    expect(find.text('Halo! Mari kita telusuri konsep matematika ini.'), findsOneWidget);
  });

  testWidgets('ProfilScreen memuat nama, tombol pensil edit nama, level XP, badges, dan riwayat skor', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfilScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verifikasi header profil dan tombol pensil edit
    expect(find.text('Profil & Riwayat'), findsOneWidget);
    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);

    // 2. Klik tombol pensil edit nama panggilan
    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();

    // Verifikasi dialog edit nama terbuka
    expect(find.text('Ubah Nama Panggilan'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);

    // Tutup dialog via tombol Batal
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    // 3. Verifikasi Level dan progress bar XP
    expect(find.textContaining('Level'), findsWidgets);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // 4. Verifikasi bagian Badges & Pencapaian Saya
    expect(find.text('Badges & Pencapaian Saya'), findsOneWidget);

    // 5. Verifikasi bagian Riwayat Skor Kuis
    expect(find.text('Riwayat Skor Kuis'), findsOneWidget);
  });
}
