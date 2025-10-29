import 'package:franchise_mobile_app/core/models/order.dart';
import 'package:franchise_mobile_app/core/models/favorite_order.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:franchise_mobile_app/core/models/loyalty.dart';
import 'address.dart';

// ===================== USER MODEL =====================
class User {
  static const String roleOwner = 'owner';
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';
  static const String roleStaff = 'staff';
  static const String roleCustomer = 'customer';

  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String role; // 'owner', 'admin', 'manager', 'staff', or 'customer'
  final List<Address> addresses;
  final List<Order> orders;
  final List<FavoriteOrder> favorites;
  final List<ScheduledOrder> scheduledOrders;
  final String language;
  final Loyalty? loyalty;
  final bool? completeProfile; // <--- Added for onboarding logic

  bool get isOwner => role == roleOwner;
  bool get isAdmin => role == roleAdmin;
  bool get isManager => role == roleManager;
  bool get isStaff => role == roleStaff;
  bool get isCustomer =>
      role == roleCustomer || !(isOwner || isAdmin || isManager || isStaff);

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
    List<Address>? addresses,
    List<Order>? orders,
    List<FavoriteOrder>? favorites,
    List<ScheduledOrder>? scheduledOrders,
    required this.language,
    this.loyalty,
    this.completeProfile, // <-- nullable for backward compatibility
  })  : addresses = addresses ?? [],
        orders = orders ?? [],
        favorites = favorites ?? [],
        scheduledOrders = scheduledOrders ?? [];

  // ---- Firestore deserialization ----
  factory User.fromFirestore(Map<String, dynamic> data, String id) {
    final rawRole = data['role'];
    final String effectiveRole =
        (rawRole is String && rawRole.isNotEmpty) ? rawRole : roleCustomer;

    return User(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? data['phone'] ?? '',
      role: effectiveRole,
      addresses: (data['addresses'] as List<dynamic>?)
              ?.map((e) => Address.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      orders: (data['orders'] as List<dynamic>?)
              ?.map((e) =>
                  Order.fromFirestore(Map<String, dynamic>.from(e), e['id']))
              .toList() ??
          [],
      favorites: (data['favorites'] as List<dynamic>?)
              ?.map((e) => FavoriteOrder.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      scheduledOrders: (data['scheduled_orders'] as List<dynamic>?)
              ?.map((e) => ScheduledOrder.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      language: data['language'] ?? 'en',
      loyalty: data['loyalty'] != null
          ? Loyalty.fromMap(Map<String, dynamic>.from(data['loyalty']))
          : null,
      completeProfile:
          data['completeProfile'] is bool ? data['completeProfile'] : false,
    );
  }

  // ---- Firestore serialization ----
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber ?? '',
      'role': role.isNotEmpty ? role : roleCustomer,
      'addresses': addresses.map((e) => e.toMap()).toList(),
      'orders': orders.map((e) => e.toFirestore()).toList(),
      'favorites': favorites.map((e) => e.toMap()).toList(),
      'scheduled_orders': scheduledOrders.map((e) => e.toMap()).toList(),
      'language': language,
      'loyalty': loyalty?.toMap(),
      'completeProfile': completeProfile ?? false,
    };
  }

  // ---- copyWith for convenient object updating ----
  User copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? role,
    List<Address>? addresses,
    List<Order>? orders,
    List<FavoriteOrder>? favorites,
    List<ScheduledOrder>? scheduledOrders,
    String? language,
    Loyalty? loyalty,
    bool? completeProfile,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      addresses: addresses ?? this.addresses,
      orders: orders ?? this.orders,
      favorites: favorites ?? this.favorites,
      scheduledOrders: scheduledOrders ?? this.scheduledOrders,
      language: language ?? this.language,
      loyalty: loyalty ?? this.loyalty,
      completeProfile: completeProfile ?? this.completeProfile,
    );
  }
}

// ===================== SCHEDULED ORDER =====================
class ScheduledOrder {
  final String orderId;
  final String frequency;
  final DateTime nextDate;
  final DateTime? endDate;

  ScheduledOrder({
    required this.orderId,
    required this.frequency,
    required this.nextDate,
    this.endDate,
  });

  factory ScheduledOrder.fromMap(Map<String, dynamic> data) {
    return ScheduledOrder(
      orderId: data['orderId'] ?? '',
      frequency: data['frequency'] ?? '',
      nextDate: (data['nextDate'] is Timestamp)
          ? (data['nextDate'] as Timestamp).toDate()
          : (data['nextDate'] is DateTime)
              ? data['nextDate'] as DateTime
              : DateTime.now(),
      endDate: (data['endDate'] is Timestamp)
          ? (data['endDate'] as Timestamp).toDate()
          : (data['endDate'] is DateTime)
              ? data['endDate'] as DateTime
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'frequency': frequency,
      'nextDate': Timestamp.fromDate(nextDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    };
  }
}

// ===================== TRANSACTION =====================
class Transaction {
  final int points;
  final String orderId;
  final DateTime timestamp;

  Transaction({
    required this.points,
    required this.orderId,
    required this.timestamp,
  });

  factory Transaction.fromMap(Map<String, dynamic> data) {
    return Transaction(
      points: data['points'] ?? 0,
      orderId: data['orderId'] ?? '',
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : (data['timestamp'] is DateTime)
              ? data['timestamp'] as DateTime
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'points': points,
      'orderId': orderId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

// ===================== REWARD =====================
class Reward {
  final String name;
  final int points;
  final DateTime timestamp;

  Reward({
    required this.name,
    required this.points,
    required this.timestamp,
  });

  factory Reward.fromMap(Map<String, dynamic> data) {
    return Reward(
      name: data['name'] ?? '',
      points: data['points'] ?? 0,
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : (data['timestamp'] is DateTime)
              ? data['timestamp'] as DateTime
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'points': points,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
