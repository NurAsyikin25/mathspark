import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/hasil_kuis.dart';
import '../models/modul.dart';
import '../models/soal_kuis.dart';
import '../services/gemini_service.dart';
import '../services/gamification_service.dart';
import 'hasil_kuis_screen.dart';

class KuisScreen extends StatefulWidget {
  final Modul modul;
  final GeminiService? geminiService;
  final GamificationService? gamificationService;

  const KuisScreen({
    super.key,
    required this.modul,
    this.geminiService,
    this.gamificationService,
  });

  @override
  State<KuisScreen> createState() => _KuisScreenState();
}

class _KuisScreenState extends State<KuisScreen> {
  List<SoalKuis> _soalList = [];
  final Map<int, int> _selectedAnswers = {}; // Map: soalIndex -> opsiIndex (0-3)
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;

  late final GeminiService _geminiService;
  late final GamificationService _gamificationService;

  @override
  void initState() {
    super.initState();
    _geminiService = widget.geminiService ?? GeminiService();
    _gamificationService = widget.gamificationService ?? GamificationService();
    _loadSoal();
  }

  Future<void> _loadSoal() async {
    try {
      final modulId = widget.modul.id ?? 1;
      final soal = await DatabaseHelper.instance.getSoalByModul(modulId);
      if (mounted) {
        setState(() {
          _soalList = soal;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onOptionSelected(int optionIndex) {
    setState(() {
      _selectedAnswers[_currentIndex] = optionIndex;
    });
  }

  Future<void> _selesaiKuis() async {
    if (_soalList.isEmpty) return;

    // Cek apakah ada soal yang belum dijawab
    final int belumDijawab = _soalList.length - _selectedAnswers.length;
    if (belumDijawab > 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Masih Ada Soal Kosong'),
          content: Text(
            'Ada $belumDijawab soal yang belum kamu jawab. Yakin ingin menyelesaikan kuis sekarang?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Lanjutkan Mengerjakan'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ya, Selesai'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. Hitung skor kuis lokal
      int totalBenar = 0;
      final List<Map<String, dynamic>> detailJawabanSalah = [];

      for (int i = 0; i < _soalList.length; i++) {
        final soal = _soalList[i];
        final dipilih = _selectedAnswers[i];

        if (dipilih != null && dipilih == soal.kunciJawaban) {
          totalBenar++;
        } else {
          final opsi = soal.opsiJawaban;
          final String jawabanSiswaText = (dipilih != null && dipilih < opsi.length)
              ? opsi[dipilih]
              : 'Tidak dijawab';
          final String kunciJawabanText = (soal.kunciJawaban < opsi.length)
              ? opsi[soal.kunciJawaban]
              : '-';

          detailJawabanSalah.add({
            'pertanyaan': soal.pertanyaan,
            'opsiJawaban': soal.opsiJawaban,
            'jawabanSiswa': jawabanSiswaText,
            'kunciJawaban': kunciJawabanText,
          });
        }
      }

      final int skor = _gamificationService.hitungSkor(
        totalBenar: totalBenar,
        totalSoal: _soalList.length,
      );

      // 2. Panggil evaluasi AI Gemini (dengan fallback offline)
      String feedbackAI;
      try {
        feedbackAI = await _geminiService.evaluateQuizResult(
          widget.modul.judul,
          detailJawabanSalah,
        );
      } catch (e) {
        feedbackAI = _generateOfflineFeedback(
          skor: skor,
          totalBenar: totalBenar,
          totalSoal: _soalList.length,
          detailJawabanSalah: detailJawabanSalah,
        );
      }

      // 3. Simpan ke SQLite HasilKuis
      // (DatabaseHelper secara otomatis hanya menimpa skor jika lebih tinggi dari rekor sebelumnya)
      final modulId = widget.modul.id ?? 1;
      final hasilKuis = HasilKuis(
        modulId: modulId,
        skorTerakhir: skor,
        jawabanSiswa: _selectedAnswers,
        feedbackAI: feedbackAI,
        dikerjakanAt: DateTime.now(),
      );

      await DatabaseHelper.instance.simpanAtauUpdateHasilKuis(hasilKuis);

      // 4. Jalankan GamificationService (buka kunci modul berikutnya jika lulus, tambah XP, cek badge)
      final gamificationResult = await _gamificationService.processQuizCompletion(
        modulId: modulId,
        skor: skor,
        urutanModul: widget.modul.urutan,
      );

      if (!mounted) return;

      // 5. Navigasikan ke HasilKuisScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HasilKuisScreen(
            modul: widget.modul,
            skor: skor,
            totalBenar: totalBenar,
            totalSoal: _soalList.length,
            feedbackAI: feedbackAI,
            gamificationResult: gamificationResult,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat memproses kuis: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _generateOfflineFeedback({
    required int skor,
    required int totalBenar,
    required int totalSoal,
    required List<Map<String, dynamic>> detailJawabanSalah,
  }) {
    if (skor == 100) {
      return 'Luar biasa! Kamu berhasil menjawab semua ($totalSoal) soal dengan sempurna tanpa kesalahan (Skor: 100%). Pemahaman logikamu terhadap materi ${widget.modul.judul} sangat luar biasa!';
    }

    final buffer = StringBuffer();
    buffer.writeln(
      'Analisis Hasil Kuis (Mode Offline):\n'
      'Kamu berhasil menjawab $totalBenar dari $totalSoal soal dengan benar (Skor: $skor).\n',
    );

    if (skor >= 70) {
      buffer.writeln('Hebat! Kamu telah memenuhi batas nilai kelulusan modul ini (≥ 70).\n');
    } else {
      buffer.writeln('Jangan berkecil hati! Pelajari kembali materi modul dan coba ulangi kuis untuk menembus batas kelulusan (≥ 70).\n');
    }

    if (detailJawabanSalah.isNotEmpty) {
      buffer.writeln('Catatan Soal yang Perlu Dipelajari Ulang:');
      for (int i = 0; i < detailJawabanSalah.length; i++) {
        final item = detailJawabanSalah[i];
        buffer.writeln('${i + 1}. ${item['pertanyaan']}');
        buffer.writeln('   - Kunci Jawaban: ${item['kunciJawaban']}');
      }
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Kuis: ${widget.modul.judul}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_soalList.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Kuis: ${widget.modul.judul}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada soal kuis yang tersedia untuk modul ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kembali ke Materi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final totalSoal = _soalList.length;
    final currentSoal = _soalList[_currentIndex];
    final progress = (_currentIndex + 1) / totalSoal;
    final selectedOption = _selectedAnswers[_currentIndex];
    final bool isLastQuestion = _currentIndex == totalSoal - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kuis: ${widget.modul.judul}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
            children: [
              // ========================================================
              // 1. PROGRESS BAR NOMOR SOAL
              // ========================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Soal ${_currentIndex + 1} dari $totalSoal',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Dijawab: ${_selectedAnswers.length}/$totalSoal',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ========================================================
              // 2. KARTU PERTANYAAN
              // ========================================================
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                  ),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Pertanyaan ${_currentIndex + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentSoal.pertanyaan,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ========================================================
              // 3. 4 PILIHAN JAWABAN (RADIO BUTTON)
              // ========================================================
              Text(
                'Pilih Jawaban:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),

              ...List.generate(currentSoal.opsiJawaban.length, (index) {
                final opsiText = currentSoal.opsiJawaban[index];
                final isSelected = selectedOption == index;
                final opsiLabel = String.fromCharCode(65 + index); // A, B, C, D

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () => _onOptionSelected(index),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer.withOpacity(0.45)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey.shade300,
                          width: isSelected ? 1.8 : 1.2,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: index,
                            groupValue: selectedOption,
                            onChanged: (val) {
                              if (val != null) _onOptionSelected(val);
                            },
                            activeColor: theme.colorScheme.primary,
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                opsiLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              opsiText,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),

              // ========================================================
              // 4. TOMBOL "SOAL BERIKUTNYA" / "SELESAI KUIS"
              // ========================================================
              Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentIndex--;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Sebelumnya'),
                      ),
                    ),
                  if (_currentIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isLastQuestion
                          ? _selesaiKuis
                          : () {
                              setState(() {
                                _currentIndex++;
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLastQuestion
                            ? Colors.green.shade700
                            : theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        isLastQuestion ? 'Selesai Kuis' : 'Soal Berikutnya',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),

          // Loading Overlay saat menganalisis kuis dengan AI
          if (_isSubmitting)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 28.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text(
                          'Menganalisis Hasil Kuis...',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tutor AI MathSpark sedang menyiapkan evaluasi belajarmu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
