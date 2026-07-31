/// Single table (or seatable node) on the floor plan.
class PosTableNode {
  final String id;
  final String label;
  final double x;
  final double y;
  final double width;
  final double height;
  final int seats;

  /// free | seated | reserved | dirty (runtime may override; stored default free)
  final String status;
  final String shape; // rect | round

  PosTableNode({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    this.width = 80,
    this.height = 80,
    this.seats = 4,
    this.status = 'free',
    this.shape = 'rect',
  });

  factory PosTableNode.fromMap(Map<String, dynamic> data) {
    return PosTableNode(
      id: data['id'] as String? ?? '',
      label: data['label'] as String? ?? '',
      x: (data['x'] as num?)?.toDouble() ?? 0,
      y: (data['y'] as num?)?.toDouble() ?? 0,
      width: (data['width'] as num?)?.toDouble() ?? 80,
      height: (data['height'] as num?)?.toDouble() ?? 80,
      seats: data['seats'] as int? ?? 4,
      status: data['status'] as String? ?? 'free',
      shape: data['shape'] as String? ?? 'rect',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'seats': seats,
      'status': status,
      'shape': shape,
    };
  }

  PosTableNode copyWith({
    String? id,
    String? label,
    double? x,
    double? y,
    double? width,
    double? height,
    int? seats,
    String? status,
    String? shape,
  }) {
    return PosTableNode(
      id: id ?? this.id,
      label: label ?? this.label,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      seats: seats ?? this.seats,
      status: status ?? this.status,
      shape: shape ?? this.shape,
    );
  }
}

/// Full floor plan for one franchise (built in web-app only).
class PosTableLayout {
  final String franchiseId;
  final double canvasWidth;
  final double canvasHeight;
  final List<PosTableNode> tables;
  final int version;
  final DateTime? updatedAt;

  PosTableLayout({
    required this.franchiseId,
    this.canvasWidth = 1024,
    this.canvasHeight = 768,
    this.tables = const <PosTableNode>[],
    this.version = 1,
    this.updatedAt,
  });

  factory PosTableLayout.empty(String franchiseId) {
    return PosTableLayout(franchiseId: franchiseId);
  }

  factory PosTableLayout.fromFirestore(
    Map<String, dynamic> data,
    String franchiseId,
  ) {
    final rawTables = data['tables'];
    final tables = rawTables is List
        ? rawTables
            .whereType<Map>()
            .map((e) => PosTableNode.fromMap(Map<String, dynamic>.from(e)))
            .toList()
        : <PosTableNode>[];

    DateTime? updatedAt;
    final ts = data['updatedAt'];
    if (ts != null) {
      try {
        // Avoid hard import if Timestamp not desired here; accept ISO or leave null.
        if (ts is DateTime) {
          updatedAt = ts;
        }
      } catch (_) {}
    }

    return PosTableLayout(
      franchiseId: franchiseId,
      canvasWidth: (data['canvasWidth'] as num?)?.toDouble() ?? 1024,
      canvasHeight: (data['canvasHeight'] as num?)?.toDouble() ?? 768,
      tables: tables,
      version: data['version'] as int? ?? 1,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'franchiseId': franchiseId,
      'canvasWidth': canvasWidth,
      'canvasHeight': canvasHeight,
      'tables': tables.map((t) => t.toMap()).toList(),
      'version': version,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  PosTableLayout copyWith({
    String? franchiseId,
    double? canvasWidth,
    double? canvasHeight,
    List<PosTableNode>? tables,
    int? version,
    DateTime? updatedAt,
  }) {
    return PosTableLayout(
      franchiseId: franchiseId ?? this.franchiseId,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      tables: tables ?? this.tables,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
