import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/hasil_kuis.dart';
import '../models/modul.dart';
import '../models/profil_siswa.dart';
import '../models/reward.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  ProfilSiswa? _profil;
  List<Reward> _rewards = [];
  List<Modul> _modulList = [];
  List<HasilKuis> _hasilList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final profil = await DatabaseHelper.instance.getProfil();
      final rewards = await DatabaseHelper.instance.getAllReward();
      final moduls = await DatabaseHelper.instance.getAllModul();
      final hasil = await DatabaseHelper.instance.getAllHasilKuis();

      if (mounted) {
        setState(() {
          _profil = profil;
          _rewards = rewards;
          _modulList = moduls;
          _hasilList = hasil;
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

  Future<void> _showEditNamaDialog() async {
    final currentNama = _profil?.namaSiswa ?? '';
    final controller = TextEditingController(text: currentNama);

    final String? namaBaru = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: Color(0xFF3F51B5)),
              SizedBox(width: 8),
              Text('Ubah Nama Panggilan'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan nama panggilan barumu untuk sapaan di MathSpark:',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Nama panggilan...',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nama panggilan tidak boleh kosong!'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(trimmed);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (namaBaru != null && namaBaru.isNotEmpty && namaBaru != currentNama) {
      try {
        final updatedProfil = (_profil != null)
            ? _profil!.copyWith(namaSiswa: namaBaru)
            : ProfilSiswa(
                namaSiswa: namaBaru,
                totalXP: 0,
                createdAt: DateTime.now(),
              );

        await DatabaseHelper.instance.upsertProfil(updatedProfil);

        if (mounted) {
          setState(() {
            _profil = updatedProfil;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nama panggilan berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memperbarui nama: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final namaSiswa = (_profil?.namaSiswa.isNotEmpty == true)
        ? _profil!.namaSiswa
        : 'Siswa';
    final totalXP = _profil?.totalXP ?? 0;

    // Perhitungan Level dan Progres XP
    final level = (totalXP ~/ 100) + 1;
    final xpProgress = (totalXP % 100) / 100.0;
    final currentLevelXP = totalXP % 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil & Riwayat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // ========================================================
                  // 1. KARTU PROFIL: NAMA + TOMBOL EDIT PENSIL
                  // ========================================================
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.person_rounded,
                              size: 46,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Nama Siswa + Ikon Pensil Edit
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  namaSiswa,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_rounded,
                                  size: 20,
                                  color: Color(0xFF3F51B5),
                                ),
                                tooltip: 'Ubah Nama Panggilan',
                                onPressed: _showEditNamaDialog,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Siswa SMK Program Keahlian PPLG',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // ========================================================
                          // 2. LEVEL & PROGRESS BAR XP SISWA
                          // ========================================================
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Level $level',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Progres Level',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '$currentLevelXP / 100 XP',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: xpProgress,
                                    minHeight: 10,
                                    backgroundColor: Colors.black.withOpacity(0.08),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '$totalXP Total XP Dikumpulkan',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ========================================================
                  // 3. BAGIAN BADGES & PENCAPAIAN SAYA
                  // ========================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Badges & Pencapaian Saya',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        '${_rewards.where((r) => r.sudahDapat).length}/${_rewards.length} Diraih',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_rewards.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Belum ada badge yang tersedia.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._rewards.map((badge) {
                      final bool sudahDapat = badge.sudahDapat;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: sudahDapat
                                ? Colors.amber.shade300
                                : Colors.grey.shade300,
                            width: sudahDapat ? 1.4 : 1,
                          ),
                        ),
                        color: sudahDapat ? Colors.amber.shade50.withOpacity(0.5) : null,
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: sudahDapat
                                  ? Colors.amber.shade100
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              sudahDapat
                                  ? Icons.emoji_events_rounded
                                  : Icons.lock_outline_rounded,
                              color: sudahDapat
                                  ? Colors.amber.shade800
                                  : Colors.grey.shade500,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            badge.namaBadge,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: sudahDapat ? Colors.black87 : Colors.grey.shade700,
                            ),
                          ),
                          subtitle: Text(
                            badge.deskripsi,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: sudahDapat
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Diraih',
                                    style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Terkunci',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),

                  // ========================================================
                  // 4. DAFTAR RIWAYAT SKOR PER MODUL
                  // ========================================================
                  Text(
                    'Riwayat Skor Kuis',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_modulList.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Belum ada modul yang terdaftar.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._modulList.map((modul) {
                      // Cari skor terbaik siswa untuk modul ini
                      final hasilModul = _hasilList.where((h) => h.modulId == modul.id);
                      final int? skorTerbaik = hasilModul.isNotEmpty
                          ? hasilModul
                              .map((h) => h.skorTerakhir)
                              .reduce((a, b) => a > b ? a : b)
                          : null;

                      final bool sudahDikerjakan = skorTerbaik != null;
                      final bool isLulus = sudahDikerjakan && skorTerbaik >= 70;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: sudahDikerjakan
                                ? (isLulus
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100)
                                : Colors.grey.shade100,
                            child: Icon(
                              sudahDikerjakan
                                  ? (isLulus
                                      ? Icons.check_circle_rounded
                                      : Icons.schedule_rounded)
                                  : Icons.quiz_outlined,
                              color: sudahDikerjakan
                                  ? (isLulus
                                      ? Colors.green.shade800
                                      : Colors.orange.shade800)
                                  : Colors.grey.shade500,
                            ),
                          ),
                          title: Text(
                            modul.judul,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          subtitle: Text(
                            'Modul ${modul.urutan}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                sudahDikerjakan ? '$skorTerbaik / 100' : 'Belum kuis',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: sudahDikerjakan
                                      ? (isLulus ? Colors.green.shade800 : Colors.orange.shade900)
                                      : Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sudahDikerjakan
                                    ? (isLulus ? 'Lulus' : 'Remedial')
                                    : '-',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: sudahDikerjakan
                                      ? (isLulus ? Colors.green.shade700 : Colors.orange.shade800)
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
