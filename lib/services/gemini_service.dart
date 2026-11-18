import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service untuk berinteraksi dengan Google Gemini REST API.
///
/// Menyediakan fitur:
/// 1. [sendSocraticChat]: Chatbot Tutor Sokratik Matematika SMK PPLG.
/// 2. [evaluateQuizResult]: Evaluasi diagnostik hasil kuis siswa.
class GeminiService {
  final http.Client _client;
  final bool _isClientInternal;
  final String model;
  final String? _apiKey;
  final String baseUrl;
  final Duration timeoutDuration;

  /// Default model yang digunakan sesuai spesifikasi MathSpark.
  static const String defaultModel = 'gemini-3.5-flash-lite';

  /// Default URL endpoint Google Gemini REST API (v1beta).
  static const String defaultBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  /// System Instruction ketat untuk Tutor Sokratik Matematika SMK PPLG.
  static const String socraticSystemInstruction = '''
Kamu adalah MathSpark Bot, seorang Tutor AI Sokratik khusus Matematika untuk siswa SMK Program Keahlian Pengembangan Perangkat Lunak dan Gim (PPLG).

ATURAN UTAMA & METODE SOKRATIK (PEDOMAN MUTLAK):
1. PERAN UTAMA:
   - Kamu adalah mentor dan pembimbing yang ramah, sabar, dan suportif.
   - Kamu BUKAN mesin penjawab tugas, kalkulator otomatis, atau penyelesai soal instan.

2. WAJIB MEMBIMBING LANGKAH DEMI LANGKAH (SCAFFOLDING):
   - Wajib selalu menggunakan pertanyaan penuntun (guiding questions) untuk merangsang pemikiran kritis siswa.
   - Pecah masalah matematika yang kompleks menjadi tahapan kecil yang logis.
   - Ajukan HANYA SATU pertanyaan atau instruksi kecil yang terarah pada satu waktu agar siswa tidak merasa kewalahan dan dapat menemukan solusinya secara mandiri.

3. MEMUJI LANGKAH YANG BENAR & MENGAPRESIASI USAHA:
   - Selalu puji langkah yang benar, pemikiran logis, atau usaha yang ditunjukkan oleh siswa (misalnya: "Bagus sekali!", "Langkah awalmu sudah sangat tepat!", "Keren, analisismu sudah mengarah ke jalan yang benar!").
   - Jika siswa menjawab salah atau keliru langkah, jangan menyalahkan secara negatif. Berikan petunjuk lembut dan tanyakan kembali bagian mana yang perlu dicek ulang.

4. DILARANG KERAS MEMBERIKAN JAWABAN AKHIR SECARA LANGSUNG:
   - DILARANG KERAS memberikan jawaban akhir angka, simbol, atau rumus jadi siap pakai secara langsung kepada siswa.
   - JIKA SISWA MEMAKSA, MEMOHON, ATAU MERAJUK (misalnya: "cepat kasih tahu jawabannya dong", "apa jawabannya langsung?", "jangan berbelit-belit"):
     TETAP TOLAK DENGAN RAMAH DAN TEGAS. Berikan penjelasan bahwa tujuanmu adalah membuat mereka paham konsepnya, lalu kembalikan fokus ke langkah pemecahan masalah dengan pertanyaan pemantik berikutnya.

5. RELEVANSI DENGAN DUNIA PPLG (KODING & GIM):
   - Jika materi memungkinkan, hubungkan konsep matematika dengan dunia coding, logika algoritma, basis data, atau pengembangan game.
   - Contoh: Logika proposisi dengan percabangan `if-else` / boolean operator, Matriks dengan array multi-dimensi / grafika transformasi 2D/3D pada game engine, Relasi & Fungsi dengan method/fungsi dalam pemrograman.

6. GAYA BAHASA & FORMAT:
   - Gunakan Bahasa Indonesia yang ramah, santun, komunikatif, dan memotivasi khas mentor sebaya bagi siswa SMK.
   - Format jawaban rapi menggunakan Markdown (teks tebal untuk penekanan, bullet points, dan penulisan ekspresi matematika yang bersih dan mudah dibaca di layar ponsel).
''';

