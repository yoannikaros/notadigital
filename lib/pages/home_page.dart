import 'package:flutter/material.dart';
import 'customer_page.dart';
import 'barang_page.dart';
import 'service_page.dart';
import 'transaksi_page.dart';
import 'settings_page.dart';
import '../main.dart';
import '../services/backup_restore_service.dart';
import '../services/database_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BackupRestoreService _backupService = BackupRestoreService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  String _companyName = 'Lentera Komputer'; // Default value
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanyName();
  }

  Future<void> _loadCompanyName() async {
    try {
      final companySettings = await _databaseHelper.getCompanyInfo();
      if (mounted) {
        setState(() {
          _companyName = companySettings?.companyName ?? 'Lentera Komputer';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _companyName = 'Lentera Komputer';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Container(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Header Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.business_center,
                          size: 40,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _isLoading
                          ? const SizedBox(
                            height: 28,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                          : Text(
                            _companyName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sistem Manajemen Service Komputer',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Menu Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                  children: [
                    _buildModernMenuCard(
                      context,
                      title: 'Customer',
                      subtitle: 'Kelola data customer',
                      icon: Icons.people_rounded,
                      color: const Color(0xFF2196F3),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomerPage(),
                          ),
                        );
                      },
                    ),
                    _buildModernMenuCard(
                      context,
                      title: 'Barang',
                      subtitle: 'Kelola data barang',
                      icon: Icons.devices_rounded,
                      color: const Color(0xFF4CAF50),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BarangPage(),
                          ),
                        );
                      },
                    ),
                    _buildModernMenuCard(
                      context,
                      title: 'Service',
                      subtitle: 'Kelola data service',
                      icon: Icons.build_rounded,
                      color: const Color(0xFFFF9800),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ServicePage(),
                          ),
                        );
                      },
                    ),
                    _buildModernMenuCard(
                      context,
                      title: 'Kasir',
                      subtitle: 'Kelola transaksi',
                      icon: Icons.point_of_sale_rounded,
                      color: const Color(0xFF9C27B0),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TransaksiPage(),
                          ),
                        );
                      },
                    ),
                    _buildModernMenuCard(
                      context,
                      title: 'Pengaturan',
                      subtitle: 'Kelola pengaturan',
                      icon: Icons.settings_rounded,
                      color: const Color(0xFFE91E63),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                        // Reload company name when returning from settings
                        _loadCompanyName();
                      },
                    ),
                    // _buildModernMenuCard(
                    //   context,
                    //   title: 'Backup DB',
                    //   subtitle: 'Backup database',
                    //   icon: Icons.backup_rounded,
                    //   gradient: const LinearGradient(
                    //     colors: [Color(0xFF26A69A), Color(0xFF00897B)],
                    //   ),
                    //   onTap: () => _handleBackup(context),
                    // ),
                    // _buildModernMenuCard(
                    //   context,
                    //   title: 'Restore DB',
                    //   subtitle: 'Restore database',
                    //   icon: Icons.restore_rounded,
                    //   gradient: const LinearGradient(
                    //     colors: [Color(0xFFEF5350), Color(0xFFF44336)],
                    //   ),
                    //   onTap: () => _handleRestore(context),
                    // ),
                  ],
                ),

                const SizedBox(height: 40),

                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Nota Digital v1.0\n© 2025 - Sistem Manajemen Service',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleBackup(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Membuat backup...'),
                ],
              ),
            ),
      );

      final result = await _backupService.exportBackupToFile();

      // Close loading dialog
      Navigator.of(context).pop();

      if (result['success']) {
        _showSuccessDialog(context, 'Backup Berhasil', result['message']);
      } else {
        _showErrorDialog(context, 'Backup Gagal', result['message']);
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog(context, 'Error', 'Terjadi kesalahan: $e');
    }
  }

  Future<void> _handleRestore(BuildContext context) async {
    try {
      // Show confirmation dialog
      final confirm = await _showConfirmDialog(
        context,
        'Konfirmasi Restore',
        'Restore akan menghapus semua data yang ada dan menggantinya dengan data dari backup. Apakah Anda yakin?',
      );

      if (!confirm) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Melakukan restore...'),
                ],
              ),
            ),
      );

      final result = await _backupService.importAndRestoreFromFile();

      // Close loading dialog
      Navigator.of(context).pop();

      if (result['success']) {
        _showSuccessDialog(context, 'Restore Berhasil', result['message']);
      } else {
        _showErrorDialog(context, 'Restore Gagal', result['message']);
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog(context, 'Error', 'Terjadi kesalahan: $e');
    }
  }

  Future<bool> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(title),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Ya, Lanjutkan'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _showSuccessDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _buildModernMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.white),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
