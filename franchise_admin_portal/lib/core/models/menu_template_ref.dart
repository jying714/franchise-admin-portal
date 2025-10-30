class MenuTemplateRef {
  final String id;
  final String name;
  // Add other fields as needed (e.g., preview, description)

  MenuTemplateRef({required this.id, required this.name});

  factory MenuTemplateRef.fromFirestore(Map<String, dynamic> data) {
    return MenuTemplateRef(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
    );
  }
}
