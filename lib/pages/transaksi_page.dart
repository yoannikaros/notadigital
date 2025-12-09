import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/transaksi_model.dart';
import '../models/transaksi_detail_model.dart';
import '../models/customer_model.dart';
import '../models/barang_model.dart';
import '../models/service_model.dart';
import '../models/invoice_model.dart';
import '../models/contact_info_model.dart';
import '../services/database_helper.dart';
import '../services/pdf_service.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'dart:convert';

// Custom TextInputFormatter untuk format ribuan
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static const _separator = '.';
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Hapus semua karakter non-digit
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // Format dengan separator ribuan
    String formattedText = _addThousandsSeparator(newText);
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
  
  static String _addThousandsSeparator(String value) {
    if (value.isEmpty) return '';
    
    // Reverse string untuk memudahkan penambahan separator
    String reversed = value.split('').reversed.join('');
    String formatted = '';
    
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formatted += _separator;
      }
      formatted += reversed[i];
    }
    
    // Reverse kembali untuk mendapatkan format yang benar
    return formatted.split('').reversed.join('');
  }
}

// Utility functions untuk formatting dan parsing
class NumberUtils {
  static String formatToThousands(double? value) {
    if (value == null) return '';
    return NumberFormat('#,###', 'id_ID').format(value.toInt()).replaceAll(',', '.');
  }
  
  static double? parseFromThousands(String value) {
    if (value.isEmpty) return null;
    // Hapus semua separator dan parse ke double
    String cleanValue = value.replaceAll('.', '');
    return double.tryParse(cleanValue);
  }
}

class TransaksiPage extends StatefulWidget {
  const TransaksiPage({super.key});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _transaksiList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransaksi();
  }

  Future<void> _loadTransaksi() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final transaksiList = await _databaseHelper.getTransaksiWithDetails();
      setState(() {
        _transaksiList = transaksiList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transaksi: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(Map<String, dynamic> transaksi) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus transaksi ${transaksi['no_invoice']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseHelper.deleteTransaksi(transaksi['transaksi_id']);
        _loadTransaksi();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting transaksi: $e')),
          );
        }
      }
    }
  }

  String _getCustomerDisplayName(Map<String, dynamic> transaksi) {
    // Jika ada data kontak dari HP
    if (transaksi['contact_source'] == 'contact' && transaksi['contact_data'] != null) {
      try {
        final contactJson = jsonDecode(transaksi['contact_data']);
        final contactInfo = ContactInfo.fromJson(contactJson);
        return contactInfo.name ?? 'Customer umum';
      } catch (e) {
        print('Error parsing contact data: $e');
      }
    }
    
    // Jika ada nama customer dari database
    if (transaksi['customer_nama'] != null) {
      return transaksi['customer_nama'];
    }
    
    // Default fallback
    return 'Customer umum';
  }



  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Transaksi',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _transaksiList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 80,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada transaksi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap tombol + untuk membuat transaksi baru',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTransaksi,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transaksiList.length,
                    itemBuilder: (context, index) {
                      final transaksi = _transaksiList[index];
                      final tanggal = DateTime.parse(transaksi['tanggal']);
                      final isLunas = transaksi['status'] == 'Lunas';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransaksiFormPage(
                                  transaksiId: transaksi['transaksi_id'],
                                ),
                              ),
                            );
                            if (result == true) {
                              _loadTransaksi();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        transaksi['no_invoice'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isLunas
                                            ? Colors.green.shade100
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isLunas
                                              ? Colors.green.shade300
                                              : Colors.orange.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        transaksi['status'],
                                        style: TextStyle(
                                          color: isLunas
                                              ? Colors.green.shade700
                                              : Colors.orange.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 16,
                                      color: colorScheme.outline,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _getCustomerDisplayName(transaksi),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 16,
                                      color: colorScheme.outline,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${tanggal.day}/${tanggal.month}/${tanggal.year}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Subtotal',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            'Rp ${NumberUtils.formatToThousands(transaksi['subtotal']?.toDouble())}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'DP',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                            'Rp ${NumberUtils.formatToThousands(transaksi['dp']?.toDouble()) ?? '0'}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                                        ],
                                      ),
                                      const Divider(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Sisa',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          Text(
                            'Rp ${NumberUtils.formatToThousands(transaksi['sisa']?.toDouble()) ?? '0'}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isLunas
                                  ? Colors.green.shade600
                                  : Colors.orange.shade600,
                            ),
                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TransaksiFormPage(
                                              transaksiId: transaksi['transaksi_id'],
                                            ),
                                          ),
                                        );
                                        if (result == true) {
                                          _loadTransaksi();
                                        }
                                      },
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        color: colorScheme.primary,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => _showDeleteConfirmation(transaksi),
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: colorScheme.error,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: colorScheme.error.withValues(alpha: 0.1),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TransaksiFormPage(),
            ),
          );
          if (result == true) {
            _loadTransaksi();
          }
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Transaksi Baru'),
        elevation: 4,
      ),
    );
  }
}

class TransaksiFormPage extends StatefulWidget {
  final int? transaksiId;

