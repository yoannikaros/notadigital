class CompanySettings {
  final int? id;
  final String companyName;
  final String companyAddress;
  final String companyPhone;
  final String companyEmail;
  final String companyWebsite;

  CompanySettings({
    this.id,
    required this.companyName,
    required this.companyAddress,
    required this.companyPhone,
    required this.companyEmail,
    required this.companyWebsite,
  });

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id ?? 1, // Always use id 1 for single settings record
      'company_name': companyName,
      'company_address': companyAddress,
      'company_phone': companyPhone,
      'company_email': companyEmail,
      'company_website': companyWebsite,
    };
  }

  // Create from Map (database result)
  factory CompanySettings.fromMap(Map<String, dynamic> map) {
    return CompanySettings(
      id: map['id'] as int?,
      companyName: map['company_name'] as String,
      companyAddress: map['company_address'] as String,
      companyPhone: map['company_phone'] as String,
      companyEmail: map['company_email'] as String,
      companyWebsite: map['company_website'] as String,
    );
  }

  // Validation
  bool isValid() {
    return companyName.isNotEmpty &&
        companyAddress.isNotEmpty &&
        companyPhone.isNotEmpty &&
        companyEmail.isNotEmpty &&
        companyWebsite.isNotEmpty;
  }

  // Create default settings
  factory CompanySettings.defaultSettings() {
    return CompanySettings(
      id: 1,
      companyName: 'Lentera Komputer',
      companyAddress: 'Jl. Contoh No. 123\nKota, Provinsi 12345',
      companyPhone: '0821-1712-3434',
      companyEmail: 'lenteracomp.bdg@gmail.com',
      companyWebsite: 'www.lenterakomputer.com',
    );
  }

  // Copy with method for easy updates
  CompanySettings copyWith({
    int? id,
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyEmail,
    String? companyWebsite,
  }) {
    return CompanySettings(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      companyWebsite: companyWebsite ?? this.companyWebsite,
    );
  }
}
