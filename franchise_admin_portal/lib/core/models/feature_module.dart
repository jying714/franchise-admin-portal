class FeatureModule {
  final bool enabled;
  final Map<String, bool> features;

  FeatureModule({
    required this.enabled,
    required this.features,
  });

  factory FeatureModule.fromMap(Map<String, dynamic> map) {
    return FeatureModule(
      enabled: map['enabled'] == true,
      features: Map<String, bool>.from(map['features'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'features': features,
    };
  }

  FeatureModule copyWith({
    bool? enabled,
    Map<String, bool>? features,
  }) {
    return FeatureModule(
      enabled: enabled ?? this.enabled,
      features: features ?? Map<String, bool>.from(this.features),
    );
  }
}
