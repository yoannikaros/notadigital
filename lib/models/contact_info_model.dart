import 'customer_model.dart';

class ContactInfo {
  final String name;
  final String phoneNumber;
  final String? displayName;
  
  ContactInfo({
    required this.name,
    required this.phoneNumber,
    this.displayName,
  });
  
  // Convert ContactInfo object to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'display_name': displayName,
    };
  }
  
  // Create ContactInfo object from Map (database result)
  factory ContactInfo.fromMap(Map<String, dynamic> map) {
    return ContactInfo(
      name: map['name'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      displayName: map['display_name'],
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'display_name': displayName,
    };
  }
  
  // Create from JSON
  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      displayName: json['display_name'],
    );
  }
  
  @override
  String toString() {
    return displayName ?? name;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactInfo &&
        other.name == name &&
        other.phoneNumber == phoneNumber;
  }
  
  @override
  int get hashCode => name.hashCode ^ phoneNumber.hashCode;
}

enum CustomerSource {
  database,
  contact,
}

class CustomerSelection {
  final CustomerSource source;
  final Customer? customer;
  final ContactInfo? contact;
  
  CustomerSelection.fromDatabase(this.customer)
      : source = CustomerSource.database,
        contact = null;
  
  CustomerSelection.fromContact(this.contact)
      : source = CustomerSource.contact,
        customer = null;
  
  String get displayName {
    switch (source) {
      case CustomerSource.database:
        return customer?.nama ?? '';
      case CustomerSource.contact:
        return contact?.name ?? '';
    }
  }
  
  String get phoneNumber {
    switch (source) {
      case CustomerSource.database:
        return customer?.noHp ?? '';
      case CustomerSource.contact:
        return contact?.phoneNumber ?? '';
    }
  }
  
  String? get address {
    switch (source) {
      case CustomerSource.database:
        return customer?.alamat;
      case CustomerSource.contact:
        return null; // Contacts don't have address
    }
  }
}