import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Kebijakan Privasi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Icon
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.privacy_tip_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Introduction
                        const Text(
                          'Aplikasi Manajemen Service Toko Komputer',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E2E2E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Aplikasi ini dirancang untuk membantu Anda mengelola layanan toko komputer secara offline. Kami berkomitmen untuk melindungi privasi dan keamanan data Anda.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section 1
                        _buildSection(
                          title: '1. Pengumpulan Data',
                          content:
                              'Aplikasi ini mengumpulkan dan menyimpan data berikut untuk keperluan operasional usaha Anda:\n\n'
                              '• Informasi pelanggan (nama, nomor HP, alamat)\n'
                              '• Data barang dan layanan service\n'
                              '• Catatan transaksi dan invoice\n'
                              '• Informasi usaha Anda (nama, alamat, kontak)',
                        ),

                        // Section 2
                        _buildSection(
                          title: '2. Penyimpanan Data',
                          content:
                              'Semua data disimpan secara LOKAL di perangkat Anda:\n\n'
                              '• Data tidak dikirim ke server atau cloud\n'
                              '• Data tidak dibagikan dengan pihak ketiga\n'
                              '• Aplikasi bekerja sepenuhnya offline\n'
                              '• Anda memiliki kontrol penuh atas data Anda',
                        ),

                        // Section 3
                        _buildSection(
                          title: '3. Penggunaan Data',
                          content:
                              'Data yang dikumpulkan digunakan untuk:\n\n'
                              '• Mengelola informasi pelanggan dan transaksi\n'
                              '• Membuat invoice dan laporan service\n'
                              '• Menyimpan riwayat transaksi\n'
                              '• Memudahkan operasional toko komputer Anda',
                        ),

                        // Section 4
                        _buildSection(
                          title: '4. Keamanan Data',
                          content:
                              'Kami menerapkan langkah keamanan berikut:\n\n'
                              '• Data disimpan dalam database lokal yang terenkripsi\n'
                              '• Tidak ada transmisi data ke internet\n'
                              '• Fitur backup untuk mencegah kehilangan data\n'
                              '• Akses data hanya melalui perangkat Anda',
                        ),

                        // Section 5
                        _buildSection(
                          title: '5. Hak Pengguna',
                          content:
                              'Sebagai pengguna aplikasi, Anda memiliki hak untuk:\n\n'
                              '• Mengakses semua data yang tersimpan\n'
                              '• Mengedit atau menghapus data kapan saja\n'
                              '• Membuat backup data Anda\n'
                              '• Menghapus aplikasi beserta semua datanya',
                        ),

                        // Section 6
                        _buildSection(
                          title: '6. Izin Aplikasi',
                          content:
                              'Aplikasi ini memerlukan izin berikut:\n\n'
                              '• Penyimpanan: Untuk menyimpan database dan file PDF\n'
                              '• Kontak (opsional): Untuk memilih pelanggan dari kontak HP\n\n'
                              'Semua izin digunakan hanya untuk fungsi aplikasi dan tidak untuk tujuan lain.',
                        ),

                        // Section 7
                        _buildSection(
                          title: '7. Backup dan Restore',
                          content:
                              'Anda dapat membuat backup data Anda:\n\n'
                              '• Backup disimpan sebagai file lokal\n'
                              '• Anda bertanggung jawab menyimpan file backup\n'
                              '• Data dapat di-restore dari file backup\n'
                              '• Disarankan membuat backup secara berkala',
                        ),

                        // Section 8
                        _buildSection(
                          title: '8. Perubahan Kebijakan',
                          content:
                              'Kebijakan privasi ini dapat diperbarui dari waktu ke waktu. '
                              'Perubahan signifikan akan diberitahukan melalui pembaruan aplikasi.',
                        ),

                        // Section 9
                        _buildSection(
                          title: '9. Kontak',
                          content:
                              'Jika Anda memiliki pertanyaan tentang kebijakan privasi ini, '
                              'Anda dapat menghubungi pengembang aplikasi melalui informasi kontak '
                              'yang tersedia di halaman distribusi aplikasi.',
                        ),

                        const SizedBox(height: 24),

                        // Footer
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.blue.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Aplikasi ini sepenuhnya offline dan tidak mengumpulkan data pribadi Anda untuk tujuan komersial.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF666666),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        Center(
                          child: Text(
                            'Terakhir diperbarui: Desember 2025',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E2E2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