  /// System Instruction untuk Evaluasi Hasil Kuis.
  static const String quizEvaluationSystemInstruction = '''
Kamu adalah Evaluator dan Guru Ahli Matematika SMK Program Keahlian PPLG di aplikasi MathSpark.
Tugasmu adalah menganalisis hasil kuis siswa yang menjawab keliru pada beberapa soal, lalu memberikan evaluasi diagnostik yang konstruktif, edukatif, dan memotivasi.

PEDOMAN EVALUASI:
1. Analisis letak kekeliruan pemahaman siswa pada setiap soal yang dijawab salah tanpa membuat siswa berkecil hati.
2. Jelaskan konsep dasar matematika apa yang perlu dipelajari ulang oleh siswa untuk memperbaiki pemahamannya.
3. Jelaskan mengapa kunci jawaban yang benar adalah solusi yang tepat dengan bahasa yang ringkas dan mudah dipahami.
4. Kaitkan dengan penerapan logika koding atau pengembangan perangkat lunak jika relevan.
5. Berikan kata-kata motivasi dan tips belajar agar siswa percaya diri untuk mencoba kuis kembali.
6. Gunakan format Markdown yang rapi dan terstruktur (subjudul soal, poin-poin penjelasan, teks tebal).
''';

  /// Membuat instance [GeminiService].
  ///
  /// [client] dapat diinjeksi untuk kebutuhan unit testing / mock.
  /// [apiKey] dapat diisi secara manual, atau otomatis membaca `GEMINI_API_KEY` dari [dotenv].
  /// [model] default adalah `gemini-3.5-flash-lite`.
  GeminiService({
    http.Client? client,
    this.model = defaultModel,
    String? apiKey,
    this.baseUrl = defaultBaseUrl,
    this.timeoutDuration = const Duration(seconds: 30),
  })  : _client = client ?? http.Client(),
        _isClientInternal = client == null,
        _apiKey = apiKey;

  /// Mengambil API Key dari konfigurasi manual atau dari file .env via `flutter_dotenv`.
  String? get apiKey {
    final manualKey = _apiKey;
    if (manualKey != null && manualKey.trim().isNotEmpty) {
      return manualKey.trim();
    }
    try {
      if (dotenv.isInitialized) {
        final key = dotenv.env['GEMINI_API_KEY'];
        if (key != null && key.trim().isNotEmpty) {
          return key.trim();
        }
      }
    } catch (_) {
      // Menangani kasus jika dotenv belum diinisialisasi
    }
    return null;
  }

  /// Mengirim pesan ke Tutor Sokratik Matematika SMK PPLG dengan riwayat chat.
  ///
  /// - [chatHistory]: Daftar riwayat obrolan sebelumnya dalam bentuk list of map
  ///   (misal: `[{'role': 'user', 'content': '...'}, {'role': 'model', 'content': '...'}]`).
  /// - [userMessage]: Pesan pertanyaan baru dari siswa.
  ///
  /// Menggunakan [socraticSystemInstruction] ketat agar AI membimbing langkah demi langkah,
  /// memuji pemikiran siswa yang benar, dan DILARANG KERAS memberikan jawaban akhir langsung.
  Future<String> sendSocraticChat(
    List<Map<String, String>> chatHistory,
    String userMessage,
  ) async {
    final trimmedUserMessage = userMessage.trim();

    final List<Map<String, dynamic>> contents = [];

    // Format chat history ke format contents Gemini REST API
    for (final item in chatHistory) {
      final rawRole = (item['role'] ?? 'user').toLowerCase().trim();
      final role =
          (rawRole == 'assistant' || rawRole == 'model' || rawRole == 'bot')
              ? 'model'
              : 'user';
      final text =
          (item['text'] ?? item['content'] ?? item['message'] ?? '').trim();

      if (text.isEmpty) continue;

      // Gemini REST API mensyaratkan pesan pertama di `contents` harus memiliki role 'user'
      if (contents.isEmpty && role == 'model') {
        continue;
      }

      // Gabungkan bagian jika ada pesan beruntun dengan role yang sama
      if (contents.isNotEmpty && contents.last['role'] == role) {
        final parts = contents.last['parts'] as List<Map<String, dynamic>>;
        parts.add({'text': text});
      } else {
        contents.add({
          'role': role,
          'parts': [
            {'text': text}
          ],
        });
      }
    }

    // Masukkan userMessage terkini jika belum ada di akhir history
    if (trimmedUserMessage.isNotEmpty) {
      final isLastDuplicate = contents.isNotEmpty &&
          contents.last['role'] == 'user' &&
          (contents.last['parts'] as List<Map<String, dynamic>>)
              .any((p) => p['text'] == trimmedUserMessage);

      if (!isLastDuplicate) {
        if (contents.isNotEmpty && contents.last['role'] == 'user') {
          final parts = contents.last['parts'] as List<Map<String, dynamic>>;
          parts.add({'text': trimmedUserMessage});
        } else {
          contents.add({
            'role': 'user',
            'parts': [
              {'text': trimmedUserMessage}
            ],
          });
        }
      }
    }

    if (contents.isEmpty) {
      return 'Halo! Silakan ketik pertanyaan atau topik matematika yang ingin kamu diskusikan bersama MathSpark Bot.';
    }

    return _callGeminiApi(
      contents: contents,
      systemInstruction: socraticSystemInstruction,
    );
  }

