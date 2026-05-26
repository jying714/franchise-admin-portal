class Address {
  final String id;
  final String label;
  final String street;
  final String city;
  final String state;
  final String zip;
  final String? name;
  final String? phone;

  Address({
    required this.id,
    this.label = '',
    this.street = '',
    this.city = '',
    this.state = '',
    this.zip = '',
    this.name,
    this.phone,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'street': street,
    'city': city,
    'state': state,
    'zip': zip,
    if (name != null) 'name': name,
    if (phone != null) 'phone': phone,
  };

  factory Address.fromMap(Map<String, dynamic> map) => Address(
    id: map['id'] ?? '',
    label: map['label'] ?? '',
    street: map['street'] ?? '',
    city: map['city'] ?? '',
    state: map['state'] ?? '',
    zip: map['zip'] ?? '',
    name: map['name'],
    phone: map['phone'],
  );
}
