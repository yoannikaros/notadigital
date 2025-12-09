class Transaksi {
  int? transaksiId;
  String noInvoice;
  DateTime tanggal;
  int? customerId;
  double? subtotal;
  double dp;
  double? sisa;
  String status;
  String? metodePembayaran;
  String? merkBarang;
  String? snBarang;
  String? namaBarang;
  String? contactSource;
  String? contactData;

  Transaksi({
    this.transaksiId,
    required this.noInvoice,
    required this.tanggal,
    this.customerId,
    this.subtotal,
    this.dp = 0,
    this.sisa,
    this.status = 'Belum Lunas',
    this.metodePembayaran,
    this.merkBarang,
    this.snBarang,
    this.namaBarang,
    this.contactSource,
    this.contactData,
  });

  // Convert Transaksi object to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'transaksi_id': transaksiId,
      'no_invoice': noInvoice,
      'tanggal': tanggal.toIso8601String(),
      'customer_id': customerId,
      'subtotal': subtotal,
      'dp': dp,
      'sisa': sisa,
      'status': status,
      'metode_pembayaran': metodePembayaran,
      'merk_barang': merkBarang,
      'sn_barang': snBarang,
      'nama_barang': namaBarang,
      'contact_source': contactSource,
      'contact_data': contactData,
    };
  }

  // Create Transaksi object from Map (database result)
  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      transaksiId: map['transaksi_id'],
      noInvoice: map['no_invoice'],
      tanggal: DateTime.parse(map['tanggal']),
      customerId: map['customer_id'],
      subtotal: map['subtotal']?.toDouble(),
      dp: map['dp']?.toDouble() ?? 0,
      sisa: map['sisa']?.toDouble(),
      status: map['status'] ?? 'Belum Lunas',
      metodePembayaran: map['metode_pembayaran'],
      merkBarang: map['merk_barang'],
      snBarang: map['sn_barang'],
      namaBarang: map['nama_barang'],
      contactSource: map['contact_source'],
      contactData: map['contact_data'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'transaksi_id': transaksiId,
      'no_invoice': noInvoice,
      'tanggal': tanggal.toIso8601String(),
      'customer_id': customerId,
      'subtotal': subtotal,
      'dp': dp,
      'sisa': sisa,
      'status': status,
      'metode_pembayaran': metodePembayaran,
      'merk_barang': merkBarang,
      'sn_barang': snBarang,
      'nama_barang': namaBarang,
      'contact_source': contactSource,
      'contact_data': contactData,
    };
  }

  // Create from JSON
  factory Transaksi.fromJson(Map<String, dynamic> json) {
    return Transaksi(
      transaksiId: json['transaksi_id'],
      noInvoice: json['no_invoice'],
      tanggal: DateTime.parse(json['tanggal']),
      customerId: json['customer_id'],
      subtotal: json['subtotal']?.toDouble(),
      dp: json['dp']?.toDouble() ?? 0,
      sisa: json['sisa']?.toDouble(),
      status: json['status'] ?? 'Belum Lunas',
      metodePembayaran: json['metode_pembayaran'],
      merkBarang: json['merk_barang'],
      snBarang: json['sn_barang'],
      namaBarang: json['nama_barang'],
      contactSource: json['contact_source'],
      contactData: json['contact_data'],
    );
  }

  // Calculate sisa automatically
  void calculateSisa() {
    if (subtotal != null) {
      sisa = subtotal! - dp;
    }
  }

  // Check if transaction is fully paid
  bool get isLunas => status == 'Lunas';

  // Update status based on payment
  void updateStatus() {
    if (sisa != null && sisa! <= 0) {
      status = 'Lunas';
    } else {
      status = 'Belum Lunas';
    }
  }
}