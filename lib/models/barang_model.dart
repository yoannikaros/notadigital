class Barang {
  int? id;
  String? nama; // Nama barang
  String? supplier; // Supplier/Distributor
  DateTime? tanggalPembelian; // Tanggal pembelian
  double? hppModal; // HPP (Harga Pokok Penjualan) / Modal
  double? hargaJual; // Harga jual
  int? stok; // Stok barang
  int? keluar; // Barang keluar
  int? sisa; // Sisa stok (calculated field: stok - keluar)

  Barang({
    this.id,
    this.nama,
    this.supplier,
    this.tanggalPembelian,
    this.hppModal,
    this.hargaJual,
    this.stok,
    this.keluar,
  });

  // Calculate sisa stok
  int get sisaStok {
    return (stok ?? 0) - (keluar ?? 0);
  }

  // Convert Barang object to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'supplier': supplier,
      'tanggal_pembelian': tanggalPembelian?.millisecondsSinceEpoch,
      'hpp_modal': hppModal,
      'harga_jual': hargaJual,
      'stok': stok,
      'keluar': keluar,
    };
  }

  // Create Barang object from Map (database result)
  factory Barang.fromMap(Map<String, dynamic> map) {
    return Barang(
      id: map['id'],
      nama: map['nama'],
      supplier: map['supplier'],
      tanggalPembelian: map['tanggal_pembelian'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['tanggal_pembelian'])
          : null,
      hppModal: map['hpp_modal']?.toDouble(),
      hargaJual: map['harga_jual']?.toDouble(),
      stok: map['stok'],
      keluar: map['keluar'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'supplier': supplier,
      'tanggal_pembelian': tanggalPembelian?.toIso8601String(),
      'hpp_modal': hppModal,
      'harga_jual': hargaJual,
      'stok': stok,
      'keluar': keluar,
    };
  }

  // Create from JSON
  factory Barang.fromJson(Map<String, dynamic> json) {
    return Barang(
      id: json['id'],
      nama: json['nama'],
      supplier: json['supplier'],
      tanggalPembelian: json['tanggal_pembelian'] != null 
          ? DateTime.parse(json['tanggal_pembelian'])
          : null,
      hppModal: json['hpp_modal']?.toDouble(),
      hargaJual: json['harga_jual']?.toDouble(),
      stok: json['stok'],
      keluar: json['keluar'],
    );
  }

  @override
  String toString() {
    return 'Barang{id: $id, nama: $nama, supplier: $supplier, tanggalPembelian: $tanggalPembelian, hppModal: $hppModal, hargaJual: $hargaJual, stok: $stok, keluar: $keluar, sisa: $sisaStok}';
  }
}