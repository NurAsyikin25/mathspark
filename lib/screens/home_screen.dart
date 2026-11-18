import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/hasil_kuis.dart';
import '../models/modul.dart';
import '../models/profil_siswa.dart';
import '../models/reward.dart';
import 'modul_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ProfilSiswa? _profil;
  List<Modul> _modulList = [];
  Map<int, HasilKuis> _hasilKuisMap = {};
  List<Reward> _rewards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final profil = await DatabaseHelper.instance.getProfil();
      final moduls = await DatabaseHelper.instance.getAllModul();
      final hasilList = await DatabaseHelper.instance.getAllHasilKuis();
      final rewards = await DatabaseHelper.instance.getAllReward();

      final Map<int, HasilKuis> mapHasil = {};
      for (final h in hasilList) {
        // Ambil hasil kuis terbaik atau terakhir untuk modul ini
        if (!mapHasil.containsKey(h.modulId) ||
            h.skorTerakhir > mapHasil[h.modulId]!.skorTerakhir) {
          mapHasil[h.modulId] = h;
        }
      }

      if (mounted) {
        setState(() {
          _profil = profil;
          _modulList = moduls;
          _hasilKuisMap = mapHasil;
          _rewards = rewards;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openModulDetail(Modul modul) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ModulDetailScreen(modul: modul),
      ),
    );
    // Refresh dashboard setelah kembali
    _loadDashboardData();
  }

  IconData _getModulIcon(int urutan) {
    switch (urutan) {
      case 1:
        return Icons.alt_route_rounded;
      case 2:
        return Icons.grid_4x4_rounded;
      case 3:
        return Icons.calculate_rounded;
      case 4:
        return Icons.show_chart_rounded;
      default:
        return Icons.menu_book_rounded;
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'MathSpark',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ========================================================
                    // 1. HEADER: MENYAPA, LEVEL, & LINEAR PROGRESS XP
                    // ========================================================
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: theme.colorScheme.primaryContainer.withOpacity(0.45),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: theme.colorScheme.primary,
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Halo $namaSiswa!',
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'SMK PPLG • Matematika Terapan',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Level $level',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // LinearProgressIndicator XP
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progres Level $level',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '$currentLevelXP / 100 XP ($totalXP Total XP)',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ========================================================
                    // 2. GRID 2 KOLOM MODUL TERSEDIA
                    // ========================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Modul Tersedia',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${_modulList.length} Modul',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_modulList.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text('Tidak ada modul yang ditemukan.'),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _modulList.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemBuilder: (context, index) {
                          final modul = _modulList[index];
                          final hasil = _hasilKuisMap[modul.id];

                          // Penentuan Status:
                          // "Terkunci" jika isLocked == true,
                          // "Selesai" jika sudah ada HasilKuis >= 70,
                          // atau "Belum dimulai"
                          final bool isLocked = modul.isLocked;
                          final bool isSelesai = hasil != null && hasil.skorTerakhir >= 70;
                          final bool sudahAdaPengerjaan = hasil != null;

                          String statusText;
                          Color statusColor;
                          Color statusBgColor;

                          if (isLocked) {
                            statusText = 'Terkunci';
                            statusColor = Colors.grey.shade700;
                            statusBgColor = Colors.grey.shade200;
                          } else if (isSelesai) {
                            statusText = 'Selesai';
                            statusColor = Colors.green.shade800;
                            statusBgColor = Colors.green.shade100;
                          } else {
                            statusText = 'Belum dimulai';
                            statusColor = Colors.blue.shade800;
                            statusBgColor = Colors.blue.shade100;
                          }

                          // Penentuan Tombol Aksi:
                          // Terkunci disabled, Mulai jika belum dimulai, atau Lanjut
                          String buttonText;
                          VoidCallback? onAction;

                          if (isLocked) {
                            buttonText = 'Terkunci';
                            onAction = null;
                          } else if (!sudahAdaPengerjaan) {
                            buttonText = 'Mulai';
                            onAction = () => _openModulDetail(modul);
                          } else {
                            buttonText = 'Lanjut';
                            onAction = () => _openModulDetail(modul);
                          }

                          return Card(
                            elevation: isLocked ? 0 : 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isLocked
                                    ? Colors.grey.shade300
                                    : theme.colorScheme.outlineVariant.withOpacity(0.5),
                              ),
                            ),
                            color: isLocked ? Colors.grey.shade50 : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Ikon Modul
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isLocked
                                          ? Colors.grey.shade200
                                          : theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isLocked ? Icons.lock : _getModulIcon(modul.urutan),
                                      color: isLocked
                                          ? Colors.grey.shade600
                                          : theme.colorScheme.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Judul Modul
                                  Text(
                                    modul.judul,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isLocked
                                          ? Colors.grey.shade600
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const Spacer(),

                                  // Badge Status
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusBgColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Tombol Aksi
                                  SizedBox(
                                    width: double.infinity,
                                    height: 36,
                                    child: ElevatedButton(
                                      onPressed: onAction,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor: Colors.grey.shade300,
                                        disabledForegroundColor: Colors.grey.shade600,
                                        elevation: 0,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        buttonText,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 28),

                    // ========================================================
                    // 3. BADGES & PENCAPAIAN SAYA
                    // ========================================================
                    Text(
                      'Badges & Pencapaian Saya',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_rewards.isEmpty)
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text('Belum ada reward yang terdaftar.'),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 125,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _rewards.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final badge = _rewards[index];
                            final bool sudahDapat = badge.sudahDapat;

                            return Tooltip(
                              message: '${badge.namaBadge}\n${badge.deskripsi}',
                              child: Container(
                                width: 100,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: sudahDapat
                                      ? Colors.amber.shade50
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: sudahDapat
                                        ? Colors.amber.shade400
                                        : Colors.grey.shade300,
                                    width: sudahDapat ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Ikon Badge (warna aktif / redup)
                                    Container(
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
                                            : Colors.grey.shade400,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      badge.namaBadge,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: sudahDapat
                                            ? Colors.black87
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
