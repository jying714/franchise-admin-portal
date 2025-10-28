class Address {
  final String street;
  final String city;
  final String state;
  final String zip;
  final String label; // e.g., "Home", "Work"
  final String? name; // e.g., "John Doe" (Recipient Name, Optional)

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    required this.label,
    this.name,
  });

  factory Address.fromMap(Map<String, dynamic> data) {
    return Address(
      street: data['street'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      zip: data['zip'] ?? '',
      label: data['label'] ?? '',
      name: data['name'], // Accepts null if not present
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
