class FranchiseInfo {
  final String id;
  final String name;
  final String? logoUrl;
  final String? status;

  FranchiseInfo({
    required this.id,
    required this.name,
    this.logoUrl,
    this.status,
  });

  factory FranchiseInfo.fromFirestore(Map<String, dynamic> data, String id) {
    return FranchiseInfo(
      id: id,
      name: data['name'] ?? 'Unnamed Franchise',
      logoUrl: data['logoUrl'],
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (status != null) 'status': status,
    };
  }
}
