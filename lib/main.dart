import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/invoice_model.dart';
import 'services/pdf_service.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale data for Indonesian locale
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nota Digital - Manajemen Service',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7CB342)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class InvoiceGeneratorPage extends StatefulWidget {
  const InvoiceGeneratorPage({super.key});

  @override
  State<InvoiceGeneratorPage> createState() => _InvoiceGeneratorPageState();
}

class _InvoiceGeneratorPageState extends State<InvoiceGeneratorPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers untuk form
  final _invoiceNumberController = TextEditingController(text: 'INV-001');
  final _clientNameController = TextEditingController(text: 'PT. Maju Jaya');
  final _clientAddressController = TextEditingController(
    text: 'Jl. Sudirman No. 123\nJakarta Pusat 10220',
  );

  List<InvoiceItem> _items = [
    InvoiceItem(
      description: 'Web Development Service',
      quantity: 1,
      unitPrice: 2500.00,
    ),
    InvoiceItem(
      description: 'Mobile App Development',
      quantity: 1,
      unitPrice: 3500.00,
    ),
    InvoiceItem(description: 'UI/UX Design', quantity: 2, unitPrice: 800.00),
    InvoiceItem(
      description: 'Database Setup & Configuration',
      quantity: 1,
      unitPrice: 1200.00,
    ),
  ];

  bool _isGenerating = false;

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _clientNameController.dispose();
    _clientAddressController.dispose();
    super.dispose();
  }

  Future<void> _generatePdf() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      // Request storage permission
      await Permission.storage.request();

      // Create invoice object
      final invoice = Invoice(
        invoiceNumber: _invoiceNumberController.text,
        date: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 30)),
        company: CompanyInfo(
          name: 'PT. Codeko Digital Solutions',
          address: 'Jl. Teknologi No. 45\nBandung 40132, Indonesia',
          phone: '+62 22 1234 5678',
          email: 'info@codeko.co.id',
          website: 'www.codeko.co.id',
        ),
        client: ClientInfo(
          name: _clientNameController.text,
          address: _clientAddressController.text,
          phone: null, // Tidak ada nomor HP di form demo
        ),
        items: _items,
        taxRate: 10.0,
      );

      // Generate PDF
      final file = await PdfService.generateInvoicePdf(invoice);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF berhasil dibuat: ${file.path}'),
            action: SnackBarAction(
              label: 'Buka',
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Generator'),
        backgroundColor: const Color(0xFF7CB342),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Invoice',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _invoiceNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Invoice',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nomor invoice harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _clientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Klien',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama klien harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _clientAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Alamat Klien',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Alamat klien harus diisi';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Items Preview
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview Items',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),

                      // Table Header
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E2E2E),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                'QTY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'DESCRIPTION',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'UNIT PRICE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'AMOUNT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Table Items
                      ..._items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final isEven = index % 2 == 0;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                isEven ? const Color(0xFFF5F5F5) : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(item.quantity.toString()),
                              ),
                              Expanded(flex: 3, child: Text(item.description)),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '\$${item.unitPrice.toStringAsFixed(2)}',
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '\$${item.amount.toStringAsFixed(2)}',
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      // Totals
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text('Subtotal: '),
                                Text(
                                  '\$${_items.fold(0.0, (sum, item) => sum + item.amount).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text('Tax (10%): '),
                                Text(
                                  '\$${(_items.fold(0.0, (sum, item) => sum + item.amount) * 0.1).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7CB342),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'TOTAL: ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '\$${(_items.fold(0.0, (sum, item) => sum + item.amount) * 1.1).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
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

              // Generate Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generatePdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7CB342),
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isGenerating
                          ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Generating PDF...'),
                            ],
                          )
                          : const Text(
                            'Generate PDF Invoice',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
