class Address {
  final String id;
  final String street;
  final String city;
  final String state;
  final String zip;
  final String label; // e.g., "Home", "Work"
  final String? name; // e.g., "John Doe" (Recipient Name, Optional)

  Address({
    required this.id,
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    required this.label,
    this.name,
  });

  factory Address.fromMap(Map<String, dynamic> data) {
    return Address(
      id: data['id'] ?? '', // Add this line
      street: data['street'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      zip: data['zip'] ?? '',
      label: data['label'] ?? '',
      name: data['name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, // Add this line
      'street': street,
      'city': city,
      'state': state,
      'zip': zip,
      'label': label,
      if (name != null) 'name': name,
    };
  }

  /// Fallback for name display (for admin usage): name > label
  String get nameDisplay => name?.isNotEmpty == true ? name! : label;
}