  /// Mengevaluasi hasil kuis siswa dengan mengirimkan ringkasan soal yang dijawab salah
  /// beserta opsi yang dipilih siswa dan kunci jawaban.
  ///
  /// - [namaModul]: Judul materi/modul kuis yang baru saja dikerjakan siswa.
  /// - [detailJawabanSalah]: List berisi data soal yang keliru dijawab, berisi
  ///   pertanyaan, opsi jawaban, jawaban yang dipilih siswa, dan kunci jawaban.
  ///
  /// Menghasilkan penjelasan singkat mengenai mengapa jawaban tersebut kurang tepat,
  /// konsep dasar yang perlu dipelajari ulang, serta motivasi perbaikan.
  Future<String> evaluateQuizResult(
    String namaModul,
    List<Map<String, dynamic>> detailJawabanSalah,
  ) async {
    // Jika tidak ada jawaban salah (skor 100)
    if (detailJawabanSalah.isEmpty) {
      return 'Luar biasa! Kamu berhasil menjawab semua soal pada modul "$namaModul" dengan benar (skor sempurna 100%). '
          'Pemahaman konsep matematikamu sangat solid. Pertahankan prestasimu dan lanjutkan ke modul berikutnya!';
    }

    final promptText = _buildQuizEvaluationPrompt(namaModul, detailJawabanSalah);

    final contents = [
      {
        'role': 'user',
        'parts': [
          {'text': promptText}
        ],
      }
    ];

    return _callGeminiApi(
      contents: contents,
      systemInstruction: quizEvaluationSystemInstruction,
    );
  }

