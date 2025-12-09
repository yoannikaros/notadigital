class InvoiceItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final String? namaBarang; // nama barang untuk detail item
  final String? snBarang; // serial number barang
  final String? garansi; // garansi barang
  
  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.namaBarang,
    this.snBarang,
    this.garansi,
  });
  
  double get amount => quantity * unitPrice;
}

class CompanyInfo {
  final String name;
  final String address;
  final String phone;
  final String email;
  final String website;
  
  CompanyInfo({
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
  });
}

class ClientInfo {
  final String name;
  final String address;
  final String? phone;
  
  ClientInfo({
    required this.name,
    required this.address,
    this.phone,
  });
}

class Invoice {
  final String invoiceNumber;
  final DateTime date;
  final DateTime dueDate;
  final CompanyInfo company;
  final ClientInfo client;
  final List<InvoiceItem> items;
  final double taxRate; // dalam persen
  final String? merkBarang;
  final String? snBarang;
  final String? namaBarang;
  final double? dpAmount; // Jumlah DP (Down Payment)
  final String paymentStatus; // Status pembayaran: 'Lunas', 'Belum Lunas', 'DP'
  final String paymentMethod; // Metode pembayaran: 'Transfer Bank', 'Cash', 'Credit Card', dll
  
  Invoice({
    required this.invoiceNumber,
    required this.date,
    required this.dueDate,
    required this.company,
    required this.client,
    required this.items,
    this.taxRate = 10.0,
    this.merkBarang,
    this.snBarang,
    this.namaBarang,
    this.dpAmount,
    this.paymentStatus = 'Belum Lunas',
    this.paymentMethod = 'Transfer Bank',
  });

  
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.amount);
  double get taxAmount => subtotal * (taxRate / 100);
  double get total => subtotal + taxAmount;
  
  // Getter untuk sisa pembayaran
  double get sisaAmount {
    if (dpAmount != null) {
      return total - dpAmount!;
    }
    return total;
  }
  
  // Getter untuk mengecek apakah ada DP
  bool get hasDP => dpAmount != null && dpAmount! > 0;
}