  const TransaksiFormPage({super.key, this.transaksiId});

  @override
  State<TransaksiFormPage> createState() => _TransaksiFormPageState();
}

class _TransaksiFormPageState extends State<TransaksiFormPage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  // Form controllers
  final _noInvoiceController = TextEditingController();
  final _dpController = TextEditingController();
  final _metodePembayaranController = TextEditingController();
  final _merkBarangController = TextEditingController();
  final _snBarangController = TextEditingController();
  final _namaBarangController = TextEditingController();

  
  // Form data
  DateTime _selectedDate = DateTime.now();
  Customer? _selectedCustomer;
  ContactInfo? _selectedContact;
  CustomerSource _customerSource = CustomerSource.database;
  String _selectedStatus = 'Belum Lunas';
  List<Customer> _customers = [];
  List<Barang> _barangList = [];
  List<Service> _serviceList = [];
  List<TransaksiDetailItem> _detailItems = [];
  final FlutterNativeContactPicker _contactPicker = FlutterNativeContactPicker();
  
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _hideDataBarangInPdf = false; // Checkbox state for hiding data barang in PDF

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // Load customers, barang, and services
      final customers = await _databaseHelper.getAllCustomers();
      final barangList = await _databaseHelper.getAllBarang();
      final serviceList = await _databaseHelper.getAllServices();
      setState(() {
        _customers = customers;
        _barangList = barangList;
        _serviceList = serviceList;
      });

      if (widget.transaksiId != null) {
        // Load existing transaction
        await _loadTransaksi();
      } else {
        // Generate new invoice number
        final invoiceNumber = await _databaseHelper.generateInvoiceNumber();
        _noInvoiceController.text = invoiceNumber;
        // Set default values
        _dpController.text = '0';
        _metodePembayaranController.text = 'Transfer';
        // Add one empty detail item
        _detailItems.add(TransaksiDetailItem());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _loadTransaksi() async {
    if (widget.transaksiId == null) return;
    
    try {
      final transaksi = await _databaseHelper.getTransaksi(widget.transaksiId!);
      if (transaksi != null) {
        _noInvoiceController.text = transaksi.noInvoice;
        _selectedDate = transaksi.tanggal;
        _dpController.text = NumberUtils.formatToThousands(transaksi.dp);
        _selectedStatus = transaksi.status;
        _metodePembayaranController.text = transaksi.metodePembayaran ?? '';
        _merkBarangController.text = transaksi.merkBarang ?? '';
        _snBarangController.text = transaksi.snBarang ?? '';
        _namaBarangController.text = transaksi.namaBarang ?? '';
    
        
        // Load customer or contact data
        if (transaksi.contactSource == 'contact' && transaksi.contactData != null) {
          // Load contact from stored data
          try {
            final contactJson = jsonDecode(transaksi.contactData!);
            _selectedContact = ContactInfo.fromJson(contactJson);
            _customerSource = CustomerSource.contact;
          } catch (e) {
            print('Error loading contact data: $e');
          }
        } else if (transaksi.customerId != null) {
          // Load customer from database
          try {
            _selectedCustomer = _customers.firstWhere(
              (c) => c.id == transaksi.customerId,
            );
            _customerSource = CustomerSource.database;
          } catch (e) {
            // Customer not found, set to null
            _selectedCustomer = null;
          }
        }
        
        // Load transaction details
        final details = await _databaseHelper.getTransaksiDetails(widget.transaksiId!);
        _detailItems = details.map((detail) => TransaksiDetailItem(
          qty: detail.qty,
          deskripsi: detail.deskripsi,
          harga: detail.harga,
          barangId: detail.barangId,
          serviceId: detail.serviceId,
          namaBarang: detail.namaBarang,
          snBarang: detail.snBarang,
          garansi: detail.garansi,
        )).toList();
        
        if (_detailItems.isEmpty) {
          _detailItems.add(TransaksiDetailItem());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transaksi: $e')),
        );
      }
    }
  }

  void _addDetailItem() {
    setState(() {
      _detailItems.add(TransaksiDetailItem());
    });
  }

  void _removeDetailItem(int index) {
    if (_detailItems.length > 1) {
      setState(() {
        _detailItems.removeAt(index);
      });
    }
  }

  double _calculateSubtotal() {
    return _detailItems.fold(0.0, (sum, item) => sum + item.totalHarga);
  }

  double _calculateSisa() {
    final subtotal = _calculateSubtotal();
    final dp = NumberUtils.parseFromThousands(_dpController.text) ?? 0;
    return subtotal - dp;
  }



  Future<Invoice> _createInvoiceFromTransaksi(int transaksiId) async {
    // Get transaction data from database
    final transaksi = await _databaseHelper.getTransaksi(transaksiId);
    if (transaksi == null) {
      throw Exception('Transaksi tidak ditemukan');
    }
    
    // Debug log untuk transaksi yang diambil dari database
    print('DEBUG: Transaksi dari database - ID: $transaksiId, customerId: ${transaksi.customerId}');
    print('DEBUG: Transaksi data - noInvoice: ${transaksi.noInvoice}, status: ${transaksi.status}');
    print('DEBUG: Transaksi barang - merk: ${transaksi.merkBarang}, sn: ${transaksi.snBarang}, nama: ${transaksi.namaBarang}');
    print('DEBUG: Contact source: ${transaksi.contactSource}, Contact data: ${transaksi.contactData}');
    
    // Get customer data from database if exists
    Customer? customer;
    ContactInfo? contactInfo;
    
    // Check if contact data from phone contacts is available
    if (transaksi.contactSource == 'contact' && transaksi.contactData != null) {
      try {
        final contactJson = jsonDecode(transaksi.contactData!);
        contactInfo = ContactInfo.fromJson(contactJson);
        print('DEBUG: Contact dari kontak HP: ${contactInfo.name} - ${contactInfo.phoneNumber}');
      } catch (e) {
        print('DEBUG: Error parsing contact data: $e');
      }
    }
    
    // Get customer from database if no contact info and customerId exists
    if (contactInfo == null && transaksi.customerId != null) {
      customer = await _databaseHelper.getCustomer(transaksi.customerId!);
      print('DEBUG: Customer dari database: ${customer?.nama} (ID: ${customer?.id})');
    }
    
    if (contactInfo == null && customer == null) {
      print('DEBUG: Tidak ada customer atau contact data, menggunakan Customer Umum');
    }
    
    // Company info (hardcoded for now, bisa diambil dari settings)
    final company = CompanyInfo(
      name: 'Lentera Komputer',
      address: 'Jl. Contoh No. 123\nKota, Provinsi 12345',
      phone: '0821-1712-3434',
      email: 'lenteracomp.bdg@gmail.com',
      website: 'www.lenterakomputer.com',
    );
    
    // Client info - prioritize contact info from phone contacts
    final client = ClientInfo(
      name: contactInfo?.name ?? customer?.nama ?? 'Customer Umum',
      address: customer?.alamat ?? 'Alamat tidak tersedia',
      phone: contactInfo?.phoneNumber ?? customer?.noHp,
    );
    
    print('DEBUG: Client name yang akan digunakan dalam PDF: ${client.name}');
    print('DEBUG: Client phone yang akan digunakan dalam PDF: ${client.phone}');
    
    // Get transaction details from database
    final details = await _databaseHelper.getTransaksiDetails(transaksiId);
    print('DEBUG: Jumlah detail items: ${details.length}');
    
    // Validasi detail items
    if (details.isEmpty) {
      throw Exception('Tidak ada detail transaksi ditemukan');
    }
    
    // Convert detail items to invoice items
    final invoiceItems = details.map((detail) {
      print('DEBUG: Detail item - qty: ${detail.qty}, desc: ${detail.deskripsi}, harga: ${detail.harga}');
      return InvoiceItem(
        description: detail.deskripsi,
        quantity: detail.qty,
        unitPrice: detail.harga,
        namaBarang: detail.namaBarang?.trim().isEmpty == true ? null : detail.namaBarang?.trim(),
        snBarang: detail.snBarang?.trim().isEmpty == true ? null : detail.snBarang?.trim(),
        garansi: detail.garansi?.trim().isEmpty == true ? null : detail.garansi?.trim(),
      );
    }).toList();
    
    // Validasi konsistensi data
    final calculatedSubtotal = invoiceItems.fold(0.0, (sum, item) => sum + item.amount);
    print('DEBUG: Calculated subtotal: $calculatedSubtotal, DB subtotal: ${transaksi.subtotal}');
    
    final invoice = Invoice(
      invoiceNumber: transaksi.noInvoice,
      date: transaksi.tanggal,
      dueDate: transaksi.tanggal.add(const Duration(days: 30)), // 30 hari dari tanggal transaksi
      company: company,
      client: client,
      items: invoiceItems,
      taxRate: 0.0, // Tidak ada pajak untuk sekarang
      merkBarang: transaksi.merkBarang?.trim().isEmpty == true ? null : transaksi.merkBarang?.trim(),
      snBarang: transaksi.snBarang?.trim().isEmpty == true ? null : transaksi.snBarang?.trim(),
      namaBarang: transaksi.namaBarang?.trim().isEmpty == true ? null : transaksi.namaBarang?.trim(),
      dpAmount: transaksi.dp > 0 ? transaksi.dp : null,
      paymentStatus: transaksi.status,
      paymentMethod: transaksi.metodePembayaran?.trim().isEmpty == true ? 'Transfer Bank' : transaksi.metodePembayaran?.trim() ?? 'Transfer Bank',
    );
    
    print('DEBUG: Invoice created - hasDP: ${invoice.hasDP}, sisaAmount: ${invoice.sisaAmount}');
    
    return invoice;
  }

  Future<void> _generatePdf() async {
    if (widget.transaksiId == null) return;
    
    try {
      // Request storage permission
      await Permission.storage.request();

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Membuat PDF...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final invoice = await _createInvoiceFromTransaksi(widget.transaksiId!);
      final pdfFile = await PdfService.generateInvoicePdf(invoice, hideDataBarang: _hideDataBarangInPdf);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF berhasil dibuat'),
            action: SnackBarAction(
              label: 'Buka PDF',
              onPressed: () {
                OpenFile.open(pdfFile.path);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat PDF: $e')),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    if (widget.transaksiId == null) return;
    
    try {
      // Request storage permission
      await Permission.storage.request();

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Menyiapkan PDF untuk dibagikan...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final invoice = await _createInvoiceFromTransaksi(widget.transaksiId!);
      final pdfFile = await PdfService.generateInvoicePdf(invoice, hideDataBarang: _hideDataBarangInPdf);
      
      // Share the PDF file
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Invoice ${invoice.invoiceNumber}',
        subject: 'Invoice ${invoice.invoiceNumber}',
      );
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membagikan PDF: $e')),
        );
      }
    }
  }

  Future<void> _pickContact() async {
    try {
      final Contact? contact = await _contactPicker.selectContact();
      if (contact != null && contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
        setState(() {
          _selectedContact = ContactInfo(
            name: contact.fullName ?? 'Unknown',
            phoneNumber: contact.phoneNumbers!.first,
            displayName: contact.fullName,
          );
          _customerSource = CustomerSource.contact;
          _selectedCustomer = null; // Clear database customer selection
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking contact: $e')),
        );
      }
    }
  }

  void _selectCustomerSource(CustomerSource source) {
    setState(() {
      _customerSource = source;
      if (source == CustomerSource.database) {
        _selectedContact = null;
      } else {
        _selectedCustomer = null;
      }
    });
  }

  Future<void> _showAddCustomerDialog() async {
    final namaController = TextEditingController();
    final noHpController = TextEditingController();
    final alamatController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    bool isLoading = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxHeight: 500),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
                  ),
                ),
                child: Form(
                  key: dialogFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade400, Colors.purple.shade400],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tambah Customer Baru',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Masukkan data customer baru',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Form Fields
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Nama Field
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: TextFormField(
                                  controller: namaController,
                                  decoration: InputDecoration(
                                    labelText: 'Nama Lengkap',
                                    hintText: 'Masukkan nama customer',
                                    prefixIcon: Icon(
                                      Icons.person_rounded,
                                      color: Colors.blue.shade400,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Nama tidak boleh kosong';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // No HP Field
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: TextFormField(
                                  controller: noHpController,
                                  decoration: InputDecoration(
                                    labelText: 'No. HP',
                                    hintText: 'Masukkan nomor HP',
                                    prefixIcon: Icon(
                                      Icons.phone_rounded,
                                      color: Colors.blue.shade400,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'No. HP tidak boleh kosong';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Alamat Field
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: TextFormField(
                                  controller: alamatController,
                                  decoration: InputDecoration(
                                    labelText: 'Alamat (opsional)',
                                    hintText: 'Masukkan alamat',
                                    prefixIcon: Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.blue.shade400,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: TextButton(
                                onPressed: isLoading ? null : () {
                                  Navigator.of(dialogContext).pop(false);
                                },
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Batal',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: isLoading ? null : () async {
                                  if (dialogFormKey.currentState!.validate()) {
                                    setState(() {
                                      isLoading = true;
                                    });
                                    
                                    try {
                                      final customer = Customer(
                                        nama: namaController.text.trim(),
                                        noHp: noHpController.text.trim(),
                                        alamat: alamatController.text.trim().isEmpty 
                                            ? null 
                                            : alamatController.text.trim(),
                                      );
                                      
                                      await _databaseHelper.insertCustomer(customer);
                                      
                                      if (mounted) {
                                        Navigator.of(dialogContext).pop(true);
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    } finally {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  }
                                },
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Simpan',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      // Reload customers and show success message
      final customers = await _databaseHelper.getAllCustomers();
      setState(() {
        _customers = customers;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer berhasil ditambahkan')),
        );
      }
    }
    
    // Dispose controllers after all operations are complete
    namaController.dispose();
    noHpController.dispose();
    alamatController.dispose();
  }

  Future<void> _saveTransaksi() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate detail items
    for (int i = 0; i < _detailItems.length; i++) {
      if (!_detailItems[i].isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item ${i + 1} tidak lengkap')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final subtotal = _calculateSubtotal();
      final dp = NumberUtils.parseFromThousands(_dpController.text) ?? 0;
      final sisa = _calculateSisa();
      
      // Determine status based on user selection and payment
      String status = _selectedStatus;
      // Only auto-update to 'Lunas' if user selected 'Belum Lunas' but payment is complete
      if (_selectedStatus == 'Belum Lunas' && sisa <= 0) {
        status = 'Lunas';
      }
      // If user manually selected 'Lunas', respect their choice even if there's remaining balance

      // Debug log untuk customer yang dipilih
      print('DEBUG: Selected customer: ${_selectedCustomer?.nama} (ID: ${_selectedCustomer?.id})');
      
      // Validasi customer jika dipilih
      if (_selectedCustomer != null) {
        final customerExists = await _databaseHelper.getCustomer(_selectedCustomer!.id!);
        if (customerExists == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Customer yang dipilih tidak valid. Silakan pilih customer lain.')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
        print('DEBUG: Customer validation passed: ${customerExists.nama}');
      }
      
      // Prepare contact data if contact is selected
      String? contactSource;
      String? contactData;
      if (_customerSource == CustomerSource.contact && _selectedContact != null) {
        contactSource = 'contact';
        contactData = jsonEncode(_selectedContact!.toJson());
      } else if (_customerSource == CustomerSource.database && _selectedCustomer != null) {
        contactSource = 'database';
      }
      
      final transaksi = Transaksi(
        transaksiId: widget.transaksiId,
        noInvoice: _noInvoiceController.text.trim(),
        tanggal: _selectedDate,
        customerId: _selectedCustomer?.id,
        subtotal: subtotal,
        dp: dp,
        sisa: sisa,
        status: status,
        metodePembayaran: _metodePembayaranController.text.trim().isEmpty 
            ? null : _metodePembayaranController.text.trim(),
        merkBarang: _merkBarangController.text.trim().isEmpty 
            ? null : _merkBarangController.text.trim(),
        snBarang: _snBarangController.text.trim().isEmpty 
            ? null : _snBarangController.text.trim(),
        namaBarang: _namaBarangController.text.trim().isEmpty 
            ? null : _namaBarangController.text.trim(),
        contactSource: contactSource,
        contactData: contactData,
      );
      
      print('DEBUG: Transaksi object customerId: ${transaksi.customerId}');

      int transaksiId;
      if (widget.transaksiId == null) {
        // Generate fresh invoice number for new transaction to prevent duplicates
        final freshInvoiceNumber = await _databaseHelper.generateInvoiceNumber();
        final freshTransaksi = Transaksi(
          transaksiId: null,
          noInvoice: freshInvoiceNumber,
          tanggal: transaksi.tanggal,
          customerId: transaksi.customerId,
          subtotal: transaksi.subtotal,
          dp: transaksi.dp,
          sisa: transaksi.sisa,
          status: transaksi.status,
          metodePembayaran: transaksi.metodePembayaran,
          merkBarang: transaksi.merkBarang,
          snBarang: transaksi.snBarang,
          namaBarang: transaksi.namaBarang,
          contactSource: transaksi.contactSource,
          contactData: transaksi.contactData,
        );
        
        // Insert new transaction with fresh invoice number
        transaksiId = await _databaseHelper.insertTransaksi(freshTransaksi);
        
        // Update the controller to show the actual saved invoice number
        _noInvoiceController.text = freshInvoiceNumber;
      } else {
        // Update existing transaction
        await _databaseHelper.updateTransaksi(transaksi);
        transaksiId = widget.transaksiId!;
        
        // Delete existing details
        final existingDetails = await _databaseHelper.getTransaksiDetails(transaksiId);
        for (final detail in existingDetails) {
          await _databaseHelper.deleteTransaksiDetail(detail.detailId!);
        }
      }

      // Insert detail items
      for (final item in _detailItems) {
        final detail = TransaksiDetail(
          transaksiId: transaksiId,
          qty: item.qty!,
          deskripsi: item.deskripsi!,
          harga: item.harga!,
          barangId: item.barangId,
          serviceId: item.serviceId,
          namaBarang: item.namaBarang,
          snBarang: item.snBarang,
          garansi: item.garansi,
        );
        await _databaseHelper.insertTransaksiDetail(detail);
      }

      // Generate PDF otomatis untuk semua transaksi (tambah dan edit)
      try {
        // Request storage permission
        await Permission.storage.request();
        
        // Tambahkan delay kecil untuk memastikan data tersimpan dengan benar
        await Future.delayed(const Duration(milliseconds: 200));
        
        final invoice = await _createInvoiceFromTransaksi(transaksiId);
        final pdfFile = await PdfService.generateInvoicePdf(invoice, hideDataBarang: _hideDataBarangInPdf);
        
        if (mounted) {
          final isNewTransaction = widget.transaksiId == null;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isNewTransaction 
                  ? 'Transaksi berhasil ditambahkan dan PDF telah dibuat'
                  : 'Transaksi berhasil diupdate dan PDF telah dibuat'),
              action: SnackBarAction(
                label: 'Buka PDF',
                onPressed: () {
                  OpenFile.open(pdfFile.path);
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final isNewTransaction = widget.transaksiId == null;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isNewTransaction
                ? 'Transaksi berhasil ditambahkan, tapi gagal membuat PDF: $e'
                : 'Transaksi berhasil diupdate, tapi gagal membuat PDF: $e')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving transaksi: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateInvoiceForDate(DateTime date) async {
    try {
      final newInvoiceNumber = await _databaseHelper.generateInvoiceNumberForDate(date);
      if (mounted) {
        setState(() {
          _noInvoiceController.text = newInvoiceNumber;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating invoice number: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _noInvoiceController.dispose();
    _dpController.dispose();
    _metodePembayaranController.dispose();
    _merkBarangController.dispose();
    _snBarangController.dispose();
    _namaBarangController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.transaksiId == null ? 'Transaksi Baru' : 'Edit Transaksi',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Add Customer Icon
          IconButton(
            onPressed: _showAddCustomerDialog,
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Tambah Customer',
          ),
          if (widget.transaksiId != null) ...[
            // Share PDF Icon
            IconButton(
              onPressed: _sharePdf,
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share PDF',
            ),
            // Generate PDF Icon
            IconButton(
              onPressed: _generatePdf,
              icon: const Icon(Icons.print),
              tooltip: 'Generate PDF',
            ),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice Number
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _noInvoiceController,
                    decoration: InputDecoration(
                      labelText: 'No. Invoice',
                      border: InputBorder.none,
                      labelStyle: TextStyle(color: colorScheme.primary),
                      prefixIcon: Icon(
                        Icons.receipt_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'No. Invoice harus diisi';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Date
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                      
                      // Generate new invoice number based on selected date
                      // Only if this is a new transaction (not editing existing one)
                      if (widget.transaksiId == null) {
                        _generateInvoiceForDate(date);
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tanggal',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Customer Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer (opsional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Customer Source Toggle
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectCustomerSource(CustomerSource.database),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: _customerSource == CustomerSource.database 
                                    ? colorScheme.primary 
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.storage,
                                    size: 18,
                                    color: _customerSource == CustomerSource.database 
                                        ? colorScheme.onPrimary 
                                        : colorScheme.onSurface,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Database',
                                    style: TextStyle(
                                      color: _customerSource == CustomerSource.database 
                                          ? colorScheme.onPrimary 
                                          : colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectCustomerSource(CustomerSource.contact),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: _customerSource == CustomerSource.contact 
                                    ? colorScheme.primary 
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.contacts,
                                    size: 18,
                                    color: _customerSource == CustomerSource.contact 
                                        ? colorScheme.onPrimary 
                                        : colorScheme.onSurface,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Kontak HP',
                                    style: TextStyle(
                                      color: _customerSource == CustomerSource.contact 
                                          ? colorScheme.onPrimary 
                                          : colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
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
                  const SizedBox(height: 12),
                  // Customer Selection Content
                  if (_customerSource == CustomerSource.database) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: DropdownButtonFormField<Customer>(
                                value: _selectedCustomer,
                                decoration: InputDecoration(
                                  labelText: 'Pilih Customer',
                                  border: InputBorder.none,
                                  labelStyle: TextStyle(color: colorScheme.primary),
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<Customer>(
                                    key: ValueKey('null_customer'),
                                    value: null,
                                    child: Text('Pilih Customer'),
                                  ),
                                  ..._customers.toSet().map((customer) => DropdownMenuItem<Customer>(
                                    key: ValueKey('customer_${customer.id}'),
                                    value: customer,
                                    child: Text('${customer.nama} - ${customer.noHp}'),
                                  )),
                                ],
                                onChanged: (customer) {
                                  setState(() {
                                    _selectedCustomer = customer;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _showAddCustomerDialog,
                            icon: Icon(
                              Icons.add,
                              color: colorScheme.onPrimary,
                              size: 24,
                            ),
                            tooltip: 'Tambah Customer Baru',
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Contact Picker
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                      ),
                      child: InkWell(
                        onTap: _pickContact,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.contacts,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedContact != null 
                                          ? _selectedContact!.name 
                                          : 'Pilih dari Kontak HP',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: _selectedContact != null 
                                            ? colorScheme.onSurface 
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (_selectedContact != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedContact!.phoneNumber,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: colorScheme.onSurfaceVariant,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              
              // Checkbox untuk menyembunyikan data barang di PDF
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      'Sembunyikan Data Barang di PDF',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Centang untuk menyembunyikan bagian data barang saat generate PDF',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    value: _hideDataBarangInPdf,
                    onChanged: (bool? value) {
                      setState(() {
                        _hideDataBarangInPdf = value ?? false;
                      });
                    },
                    activeColor: colorScheme.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Data Barang Section - Conditional visibility based on checkbox
              if (!_hideDataBarangInPdf) ...[
                // Data Barang Section
                Text(
                  'Data Barang',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Nama Barang
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextFormField(
                      controller: _namaBarangController,
                      decoration: InputDecoration(
                        labelText: 'Nama Barang',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                        labelStyle: TextStyle(color: colorScheme.primary),
                        prefixIcon: Icon(
                          Icons.inventory_2_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                // Merk Barang
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextFormField(
                      controller: _merkBarangController,
                      decoration: InputDecoration(
                        labelText: 'Merk',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                        labelStyle: TextStyle(color: colorScheme.primary),
                        prefixIcon: Icon(
                          Icons.branding_watermark_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                // SN Barang
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextFormField(
                      controller: _snBarangController,
                      decoration: InputDecoration(
                        labelText: 'SN (Serial Number)',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                        labelStyle: TextStyle(color: colorScheme.primary),
                        prefixIcon: Icon(
                          Icons.confirmation_number_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
              
              // Detail Items Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Transaksi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _addDetailItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Item'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Detail Items List
              ..._detailItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Item ${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimaryContainer,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (_detailItems.length > 1)
                              IconButton(
                                onPressed: () => _removeDetailItem(index),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: colorScheme.error,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: colorScheme.error.withValues(alpha: 0.1),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Field Nama Barang (paling atas, jika checkbox dicentang)
                        if (_hideDataBarangInPdf) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              initialValue: item.namaBarang ?? _namaBarangController.text,
                              decoration: InputDecoration(
                                labelText: 'Nama Barang',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                                labelStyle: TextStyle(color: colorScheme.primary),
                              ),
                              onChanged: (value) {
                                item.namaBarang = value.isEmpty ? null : value;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Baris pertama: Qty dan Sumber Deskripsi
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextFormField(
                                  initialValue: item.qty?.toString() ?? '',
                                  decoration: InputDecoration(
                                    labelText: 'Qty',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                    labelStyle: TextStyle(color: colorScheme.primary),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  onChanged: (value) {
                                    item.qty = int.tryParse(value);
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonFormField<DeskripsiSource>(
                                  value: item.deskripsiSource,
                                  decoration: InputDecoration(
                                    labelText: 'Sumber Deskripsi',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                    labelStyle: TextStyle(color: colorScheme.primary),
                                  ),
                                  items: DeskripsiSource.values.map((source) {
                                    return DropdownMenuItem(
                                      value: source,
                                      child: Text(source.displayName),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        item.deskripsiSource = value;
                                        item.clearSelection();
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Baris kedua: Field deskripsi dan Harga
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           // Field deskripsi berdasarkan pilihan
                           if (item.deskripsiSource == DeskripsiSource.ketikBebas) ...[
                             Container(
                               decoration: BoxDecoration(
                                 color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                 borderRadius: BorderRadius.circular(12),
                               ),
                               child: TextFormField(
                                 initialValue: item.deskripsi ?? '',
                                 decoration: InputDecoration(
                                   labelText: 'Deskripsi',
                                   border: InputBorder.none,
                                   contentPadding: const EdgeInsets.all(16),
                                   labelStyle: TextStyle(color: colorScheme.primary),
                                 ),
                                 maxLines: 1,
                                 onChanged: (value) {
                                   item.deskripsi = value.isEmpty ? null : value;
                                 },
                               ),
                             ),
                           ] else if (item.deskripsiSource == DeskripsiSource.dariBarang) ...[
                             Container(
                               decoration: BoxDecoration(
                                 color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                 borderRadius: BorderRadius.circular(12),
                               ),
                               child: DropdownButtonFormField<Barang>(
                                 value: item.selectedBarang,
                                 decoration: InputDecoration(
                                   labelText: 'Pilih Barang',
                                   border: InputBorder.none,
                                   contentPadding: const EdgeInsets.all(16),
                                   labelStyle: TextStyle(color: colorScheme.primary),
                                 ),
                                 items: _barangList.map((barang) {
                                   return DropdownMenuItem(
                                     value: barang,
                                     child: Text('Barang ID: ${barang.id}'),
                                   );
                                 }).toList(),
                                 onChanged: (value) {
                                   if (value != null) {
                                     setState(() {
                                       item.updateFromBarang(value);
                                     });
                                   }
                                 },
                               ),
                             ),
                           ] else if (item.deskripsiSource == DeskripsiSource.dariService) ...[
                             Container(
                               decoration: BoxDecoration(
                                 color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                 borderRadius: BorderRadius.circular(12),
                               ),
                               child: DropdownButtonFormField<Service>(
                                 value: item.selectedService,
                                 decoration: InputDecoration(
                                   labelText: 'Pilih Service',
                                   border: InputBorder.none,
                                   contentPadding: const EdgeInsets.all(16),
                                   labelStyle: TextStyle(color: colorScheme.primary),
                                 ),
                                 items: _serviceList.map((service) {
                                   return DropdownMenuItem(
                                     value: service,
                                     child: Text(service.jenisKerusakan.join(', ')),
                                   );
                                 }).toList(),
                                 onChanged: (value) {
                                   if (value != null) {
                                     setState(() {
                                       item.updateFromService(value);
                                     });
                                   }
                                 },
                               ),
                             ),
                           ],
                         ],
                       ),
                           
                     SizedBox(height: 16),
                        Row(
                          children: [
                               Expanded(
                                flex: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextFormField(
                                    initialValue: item.garansi ?? '',
                                    decoration: InputDecoration(
                                      labelText: 'Garansi',
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(16),
                                      labelStyle: TextStyle(color: colorScheme.primary),
                                    ),
                                    maxLines: 1,
                                    onChanged: (value) {
                                      item.garansi = value.isEmpty ? null : value;
                                    },
                                  ),
                                ),
                              ),
                             
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextFormField(
                                  initialValue: NumberUtils.formatToThousands(item.harga),
                                  decoration: InputDecoration(
                                    labelText: 'Harga',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                    prefixText: 'Rp ',
                                    labelStyle: TextStyle(color: colorScheme.primary),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                                  onChanged: (value) {
                                    item.harga = NumberUtils.parseFromThousands(value);
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Additional fields when checkbox is checked
                        if (_hideDataBarangInPdf) ...[
                          const SizedBox(height: 16),
                          // Field SN (Serial Number) - baris terpisah
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              initialValue: item.snBarang ?? _snBarangController.text,
                              decoration: InputDecoration(
                                labelText: 'SN (Serial Number)',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                                labelStyle: TextStyle(color: colorScheme.primary),
                              ),
                              maxLines: 1,
                              onChanged: (value) {
                                item.snBarang = value.isEmpty ? null : value;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // // Field Garansi dan Harga Garansi dalam satu baris
                          // Row(
                          //   children: [
                         
                          //     const SizedBox(width: 16),
                          //     Expanded(
                          //       flex: 1,
                          //       child: Container(
                          //         decoration: BoxDecoration(
                          //           color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          //           borderRadius: BorderRadius.circular(12),
                          //         ),
                          //         child: TextFormField(
                          //           initialValue: NumberUtils.formatToThousands(item.hargaGaransi),
                          //           decoration: InputDecoration(
                          //             labelText: 'Harga Garansi',
                          //             border: InputBorder.none,
                          //             contentPadding: const EdgeInsets.all(16),
                          //             prefixText: 'Rp ',
                          //             labelStyle: TextStyle(color: colorScheme.primary),
                          //           ),
                          //           keyboardType: TextInputType.number,
                          //           inputFormatters: [ThousandsSeparatorInputFormatter()],
                          //           maxLines: 1,
                          //           onChanged: (value) {
                          //             item.hargaGaransi = NumberUtils.parseFromThousands(value);
                          //           },
                          //         ),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                       
                        ],
                        if (item.qty != null && item.harga != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Item:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  'Rp ${NumberUtils.formatToThousands(item.totalHarga)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
              
              // Subtotal
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.primaryContainer.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'Rp ${NumberUtils.formatToThousands(_calculateSubtotal())}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // DP
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextFormField(
                    controller: _dpController,
                    decoration: InputDecoration(
                      labelText: 'DP (Down Payment)',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                      prefixText: 'Rp ',
                      labelStyle: TextStyle(color: colorScheme.primary),
                      prefixIcon: Icon(
                        Icons.payments_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    onChanged: (value) {
                      setState(() {}); // Refresh to update sisa calculation
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Sisa
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.tertiaryContainer,
                        colorScheme.tertiaryContainer.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sisa:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Rp ${NumberUtils.formatToThousands(_calculateSisa())}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Status
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                      labelStyle: TextStyle(color: colorScheme.primary),
                      prefixIcon: Icon(
                        Icons.flag_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Belum Lunas', child: Text('Belum Lunas')),
                      DropdownMenuItem(value: 'Lunas', child: Text('Lunas')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Metode Pembayaran
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextFormField(
                    controller: _metodePembayaranController,
                    decoration: InputDecoration(
                      labelText: 'Metode Pembayaran (opsional)',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                      labelStyle: TextStyle(color: colorScheme.primary),
                      prefixIcon: Icon(
                        Icons.credit_card_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              const SizedBox(height: 24),
              
              // Save Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTransaksi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: colorScheme.onPrimary,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: colorScheme.onPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.transaksiId == null 
                                  ? Icons.save_outlined 
                                  : Icons.update_outlined,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.transaksiId == null ? 'Simpan Transaksi' : 'Update Transaksi',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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

enum DeskripsiSource {
  ketikBebas('Ketik Bebas'),
  dariBarang('Dari Barang'),
  dariService('Dari Service');

  const DeskripsiSource(this.displayName);
  final String displayName;
}

class TransaksiDetailItem {
  int? qty;
  String? deskripsi;
  double? harga;
  int? barangId;
  int? serviceId;
  DeskripsiSource deskripsiSource;
  Barang? selectedBarang;
  Service? selectedService;
  String? namaBarang; // nama barang untuk detail item
  String? snBarang; // serial number barang
  String? garansi; // garansi barang
  double? hargaGaransi; // harga garansi

  TransaksiDetailItem({
    this.qty,
    this.deskripsi,
    this.harga,
    this.barangId,
    this.serviceId,
    this.deskripsiSource = DeskripsiSource.ketikBebas,
    this.selectedBarang,
    this.selectedService,
    this.namaBarang,
    this.snBarang,
    this.garansi,
    this.hargaGaransi,
  });

  bool get isValid => qty != null && qty! > 0 && deskripsi != null && deskripsi!.isNotEmpty && harga != null && harga! > 0;
  
  double get totalHarga => (qty ?? 0) * (harga ?? 0);

  void updateFromBarang(Barang barang) {
    selectedBarang = barang;
    barangId = barang.id;
    serviceId = null;
    selectedService = null;
    deskripsi = 'Barang ID: ${barang.id}';
  }

  void updateFromService(Service service) {
    selectedService = service;
    serviceId = service.id;
    barangId = null;
    selectedBarang = null;
    deskripsi = service.jenisKerusakan.join(', ');
  }

  void clearSelection() {
    selectedBarang = null;
    selectedService = null;
    barangId = null;
    serviceId = null;
    if (deskripsiSource == DeskripsiSource.ketikBebas) {
      deskripsi = null;
    }
  }
}