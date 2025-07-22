class FranchiseInfo {
  final String id;
  final String name;
  final String? logoUrl;
  final String? status;
  final String? ownerName;
  final String? phone;
  final String? businessEmail;

  FranchiseInfo({
    required this.id,
    required this.name,
    this.logoUrl,
    this.status,
    this.ownerName,
    this.phone,
    this.businessEmail,
  });

  factory FranchiseInfo.fromMap(Map<String, dynamic> data, String id) {
    return FranchiseInfo(
      id: id,
      name: data['name'] ?? 'Unnamed Franchise',
      logoUrl: data['logoUrl'],
      status: data['status'] ?? 'active',
      ownerName: data['ownerName'],
      phone: data['phone'],
      businessEmail: data['businessEmail'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (status != null) 'status': status,
      if (ownerName != null) 'ownerName': ownerName,
      if (phone != null) 'phone': phone,
      if (businessEmail != null) 'businessEmail': businessEmail,
    };
  }
}
