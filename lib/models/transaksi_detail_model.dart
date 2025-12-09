class TransaksiDetail {
  int? detailId;
  int? transaksiId;
  int qty;
  String deskripsi;
  double harga;
  int? barangId; // relasi opsional
  int? serviceId; // relasi opsional
  String? namaBarang; // nama barang untuk detail item
  String? snBarang; // serial number barang
  String? garansi; // garansi barang

  TransaksiDetail({
    this.detailId,
    this.transaksiId,
    required this.qty,
    required this.deskripsi,
    required this.harga,
    this.barangId,
    this.serviceId,
    this.namaBarang,
    this.snBarang,
    this.garansi,
  });

  // Convert TransaksiDetail object to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'detail_id': detailId,
      'transaksi_id': transaksiId,
      'qty': qty,
      'deskripsi': deskripsi,
      'harga': harga,
      'barang_id': barangId,
      'service_id': serviceId,
      'nama_barang': namaBarang,
      'sn_barang': snBarang,
      'garansi': garansi,
    };
  }

  // Create TransaksiDetail object from Map (database result)
  factory TransaksiDetail.fromMap(Map<String, dynamic> map) {
    return TransaksiDetail(
      detailId: map['detail_id'],
      transaksiId: map['transaksi_id'],
      qty: map['qty'],
      deskripsi: map['deskripsi'],
      harga: map['harga']?.toDouble(),
      barangId: map['barang_id'],
      serviceId: map['service_id'],
      namaBarang: map['nama_barang'],
      snBarang: map['sn_barang'],
      garansi: map['garansi'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'detail_id': detailId,
      'transaksi_id': transaksiId,
      'qty': qty,
      'deskripsi': deskripsi,
      'harga': harga,
      'barang_id': barangId,
      'service_id': serviceId,
      'nama_barang': namaBarang,
      'sn_barang': snBarang,
      'garansi': garansi,
    };
  }

  // Create from JSON
  factory TransaksiDetail.fromJson(Map<String, dynamic> json) {
    return TransaksiDetail(
      detailId: json['detail_id'],
      transaksiId: json['transaksi_id'],
      qty: json['qty'],
      deskripsi: json['deskripsi'],
      harga: json['harga']?.toDouble(),
      barangId: json['barang_id'],
      serviceId: json['service_id'],
      namaBarang: json['nama_barang'],
      snBarang: json['sn_barang'],
      garansi: json['garansi'],
    );
  }

  // Calculate total price for this detail (qty * harga)
  double get totalHarga => qty * harga;

  // Check if this detail is related to a barang
  bool get isBarangRelated => barangId != null;

  // Check if this detail is related to a service
  bool get isServiceRelated => serviceId != null;

  // Get item type description
  String get itemType {
    if (isBarangRelated) return 'Barang';
    if (isServiceRelated) return 'Service';
    return 'Item';
  }
}