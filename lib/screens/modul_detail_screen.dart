import 'dart:convert';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/modul.dart';
import 'kuis_screen.dart';

class ModulDetailScreen extends StatefulWidget {
  final Modul modul;

  const ModulDetailScreen({
    super.key,
    required this.modul,
  });

  @override
  State<ModulDetailScreen> createState() => _ModulDetailScreenState();
}

class _ModulDetailScreenState extends State<ModulDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;
  String? _prasyaratJudul;
  List<Map<String, String>> _subBabList = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _parseKonten();
    _loadPrasyarat();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      if (maxScroll > 0) {
        final progress = (currentScroll / maxScroll).clamp(0.0, 1.0);
        if ((progress - _scrollProgress).abs() > 0.01 || progress == 1.0 || progress == 0.0) {
          setState(() {
            _scrollProgress = progress;
          });
        }
      }
    }
  }

  void _parseKonten() {
    try {
      final decoded = jsonDecode(widget.modul.kontenJson);
      if (decoded is List) {
        _subBabList = decoded.map<Map<String, String>>((item) {
          if (item is Map) {
            return {
              'judul': item['judul']?.toString() ?? 'Sub-Bab Materi',
              'isi': item['isi']?.toString() ?? '',
            };
          }
          return {
            'judul': 'Sub-Bab Materi',
            'isi': item.toString(),
          };
        }).toList();
      }
    } catch (_) {
      _subBabList = [
        {
          'judul': 'Materi Pembelajaran',
          'isi': widget.modul.deskripsi,
        }
      ];
    }
  }

  Future<void> _loadPrasyarat() async {
    if (widget.modul.urutan > 1) {
      try {
        final allModul = await DatabaseHelper.instance.getAllModul();
        final prevModul = allModul.firstWhere(
          (m) => m.urutan == widget.modul.urutan - 1,
          orElse: () => Modul(
            judul: 'Modul ${widget.modul.urutan - 1}',
            deskripsi: '',
            kontenJson: '',
            urutan: widget.modul.urutan - 1,
          ),
        );
        if (mounted) {
          setState(() {
            _prasyaratJudul = prevModul.judul;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _prasyaratJudul = 'Modul ${widget.modul.urutan - 1}';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urutan = widget.modul.urutan;
    final int progressPercent = (_scrollProgress * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.modul.judul,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: _scrollProgress,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
            minHeight: 4,
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Indikator Progres Baca Teks
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Modul $urutan',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Selesai dibaca: $progressPercent%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Card Header Deskripsi Modul
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.modul.judul,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.modul.deskripsi,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Label Prasyarat (jika urutan > 1)
            if (urutan > 1)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.shade300,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_clock_rounded,
                      color: Colors.amber.shade900,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Prasyarat: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: _prasyaratJudul ?? 'Modul ${urutan - 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Daftar Sub-Bab Materi
            if (_subBabList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text('Materi belum tersedia.'),
                ),
              )
            else
              ..._subBabList.asMap().entries.map((entry) {
                final index = entry.key;
                final subBab = entry.value;
                final judul = subBab['judul'] ?? 'Sub-Bab ${index + 1}';
                final isi = subBab['isi'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul Sub-Bab
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              judul,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),

                      // Isi Sub-Bab Materi
                      Text(
                        isi,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          height: 1.6,
                          letterSpacing: 0.2,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 16),

            // Tombol Penuh "Mulai Kuis" di Bagian Bawah
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => KuisScreen(modul: widget.modul),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: const Text(
                  'Mulai Kuis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
