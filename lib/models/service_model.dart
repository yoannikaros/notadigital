class Service {
  int? id;
  List<String> jenisKerusakan; // Sekarang bisa diisi bebas
  String? keteranganLainLain; // Keterangan tambahan

  Service({
    this.id,
    required this.jenisKerusakan,
    this.keteranganLainLain,
  });

  // Convert Service object to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jenis_kerusakan': jenisKerusakan.join(','),
      'keterangan_lain_lain': keteranganLainLain,
    };
  }

  // Create Service object from Map (database result)
  factory Service.fromMap(Map<String, dynamic> map) {
    List<String> jenisKerusakanList = [];
    if (map['jenis_kerusakan'] != null && map['jenis_kerusakan'].isNotEmpty) {
      String jenisKerusakanStr = map['jenis_kerusakan'];
      jenisKerusakanList = jenisKerusakanStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    return Service(
      id: map['id'],
      jenisKerusakan: jenisKerusakanList,
      keteranganLainLain: map['keterangan_lain_lain'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jenis_kerusakan': jenisKerusakan,
      'keterangan_lain_lain': keteranganLainLain,
    };
  }

  // Create from JSON
  factory Service.fromJson(Map<String, dynamic> json) {
    List<String> jenisKerusakanList = [];
    if (json['jenis_kerusakan'] != null) {
      if (json['jenis_kerusakan'] is List) {
        jenisKerusakanList = List<String>.from(json['jenis_kerusakan']);
      } else {
        jenisKerusakanList = [json['jenis_kerusakan'].toString()];
      }
    }

    return Service(
      id: json['id'],
      jenisKerusakan: jenisKerusakanList,
      keteranganLainLain: json['keterangan_lain_lain'],
    );
  }

  @override
  String toString() {
    return 'Service{id: $id, jenisKerusakan: $jenisKerusakan, keteranganLainLain: $keteranganLainLain}';
  }
}