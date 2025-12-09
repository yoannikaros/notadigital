import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/barang_model.dart';
import '../services/database_helper.dart';
import '../services/pdf_service.dart';
import 'package:open_file/open_file.dart';

class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color background = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFB00020);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
}

class BarangPage extends StatefulWidget {
  const BarangPage({super.key});

  @override
  State<BarangPage> createState() => _BarangPageState();
}

class _BarangPageState extends State<BarangPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Barang> _barangList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBarang();
  }

  Future<void> _loadBarang() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final barangList = await _databaseHelper.getAllBarang();
      setState(() {
        _barangList = barangList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteBarang(int id) async {
    try {
      await _databaseHelper.deleteBarang(id);
      _loadBarang();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barang berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting barang: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _generatePdfReport() async {
    if (_barangList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data barang untuk diekspor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Generating PDF...'),
            ],
          ),
        );
      },
    );

    try {
      final pdfFile = await PdfService.generateBarangReportPdf(_barangList);
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('PDF Generated'),
              content: Text('PDF berhasil disimpan di: ${pdfFile.path}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    OpenFile.open(pdfFile.path);
                  },
                  child: const Text('Open PDF'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(Barang barang) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Konfirmasi Hapus',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apakah Anda yakin ingin menghapus barang ini?',
                style: AppTextStyles.body1,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: ${barang.id}',
                      style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w500),
                    ),
                    if (barang.supplier != null && barang.supplier!.isNotEmpty)
                      Text('Supplier: ${barang.supplier}'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBarang(barang.id!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _showOutflowDialog(Barang barang) {
    final TextEditingController outflowController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.secondary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.output_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Catat Barang Keluar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        barang.nama ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stock info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.inventory_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${barang.stok ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            const Text(
                              'Stok Tersedia',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: barang.sisaStok > 0 ? Colors.green : Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${barang.sisaStok}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: barang.sisaStok > 0 ? Colors.green : Colors.orange,
                              ),
                            ),
                            const Text(
                              'Sisa Stok',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Outflow amount input
                const Text(
                  'Jumlah Keluar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: outflowController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Masukkan jumlah barang keluar',
                      prefixIcon: const Icon(
                        Icons.output_outlined,
                        color: AppColors.primary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Note input
                const Text(
                  'Catatan (Opsional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tambahkan catatan untuk barang keluar ini...',
                      prefixIcon: const Icon(
                        Icons.note_outlined,
                        color: AppColors.secondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final outflowAmount = int.tryParse(outflowController.text);
                if (outflowAmount != null && outflowAmount > 0) {
                  if (outflowAmount <= barang.sisaStok) {
                    Navigator.of(context).pop();
                    _recordOutflow(barang, outflowAmount, noteController.text);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Jumlah keluar melebihi stok yang tersedia!'),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Masukkan jumlah yang valid!'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Catat Keluar',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _recordOutflow(Barang barang, int outflowAmount, String note) async {
    try {
      // Update the outflow amount
      final updatedBarang = Barang(
        id: barang.id,
        nama: barang.nama,
        supplier: barang.supplier,
        tanggalPembelian: barang.tanggalPembelian,
        hppModal: barang.hppModal,
        hargaJual: barang.hargaJual,
        stok: barang.stok,
        keluar: (barang.keluar ?? 0) + outflowAmount,
      );

      await DatabaseHelper().updateBarang(updatedBarang);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Berhasil mencatat $outflowAmount ${barang.nama} keluar',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      // Reload the data
      _loadBarang();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manajemen Barang',
          style: AppTextStyles.heading2,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _barangList.isEmpty ? null : _generatePdfReport,
            tooltip: 'Export ke PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _barangList.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada data barang',
                        style: AppTextStyles.heading2,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap tombol + untuk menambah barang baru',
                        style: AppTextStyles.body2,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _barangList.length,
                  itemBuilder: (context, index) {
                    final barang = _barangList[index];
                    return GestureDetector(
                      onTap: () => _showOutflowDialog(barang),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.grey.shade50,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                              spreadRadius: 0,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _showOutflowDialog(barang),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header with modern design
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [AppColors.primary, AppColors.secondary],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'ID: ${barang.id}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      // Action buttons with modern design
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => BarangFormPage(barang: barang),
                                              ),
                                            );
                                            if (result == true) {
                                              _loadBarang();
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppColors.error,
                                            size: 20,
                                          ),
                                          onPressed: () => _showDeleteConfirmation(barang),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Nama Barang with modern styling
                                  if (barang.nama != null && barang.nama!.isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primary.withValues(alpha: 0.05),
                                            AppColors.secondary.withValues(alpha: 0.05),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.inventory_2_outlined,
                                              color: AppColors.primary,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Nama Barang',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textSecondary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  barang.nama!,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Info Grid with modern cards
                                  Row(
                                    children: [
                                      // Supplier Card
                                      if (barang.supplier != null && barang.supplier!.isNotEmpty)
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.blue.withValues(alpha: 0.1),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.business_outlined,
                                                      color: Colors.blue.shade600,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    const Text(
                                                      'Supplier',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors.textSecondary,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  barang.supplier!,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.blue.shade700,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      
                                      if (barang.supplier != null && barang.supplier!.isNotEmpty && barang.tanggalPembelian != null)
                                        const SizedBox(width: 12),
                                      
                                      // Date Card
                                      if (barang.tanggalPembelian != null)
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.orange.withValues(alpha: 0.1),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_today_outlined,
                                                      color: Colors.orange.shade600,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    const Text(
                                                      'Tanggal',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors.textSecondary,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${barang.tanggalPembelian!.day}/${barang.tanggalPembelian!.month}/${barang.tanggalPembelian!.year}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.orange.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Price Information
                                  if (barang.hppModal != null || barang.hargaJual != null)
                                    Row(
                                      children: [
                                        // HPP Modal
                                        if (barang.hppModal != null)
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withValues(alpha: 0.05),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.green.withValues(alpha: 0.1),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.attach_money_outlined,
                                                        color: Colors.green.shade600,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      const Text(
                                                        'HPP Modal',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: AppColors.textSecondary,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    NumberFormatter.formatCurrency(barang.hppModal),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.green.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        
                                        if (barang.hppModal != null && barang.hargaJual != null)
                                          const SizedBox(width: 12),
                                        
                                        // Harga Jual
                                        if (barang.hargaJual != null)
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.withValues(alpha: 0.05),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.purple.withValues(alpha: 0.1),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.sell_outlined,
                                                        color: Colors.purple.shade600,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      const Text(
                                                        'Harga Jual',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: AppColors.textSecondary,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    NumberFormatter.formatCurrency(barang.hargaJual),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.purple.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Stock Information with modern design
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey.shade50,
                                          Colors.white,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Stok
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Icon(
                                                    Icons.inventory_outlined,
                                                    color: AppColors.primary,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${barang.stok ?? 0}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                                const Text(
                                                  'Stok',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textSecondary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        
                                        const SizedBox(width: 12),
                                        
                                        // Keluar
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.error.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.error.withValues(alpha: 0.1),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.error.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Icon(
                                                    Icons.output_outlined,
                                                    color: AppColors.error,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${barang.keluar ?? 0}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                    color: AppColors.error,
                                                  ),
                                                ),
                                                const Text(
                                                  'Keluar',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textSecondary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        
                                        const SizedBox(width: 12),
                                        
                                        // Sisa
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: barang.sisaStok > 0 
                                                  ? Colors.green.withValues(alpha: 0.05)
                                                  : Colors.orange.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: barang.sisaStok > 0 
                                                    ? Colors.green.withValues(alpha: 0.1)
                                                    : Colors.orange.withValues(alpha: 0.1),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: barang.sisaStok > 0 
                                                        ? Colors.green.withValues(alpha: 0.1)
                                                        : Colors.orange.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    barang.sisaStok > 0 
                                                        ? Icons.check_circle_outline
                                                        : Icons.warning_outlined,
                                                    color: barang.sisaStok > 0 ? Colors.green : Colors.orange,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${barang.sisaStok}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                    color: barang.sisaStok > 0 ? Colors.green : Colors.orange,
                                                  ),
                                                ),
                                                const Text(
                                                  'Sisa',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textSecondary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Click to record outflow hint
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.secondary.withValues(alpha: 0.1),
                                          AppColors.primary.withValues(alpha: 0.05),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.secondary.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.touch_app_outlined,
                                            color: AppColors.secondary,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Expanded(
                                          child: Text(
                                            'Tap kartu untuk catat barang keluar',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          color: AppColors.secondary,
                                          size: 14,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BarangFormPage(),
            ),
          );
          if (result == true) {
            _loadBarang();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah Barang',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class BarangFormPage extends StatefulWidget {
  final Barang? barang;

  const BarangFormPage({super.key, this.barang});

  @override
  State<BarangFormPage> createState() => _BarangFormPageState();
}

class _BarangFormPageState extends State<BarangFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _supplierController = TextEditingController();
  final _hppModalController = TextEditingController();
  final _hargaJualController = TextEditingController();
  final _stokController = TextEditingController();
  final _keluarController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  DateTime? _selectedTanggalPembelian;
  bool _isLoading = false;
  
  // Add calculated remaining stock
  int _sisaStok = 0;

  @override
  void initState() {
    super.initState();
    if (widget.barang != null) {
      _populateFields();
    }
    
    // Add listeners for automatic stock calculation
    _stokController.addListener(_calculateSisaStok);
    _keluarController.addListener(_calculateSisaStok);
  }

  @override
  void dispose() {
    _stokController.removeListener(_calculateSisaStok);
    _keluarController.removeListener(_calculateSisaStok);
    _namaController.dispose();
    _supplierController.dispose();
    _hppModalController.dispose();
    _hargaJualController.dispose();
    _stokController.dispose();
    _keluarController.dispose();
    super.dispose();
  }

  void _calculateSisaStok() {
    final stok = int.tryParse(_stokController.text) ?? 0;
    final keluar = int.tryParse(_keluarController.text) ?? 0;
    setState(() {
      _sisaStok = stok - keluar;
    });
  }

  void _populateFields() {
    _namaController.text = widget.barang!.nama ?? '';
    _supplierController.text = widget.barang!.supplier ?? '';
    _hppModalController.text = widget.barang!.hppModal != null ? NumberFormatter.formatNumber(widget.barang!.hppModal) : '';
    _hargaJualController.text = widget.barang!.hargaJual != null ? NumberFormatter.formatNumber(widget.barang!.hargaJual) : '';
    _stokController.text = widget.barang!.stok?.toString() ?? '';
    _keluarController.text = widget.barang!.keluar?.toString() ?? '';
    _selectedTanggalPembelian = widget.barang!.tanggalPembelian;
    
    // Calculate initial sisa stok
    _calculateSisaStok();
  }

  // Helper method to parse formatted number back to double
  double? _parseFormattedNumber(String text) {
    if (text.isEmpty) return null;
    String digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');
    return digitsOnly.isEmpty ? null : double.tryParse(digitsOnly);
  }

  Future<void> _saveBarang() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final barang = Barang(
        id: widget.barang?.id,
        nama: _namaController.text.isEmpty ? null : _namaController.text,
        supplier: _supplierController.text.isEmpty ? null : _supplierController.text,
        tanggalPembelian: _selectedTanggalPembelian,
        hppModal: _parseFormattedNumber(_hppModalController.text),
        hargaJual: _parseFormattedNumber(_hargaJualController.text),
        stok: _stokController.text.isEmpty ? null : int.tryParse(_stokController.text),
        keluar: _keluarController.text.isEmpty ? null : int.tryParse(_keluarController.text),
      );

      if (widget.barang == null) {
        await _databaseHelper.insertBarang(barang);
      } else {
        await _databaseHelper.updateBarang(barang);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.barang == null ? 'Tambah Barang' : 'Edit Barang',
          style: AppTextStyles.heading2,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nama Barang
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Barang',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Supplier/Distributor
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Supplier/Distributor',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tanggal Pembelian
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedTanggalPembelian ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedTanggalPembelian = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTanggalPembelian == null
                            ? 'Pilih Tanggal Pembelian'
                            : '${_selectedTanggalPembelian!.day}/${_selectedTanggalPembelian!.month}/${_selectedTanggalPembelian!.year}',
                        style: TextStyle(
                          color: _selectedTanggalPembelian == null
                              ? Colors.grey[600]
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // HPP Modal
              TextFormField(
                controller: _hppModalController,
                decoration: const InputDecoration(
                  labelText: 'HPP Modal',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
              ),
              
              const SizedBox(height: 16),
              
              // Harga Jual
              TextFormField(
                controller: _hargaJualController,
                decoration: const InputDecoration(
                  labelText: 'Harga Jual',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sell),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
              ),
              
              const SizedBox(height: 16),
              
              // Stock Information Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Stok',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        // Stok
                        Expanded(
                          child: TextFormField(
                            controller: _stokController,
                            decoration: const InputDecoration(
                              labelText: 'Stok',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.inventory),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Keluar
                        Expanded(
                          child: TextFormField(
                            controller: _keluarController,
                            decoration: const InputDecoration(
                              labelText: 'Keluar',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.output),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Sisa Stok Display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _sisaStok >= 0 ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _sisaStok >= 0 ? Colors.green : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _sisaStok >= 0 ? Icons.check_circle : Icons.warning,
                            color: _sisaStok >= 0 ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sisa Stok: $_sisaStok',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _sisaStok >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBarang,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.barang == null ? 'Simpan Barang' : 'Update Barang',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
}

class NumberFormatter {
  static final NumberFormat _formatter = NumberFormat('#,###', 'id_ID');
  
  static String formatCurrency(double? value) {
    if (value == null) return '0';
    return 'Rp ${_formatter.format(value.toInt())}';
  }
  
  static String formatNumber(double? value) {
    if (value == null) return '0';
    return _formatter.format(value.toInt());
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Format with thousand separators
    final formatter = NumberFormat('#,###', 'id_ID');
    String formatted = formatter.format(int.parse(digitsOnly));

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}