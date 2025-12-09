import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/invoice_model.dart';
import '../models/barang_model.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PdfService {
  // Format mata uang rupiah
  static String formatRupiah(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Generate Barang Report PDF
  static Future<File> generateBarangReportPdf(List<Barang> barangList) async {
    final pdf = pw.Document();

    // Warna sesuai desain
    final greenColor = PdfColor.fromHex('#7CB342');
    final darkColor = PdfColor.fromHex('#2E2E2E');
    final lightGray = PdfColor.fromHex('#F5F5F5');

    // Load logo image
    Uint8List? logoImageBytes;
    try {
      final ByteData logoData = await rootBundle.load('assets/img/logo.png');
      logoImageBytes = logoData.buffer.asUint8List();
    } catch (e) {
      // Error loading logo image
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildBarangReportHeader(greenColor, darkColor, logoImageBytes),
              pw.SizedBox(height: 30),

              // Summary Section
              _buildBarangSummary(barangList, greenColor, darkColor),
              pw.SizedBox(height: 20),

              // Table Section
              _buildBarangTable(barangList, greenColor, darkColor, lightGray),

              pw.Spacer(),

              // Footer Section
              _buildBarangReportFooter(greenColor, darkColor),
            ],
          );
        },
      ),
    );

    // Save PDF
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/laporan_barang_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static pw.Widget _buildBarangReportHeader(
    PdfColor greenColor,
    PdfColor darkColor,
    Uint8List? logoImageBytes,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'LAPORAN DATA BARANG',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: darkColor,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Lentera Komputer',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: greenColor,
              ),
            ),
            pw.Text(
              'Tanggal: ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 12, color: darkColor),
            ),
          ],
        ),
        if (logoImageBytes != null)
          pw.Container(
            width: 80,
            height: 80,
            child: pw.Image(
              pw.MemoryImage(logoImageBytes),
              fit: pw.BoxFit.contain,
            ),
          ),
      ],
    );
  }

  static pw.Widget _buildBarangSummary(
    List<Barang> barangList,
    PdfColor greenColor,
    PdfColor darkColor,
  ) {
    final totalBarang = barangList.length;
    final totalStok = barangList.fold<int>(
      0,
      (sum, item) => sum + (item.stok ?? 0),
    );
    final totalKeluar = barangList.fold<int>(
      0,
      (sum, item) => sum + (item.keluar ?? 0),
    );
    final totalSisa = barangList.fold<int>(
      0,
      (sum, item) => sum + item.sisaStok,
    );

    final lightGray = PdfColor.fromHex('#F5F5F5');

    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Total Jenis Barang',
            totalBarang.toString(),
            greenColor,
            darkColor,
          ),
          _buildSummaryItem(
            'Total Stok',
            totalStok.toString(),
            greenColor,
            darkColor,
          ),
          _buildSummaryItem(
            'Total Keluar',
            totalKeluar.toString(),
            greenColor,
            darkColor,
          ),
          _buildSummaryItem(
            'Sisa Stok',
            totalSisa.toString(),
            greenColor,
            darkColor,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(
    String label,
    String value,
    PdfColor greenColor,
    PdfColor darkColor,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: greenColor,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: darkColor)),
      ],
    );
  }

  static pw.Widget _buildBarangTable(
    List<Barang> barangList,
    PdfColor greenColor,
    PdfColor darkColor,
    PdfColor lightGray,
  ) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          // Table Header
          pw.Container(
            padding: pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: greenColor,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'No',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'Barang ID',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'Supplier',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'Stok',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'Keluar',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'Sisa',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Body
          pw.Expanded(
            child: pw.ListView.builder(
              itemCount: barangList.length,
              itemBuilder: (context, index) {
                final barang = barangList[index];
                final isEven = index % 2 == 0;

                return pw.Container(
                  padding: pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: isEven ? lightGray : PdfColors.white,
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          '${index + 1}',
                          style: pw.TextStyle(fontSize: 9, color: darkColor),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          '${barang.id}',
                          style: pw.TextStyle(fontSize: 9, color: darkColor),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          barang.supplier ?? '-',
                          style: pw.TextStyle(fontSize: 9, color: darkColor),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          '${barang.stok ?? 0}',
                          style: pw.TextStyle(fontSize: 9, color: darkColor),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          '${barang.keluar ?? 0}',
                          style: pw.TextStyle(fontSize: 9, color: darkColor),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          '${barang.sisaStok}',
                          style: pw.TextStyle(fontSize: 9, color: darkColor),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBarangReportFooter(
    PdfColor greenColor,
    PdfColor darkColor,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Lentera Komputer',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: darkColor,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'WhatsApp: 0821-1712-3434',
              style: pw.TextStyle(fontSize: 8, color: darkColor),
            ),
            pw.Text(
              'Email: lenteracomp.bdg@gmail.com',
              style: pw.TextStyle(fontSize: 8, color: darkColor),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SizedBox(height: 40),
            pw.Text(
              'Diki Wahyu Diardi',
              style: pw.TextStyle(fontSize: 8, color: darkColor),
            ),
          ],
        ),
      ],
    );
  }

  static Future<File> generateInvoicePdf(
    Invoice invoice, {
    bool hideDataBarang = false,
  }) async {
    final pdf = pw.Document();

    // Warna sesuai desain
    final greenColor = PdfColor.fromHex('#7CB342');
    final darkColor = PdfColor.fromHex('#2E2E2E');
    final lightGray = PdfColor.fromHex('#F5F5F5');

    // Load footer image
    Uint8List? footerImageBytes;
    try {
      final ByteData data = await rootBundle.load('assets/img/footer.png');
      footerImageBytes = data.buffer.asUint8List();
    } catch (e) {
      // Error loading footer image
    }

    // Load logo image
    Uint8List? logoImageBytes;
    try {
      final ByteData logoData = await rootBundle.load('assets/img/logo.png');
      logoImageBytes = logoData.buffer.asUint8List();
    } catch (e) {
      // Error loading logo image
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(invoice, greenColor, darkColor, logoImageBytes),
              pw.SizedBox(height: 30),

              // Invoice Info Section
              _buildInvoiceInfo(invoice, greenColor, darkColor),
              pw.SizedBox(height: 20),

              // Data Barang Section (if available and not hidden)
              if (!hideDataBarang &&
                  (invoice.merkBarang != null ||
                      invoice.snBarang != null ||
                      invoice.namaBarang != null))
                _buildDataBarangSection(invoice, greenColor, darkColor),
              if (!hideDataBarang &&
                  (invoice.merkBarang != null ||
                      invoice.snBarang != null ||
                      invoice.namaBarang != null))
                pw.SizedBox(height: 20),

              // Table Section
              _buildItemsTable(
                invoice,
                greenColor,
                darkColor,
                lightGray,
                hideDataBarang,
              ),
              pw.SizedBox(height: 20),

              // Footer Section
              _buildFooter(invoice, greenColor, darkColor),

              pw.Spacer(),

              // Bottom Section
              _buildBottomSection(
                invoice,
                greenColor,
                darkColor,
                logoImageBytes,
              ),

              pw.SizedBox(height: 20),

              // Footer image
              _buildFooterImage(footerImageBytes),
            ],
          );
        },
      ),
    );

    // Save PDF
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/invoice_${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static pw.Widget _buildHeader(
    Invoice invoice,
    PdfColor greenColor,
    PdfColor darkColor,
    Uint8List? logoImageBytes,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo dan Company Info
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo Company
            pw.Container(
              width: 120,
              height: 60,
              child:
                  logoImageBytes != null
                      ? pw.Image(pw.MemoryImage(logoImageBytes))
                      : pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: pw.BoxDecoration(
                          color: greenColor,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'LENTERA KOMPUTER',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
            ),
          ],
        ),

        // Invoice Title
        pw.Container(
          padding: pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: pw.BoxDecoration(
            color: greenColor,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'INVOICE',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceInfo(
    Invoice invoice,
    PdfColor greenColor,
    PdfColor darkColor,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // INV To
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'INV TO:',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: darkColor,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              invoice.client.name,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: darkColor,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              invoice.client.phone ?? 'Nomor tidak tersedia',
              style: pw.TextStyle(fontSize: 10, color: darkColor),
            ),
          ],
        ),

        // Invoice Details
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Invoice: ${invoice.invoiceNumber}',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: darkColor,
              ),
            ),
            pw.SizedBox(height: 4),
            // pw.Text(
            //   'Issue Date: ${invoice.date.day}/${invoice.date.month}/${invoice.date.year}',
            //   style: pw.TextStyle(fontSize: 10, color: darkColor),
            // ),
            // pw.SizedBox(height: 4),
            // pw.Text(
            //   'Due Date: ${invoice.dueDate.day}/${invoice.dueDate.month}/${invoice.dueDate.year}',
            //   style: pw.TextStyle(fontSize: 10, color: darkColor),
            // ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildDataBarangSection(
    Invoice invoice,
    PdfColor greenColor,
    PdfColor darkColor,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DATA BARANG',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: greenColor,
            ),
          ),
          pw.SizedBox(height: 8),
          // Single row for all barang information
          pw.Row(
            children: [
              // Nama Barang
              if (invoice.namaBarang != null)
                pw.Expanded(
                  flex: 2,
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: 'Nama Barang: ',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: darkColor,
                          ),
                        ),
                        pw.TextSpan(
                          text: invoice.namaBarang!,
                          style: pw.TextStyle(fontSize: 10, color: darkColor),
                        ),
                      ],
                    ),
                  ),
                ),
              if (invoice.namaBarang != null &&
                  (invoice.merkBarang != null || invoice.snBarang != null))
                pw.SizedBox(width: 16),
              // Merk
              if (invoice.merkBarang != null)
                pw.Expanded(
                  flex: 1,
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: 'Merk: ',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: darkColor,
                          ),
                        ),
                        pw.TextSpan(
                          text: invoice.merkBarang!,
                          style: pw.TextStyle(fontSize: 10, color: darkColor),
                        ),
                      ],
                    ),
                  ),
                ),
              if (invoice.merkBarang != null && invoice.snBarang != null)
                pw.SizedBox(width: 16),
              // Serial Number
              if (invoice.snBarang != null)
                pw.Expanded(
                  flex: 1,
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: 'SN: ',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: darkColor,
                          ),
                        ),
                        pw.TextSpan(
                          text: invoice.snBarang!,
                          style: pw.TextStyle(fontSize: 10, color: darkColor),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(
    Invoice invoice,
    PdfColor greenColor,
    PdfColor darkColor,
    PdfColor lightGray,
    bool hideDataBarang,
  ) {
    // Define column widths based on whether data barang is hidden or not
    List<double> columnWidths;
    if (hideDataBarang) {
      // QTY, NAMA BARANG, DESCRIPTION, SN, GARANSI, HARGA, TOTAL
      columnWidths = [40, 80, 120, 80, 60, 80, 80]; // Total: 540
    } else {
      // QTY, DESCRIPTION, HARGA, TOTAL
      columnWidths = [50, 280, 100, 100]; // Total: 530
    }

    List<pw.TableRow> rows = [
      // Header
      pw.TableRow(
        decoration: pw.BoxDecoration(color: darkColor),
        children: [
          _buildTableCellWithWidth('QTY', columnWidths[0], isHeader: true),
          if (hideDataBarang) ...[
            _buildTableCellWithWidth('NAMA BARANG', columnWidths[1], isHeader: true),
            _buildTableCellWithWidth('DESCRIPTION', columnWidths[2], isHeader: true),
            _buildTableCellWithWidth('SN', columnWidths[3], isHeader: true),
            _buildTableCellWithWidth('GARANSI', columnWidths[4], isHeader: true),
            _buildTableCellWithWidth('HARGA', columnWidths[5], isHeader: true),
            _buildTableCellWithWidth('TOTAL', columnWidths[6], isHeader: true),
          ] else ...[
            _buildTableCellWithWidth('DESCRIPTION', columnWidths[1], isHeader: true),
            _buildTableCellWithWidth('HARGA', columnWidths[2], isHeader: true),
            _buildTableCellWithWidth('TOTAL', columnWidths[3], isHeader: true),
          ],
        ],
      ),
    ];

    // Add dynamic items from invoice
    for (int i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final isEven = i % 2 == 0;

      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: isEven ? PdfColors.white : lightGray,
          ),
          children: [
            _buildTableCellWithWidth(item.quantity.toString(), columnWidths[0]),
            if (hideDataBarang) ...[
              _buildTableCellWithWidth(item.namaBarang ?? '-', columnWidths[1]),
              _buildTableCellWithWidth(item.description, columnWidths[2]),
              _buildTableCellWithWidth(item.snBarang ?? '-', columnWidths[3]),
              _buildTableCellWithWidth(item.garansi ?? '-', columnWidths[4]),
              _buildTableCellWithWidth(formatRupiah(item.unitPrice), columnWidths[5]),
              _buildTableCellWithWidth(formatRupiah(item.amount), columnWidths[6]),
            ] else ...[
              _buildTableCellWithWidth(item.description, columnWidths[1]),
              _buildTableCellWithWidth(formatRupiah(item.unitPrice), columnWidths[2]),
              _buildTableCellWithWidth(formatRupiah(item.amount), columnWidths[3]),
            ],
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: hideDataBarang 
        ? {
            0: pw.FixedColumnWidth(columnWidths[0]),
            1: pw.FixedColumnWidth(columnWidths[1]),
            2: pw.FixedColumnWidth(columnWidths[2]),
            3: pw.FixedColumnWidth(columnWidths[3]),
            4: pw.FixedColumnWidth(columnWidths[4]),
            5: pw.FixedColumnWidth(columnWidths[5]),
            6: pw.FixedColumnWidth(columnWidths[6]),
          }
        : {
            0: pw.FixedColumnWidth(columnWidths[0]),
            1: pw.FixedColumnWidth(columnWidths[1]),
            2: pw.FixedColumnWidth(columnWidths[2]),
            3: pw.FixedColumnWidth(columnWidths[3]),
          },
      children: rows,
    );
  }

  static pw.Widget _buildTableCellWithWidth(String text, double width, {bool isHeader = false}) {
    return pw.Container(
      width: width,
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
        maxLines: null, // Allow multiple lines
        overflow: pw.TextOverflow.visible, // Show all text
      ),
    );
  }

  static pw.Widget _buildFooter(
    Invoice invoice,
    PdfColor greenColor,
    PdfColor darkColor,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _buildTotalRow(
              'Subtotal',
              formatRupiah(invoice.subtotal),
              darkColor,
            ),
            pw.SizedBox(height: 4),
            // _buildTotalRow('Tax (${invoice.taxRate.toStringAsFixed(0)}%)', formatRupiah(invoice.taxAmount), darkColor),
            // pw.SizedBox(height: 8),
            // Tampilkan DP hanya jika ada nilainya
            if (invoice.hasDP) ...[
              pw.SizedBox(height: 4),
              _buildTotalRow('DP', formatRupiah(invoice.dpAmount!), darkColor),
            ],
            pw.SizedBox(height: 8),
            pw.Container(
              padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: greenColor,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'TOTAL ',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Text(
                    formatRupiah(invoice.sisaAmount),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Tambahan informasi DP dan Sisa jika ada DP
            // if (invoice.hasDP) ...[

            //   pw.SizedBox(height: 4),
            //   _buildTotalRow('Sisa Pembayaran', formatRupiah(invoice.sisaAmount), darkColor),
            // ],
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    String amount,
    PdfColor darkColor,
  ) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 80,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, color: darkColor),
            textAlign: pw.TextAlign.right,
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Container(
          width: 60,
          child: pw.Text(
            amount,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: darkColor,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooterImage(Uint8List? footerImageBytes) {
    if (footerImageBytes != null) {
      return pw.Container(
        width: double.infinity,
        height: 60,
        child: pw.Image(
          pw.MemoryImage(footerImageBytes),
          fit: pw.BoxFit.fitWidth,
          alignment: pw.Alignment.centerRight,
        ),
      );
    } else {
      // Fallback if image loading fails
      return pw.Container(
        width: double.infinity,
        height: 60,
        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#7CB342')),
        child: pw.Center(
          child: pw.Text(
            'Footer Image',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  static pw.Widget _buildBottomSection(
    Invoice invoice,
    PdfColor greenColor,
    PdfColor darkColor,
    Uint8List? logoImageBytes,
  ) {
    return pw.Column(
      children: [
        // Payment Information Section
        pw.Row(
          children: [
            // Payment Method Section
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Payment Method',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Metode: ${invoice.paymentMethod}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: darkColor,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Please transfer payment to the following account:',
                    style: pw.TextStyle(fontSize: 10, color: darkColor),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'BCA : 337-002-1201',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: darkColor,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            // Payment Status Section
            // pw.Column(
            //   crossAxisAlignment: pw.CrossAxisAlignment.end,
            //   children: [
            //     pw.Text(
            //       'Payment Status',
            //       style: pw.TextStyle(
            //         fontSize: 12,
            //         fontWeight: pw.FontWeight.bold,
            //         color: darkColor,
            //       ),
            //     ),
            //     pw.SizedBox(height: 8),
            //     pw.Container(
            //       padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            //       decoration: pw.BoxDecoration(
            //         color: _getStatusColor(invoice.paymentStatus),
            //         borderRadius: pw.BorderRadius.circular(4),
            //       ),
            //       child: pw.Text(
            //         invoice.paymentStatus,
            //         style: pw.TextStyle(
            //           fontSize: 10,
            //           fontWeight: pw.FontWeight.bold,
            //           color: PdfColors.white,
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
        pw.SizedBox(height: 20),

        // Terms & Conditions and Signature
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Terms & Conditions
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Terima Kasih',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: darkColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Terima kasih atas kepercayaan Anda telah bertransaksi dengan kami.',
                  style: pw.TextStyle(fontSize: 8, color: darkColor),
                ),
                pw.Text(
                  'Kami berharap dapat terus memberikan pelayanan terbaik untuk Anda.',
                  style: pw.TextStyle(fontSize: 8, color: darkColor),
                ),

                // pw.SizedBox(height: 8),
                // pw.Text(
                //   invoice.company.address,
                //   style: pw.TextStyle(fontSize: 8, color: darkColor),
                // ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Container(
                      width: 12,
                      height: 12,
                      decoration: pw.BoxDecoration(
                        color: greenColor,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      'WhatsApp: 0821-1712-3434',
                      style: pw.TextStyle(fontSize: 8, color: darkColor),
                    ),
                  ],
                ),
                // pw.SizedBox(height: 4),
                // pw.Row(
                //   children: [
                //     pw.Container(
                //       width: 12,
                //       height: 12,
                //       decoration: pw.BoxDecoration(
                //         color: greenColor,
                //         shape: pw.BoxShape.circle,
                //       ),
                //     ),
                //     pw.SizedBox(width: 4),
                //     pw.Text(
                //       invoice.company.website,
                //       style: pw.TextStyle(fontSize: 8, color: darkColor),
                //     ),
                //   ],
                // ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Container(
                      width: 12,
                      height: 12,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      'Email: lenteracomp.bdg@gmail.com',
                      style: pw.TextStyle(fontSize: 8, color: darkColor),
                    ),
                  ],
                ),
              ],
            ),

            // Signature Area
            pw.Container(
              margin: pw.EdgeInsets.only(right: 50),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // pw.Container(
                  //   width: 80,
                  //   height: 40,
                  //   child: logoImageBytes != null
                  //       ? pw.Image(
                  //           pw.MemoryImage(logoImageBytes),
                  //           fit: pw.BoxFit.contain,
                  //         )
                  //       : pw.Text(
                  //           'Lentera Komputer',
                  //           style: pw.TextStyle(
                  //             fontSize: 10,
                  //             fontWeight: pw.FontWeight.bold,
                  //             color: darkColor,
                  //           ),
                  //         ),
                  // ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Diki Wahyu Diardi',
                    style: pw.TextStyle(fontSize: 8, color: darkColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