  /// Membangun prompt analisis hasil kuis dari daftar jawaban salah.
  String _buildQuizEvaluationPrompt(
    String namaModul,
    List<Map<String, dynamic>> detailJawabanSalah,
  ) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Siswa baru saja menyelesaikan kuis matematika untuk modul: "$namaModul".\n'
      'Berikut adalah rincian soal-soal yang dijawab salah oleh siswa beserta pilihan jawaban yang dipilih:\n',
    );

    for (int i = 0; i < detailJawabanSalah.length; i++) {
      final item = detailJawabanSalah[i];
      final no = i + 1;
      final pertanyaan = item['pertanyaan'] ?? item['soal'] ?? 'Soal nomor $no';
      final opsi = item['opsiJawaban'] ?? item['opsi_jawaban'] ?? item['opsi'];
      final rawJawabanSiswa = item['jawabanSiswa'] ??
          item['opsiDipilih'] ??
          item['jawaban_siswa'] ??
          item['jawabanTerpilih'] ??
          item['pilihanSiswa'];
      final rawKunciJawaban = item['kunciJawaban'] ??
          item['jawabanBenar'] ??
          item['kunci_jawaban'] ??
          item['opsiBenar'];

      final jawabanSiswaText = _formatAnswer(rawJawabanSiswa, opsi);
      final kunciJawabanText = _formatAnswer(rawKunciJawaban, opsi);

      buffer.writeln('### Soal $no:');
      buffer.writeln('- **Pertanyaan:** $pertanyaan');

      if (opsi is List && opsi.isNotEmpty) {
        buffer.writeln('- **Pilihan Jawaban:**');
        for (int j = 0; j < opsi.length; j++) {
          final label = String.fromCharCode(65 + j);
          buffer.writeln('  $label. ${opsi[j]}');
        }
      }

      buffer.writeln('- **Pilihan Siswa (Salah):** $jawabanSiswaText');
      if (kunciJawabanText != '-') {
        buffer.writeln('- **Kunci Jawaban Seharusnya:** $kunciJawabanText');
      }
      buffer.writeln('');
    }

    buffer.writeln('''
Instruksi untuk Tutor Evaluator:
1. Berikan apresiasi dan motivasi hangat kepada siswa SMK PPLG atas usahanya mengerjakan kuis ini.
2. Analisis setiap soal yang salah di atas: jelaskan letak kekeliruan logika/konsep dari jawaban siswa, dan mengapa kunci jawaban tersebut yang tepat.
3. Rangkum konsep dasar matematika apa yang perlu dipelajari atau diperdalam kembali oleh siswa.
4. Kaitkan konsep tersebut dengan logika pemrograman/coding/PPLG jika relevan agar lebih mudah dipahami dan diingat.
5. Berikan saran langkah belajar perbaikan yang jelas agar siswa siap mencoba kuis kembali.
6. Gunakan format Markdown yang terstruktur, rapi, dan nyaman dibaca di layar smartphone.
''');

    return buffer.toString();
  }

  /// Memformat teks jawaban baik jika berbentuk index integer maupun string opsi.
  String _formatAnswer(dynamic answer, dynamic options) {
    if (answer == null) return '-';
    if (answer is int &&
        options is List &&
        answer >= 0 &&
        answer < options.length) {
      final label = String.fromCharCode(65 + answer);
      return '$label. ${options[answer]}';
    }
    return answer.toString();
  }

  /// Eksekusi pemanggilan HTTP POST ke endpoint Gemini REST API dengan penanganan error.
  Future<String> _callGeminiApi({
    required List<Map<String, dynamic>> contents,
    String? systemInstruction,
  }) async {
    final key = apiKey;
    if (key == null || key.isEmpty) {
      return 'Kunci API (GEMINI_API_KEY) belum dikonfigurasi di file .env. Pastikan API key sudah dimasukkan agar fitur AI dapat digunakan.';
    }

    final url = '$baseUrl/models/$model:generateContent?key=$key';
    final uri = Uri.parse(url);

    final Map<String, dynamic> requestBody = {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 2048,
      },
    };

    if (systemInstruction != null && systemInstruction.trim().isNotEmpty) {
      requestBody['systemInstruction'] = {
        'parts': [
          {'text': systemInstruction}
        ]
      };
    }

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

        // Cek jika prompt terkena filter keamanan
        if (responseData.containsKey('promptFeedback')) {
          final feedback =
              responseData['promptFeedback'] as Map<String, dynamic>?;
          final blockReason = feedback?['blockReason'];
          if (blockReason != null) {
            return 'Pesan tidak dapat diproses karena terdeteksi oleh sistem keamanan AI ($blockReason). Silakan ajukan pertanyaan lain seputar materi matematika SMK.';
          }
        }

        // Ekstraksi jawaban dari candidates
        if (responseData.containsKey('candidates')) {
          final candidates = responseData['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final firstCandidate = candidates.first as Map<String, dynamic>?;
            final content = firstCandidate?['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts
                  .whereType<Map<String, dynamic>>()
                  .map((p) => p['text']?.toString() ?? '')
                  .where((t) => t.isNotEmpty)
                  .join('\n')
                  .trim();
              if (text.isNotEmpty) {
                return text;
              }
            }

            final finishReason = firstCandidate?['finishReason']?.toString();
            if (finishReason != null && finishReason != 'STOP') {
              return 'Respon tidak dapat ditampilkan secara lengkap karena alasan: $finishReason. Silakan ajukan pertanyaan kembali.';
            }
          }
        }

        return 'Maaf, tidak ada respon yang diterima dari AI. Silakan coba ajukan pertanyaan kembali.';
      } else if (response.statusCode == 400) {
        return 'Permintaan ke layanan AI tidak valid (Kode 400). Silakan periksa kembali pesan yang dikirim.';
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return 'Autentikasi API Key Gemini gagal. Pastikan GEMINI_API_KEY di file .env Anda valid dan masih aktif.';
      } else if (response.statusCode == 429) {
        return 'Batas permintaan (rate limit) AI tercapai atau kuota sementara habis. Tunggu sebentar sebelum mencoba kembali ya.';
      } else if (response.statusCode >= 500) {
        return 'Server layanan AI sedang mengalami kendala sementara (Kode ${response.statusCode}). Silakan coba beberapa saat lagi.';
      } else {
        return 'Terjadi kesalahan saat menghubungi layanan AI (Status: ${response.statusCode}). Silakan coba lagi.';
      }
    } on TimeoutException {
      return 'Waktu permintaan habis (timeout). Koneksi internet lambat atau server sedang sibuk, silakan coba kirim kembali.';
    } on SocketException {
      return 'Gagal terhubung ke internet. Periksa koneksi data atau Wi-Fi pada perangkatmu dan coba lagi ya!';
    } on http.ClientException {
      return 'Terjadi kendala koneksi ke server AI. Pastikan internet Anda aktif dan coba beberapa saat lagi.';
    } on FormatException {
      return 'Terjadi kesalahan saat memproses respon dari server AI. Silakan coba lagi.';
    } catch (e) {
      return 'Terjadi kendala tak terduga: ${e.toString()}. Silakan coba kembali nanti.';
    }
  }

  /// Menutup client HTTP jika dibuat secara internal.
  void dispose() {
    if (_isClientInternal) {
      _client.close();
    }
  }
}
