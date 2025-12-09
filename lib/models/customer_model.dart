class Customer {
  int? id;
  String nama;
  String noHp;
  String? alamat;

  Customer({
    this.id,
    required this.nama,
    required this.noHp,
    this.alamat,
  });

  // Convert Customer object to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'no_hp': noHp,
      'alamat': alamat,
    };
  }

  // Create Customer object from Map (database result)
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      nama: map['nama'],
      noHp: map['no_hp'],
      alamat: map['alamat'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'no_hp': noHp,
      'alamat': alamat,
    };
  }

  // Create from JSON
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      nama: json['nama'],
      noHp: json['no_hp'],
      alamat: json['alamat'],
    );
  }

  @override
  String toString() {
    return 'Customer{id: $id, nama: $nama, noHp: $noHp, alamat: $alamat}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}