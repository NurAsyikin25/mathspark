# Aturan Proyek MathSpark (Flutter + SQLite + Gemini API)

- **Aplikasi:** Media pembelajaran Matematika SMK Program Keahlian PPLG dengan Tutor AI Sokratik.
- **Platform & Tech:** Flutter (target Android), SQLite (`sqflite`) untuk penyimpanan offline, serta `http` + `flutter_dotenv` untuk Gemini API (`gemini-3.5-flash-lite` via `.env`).
- **State Management:** Gunakan `StatefulWidget` standar / `ChangeNotifier` sederhana (hindari BLoC, GetX, atau Riverpod agar kode tetap ringkas dan mudah dipelihara).
- **Alur Wajib Chatbot:**
  1. Pertanyaan siswa wajib melewati _text preprocessing_ + TF-IDF + Cosine Similarity secara lokal di Dart sebelum memanggil API.
  2. Jika skor Cosine Similarity `< 0.3` (threshold default), tolak secara lokal tanpa memanggil Gemini API.
  3. Jika skor `>= 0.3`, kirim ke Gemini API dengan `systemInstruction` Tutor Sokratik (wajib membimbing langkah demi langkah dan dilarang keras memberi jawaban akhir secara langsung).
- **Entitas SQLite (`mathspark.db`):** `Modul`, `SoalKuis`, `HasilKuis`, `ProfilSiswa`, `Reward`.
- **Halaman Utama (6 Screen):** Onboarding, Dashboard (Home), Detail Modul, Kuis & Evaluasi AI, Chatbot (MathSpark Bot), Profil & Riwayat Skor.
- **Struktur Folder Wajib:**
  - `lib/models/` -> Class data (`modul.dart`, `soal_kuis.dart`, `hasil_kuis.dart`, `profil_siswa.dart`, `reward.dart`) lengkap dengan `toMap()` dan `fromMap()`
  - `lib/database/` -> `database_helper.dart` & `seed_data.dart`
  - `lib/services/` -> `tfidf_filter_service.dart`, `gemini_service.dart`, `gamification_service.dart`
  - `lib/screens/` -> 6 halaman utama sesuai wireframe
  - `lib/widgets/` -> Komponen UI reusable
