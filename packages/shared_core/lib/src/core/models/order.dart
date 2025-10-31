import 'package:cloud_firestore/cloud_firestore.dart';
import 'address.dart';

class Order {
  final String id;
  final String userId;
  final String storeId;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double discount;
  final double total;
  final String deliveryType;
  final String time;
  final String status;
  final DateTime timestamp;
  final int estimatedTime;
  final Map<String, dynamic> timestamps;
  final Address? address;
  final String? userName;
  final String? refundStatus;
  final Address? deliveryAddress;
  final String? specialInstructions;

  bool get isFeedbackEligible =>
      status.toLowerCase() == 'completed' ||
      status.toLowerCase() == 'placed' ||
      status.toLowerCase() == 'delivered';

  Order({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.deliveryType,
    required this.time,
    required this.status,
    required this.timestamp,
    required this.estimatedTime,
    required this.timestamps,
    this.address,
    this.userName,
    this.refundStatus,
    this.deliveryAddress,
    this.specialInstructions,
  });

  factory Order.fromFirestore(Map<String, dynamic> data, String id) {
    return Order(
      id: id,
      userId: data['userId'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (data['tax'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      deliveryType: data['deliveryType'] ?? '',
      time: data['time'] ?? '',
      status: data['status'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : (data['timestamp'] as DateTime?) ?? DateTime.now(),
      estimatedTime: data['estimatedTime'] as int? ?? 0,
      timestamps: Map<String, dynamic>.from(data['timestamps'] as Map? ?? {}),
      address: data['address'] != null
          ? Address.fromMap(Map<String, dynamic>.from(data['address']))
          : null,
      userName: data['userName'],
      refundStatus: data['refundStatus'],
      deliveryAddress: data['deliveryAddress'] != null
          ? Address.fromMap(Map<String, dynamic>.from(data['deliveryAddress']))
          : null,
      specialInstructions: data['specialInstructions'],
      storeId: data['storeId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'storeId': storeId,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'total': total,
      'deliveryType': deliveryType,
      'time': time,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'estimatedTime': estimatedTime,
      'timestamps': timestamps,
      'address': address?.toMap(),
      'userName': userName,
      'refundStatus': refundStatus,
      'deliveryAddress': deliveryAddress?.toMap(),
      'specialInstructions': specialInstructions,
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    String? storeId,
    List<OrderItem>? items,
    double? subtotal,
    double? tax,
    double? deliveryFee,
    double? discount,
    double? total,
    String? deliveryType,
    String? time,
    String? status,
    DateTime? timestamp,
    int? estimatedTime,
    Map<String, dynamic>? timestamps,
    Address? address,
    String? userName,
    String? refundStatus,
    Address? deliveryAddress,
    String? specialInstructions,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storeId: storeId ?? this.storeId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      deliveryType: deliveryType ?? this.deliveryType,
      time: time ?? this.time,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      timestamps: timestamps ?? this.timestamps,
      address: address ?? this.address,
      userName: userName ?? this.userName,
      refundStatus: refundStatus ?? this.refundStatus,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  String get userNameDisplay =>
      userName ?? (address?.name?.isNotEmpty == true ? address!.name! : userId);

  String get refundStatusDisplay => refundStatus ?? '';
}

class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final Map<String, dynamic> customizations;
  final String? image;
  final String? size;
  final String? cartItemKey;
  final double? deliveryFee;
  final double? discount;
  final String? deliveryType;
  final String? time;
  final DateTime? timestamp;
  final int? estimatedTime;
  final Address? deliveryAddress;
  final String? specialInstructions;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.customizations,
    this.image,
    this.size,
    this.cartItemKey,
    this.deliveryFee,
    this.discount,
    this.deliveryType,
    this.time,
    this.timestamp,
    this.estimatedTime,
    this.deliveryAddress,
    this.specialInstructions,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      menuItemId: data['menuItemId'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      quantity: data['quantity'] ?? 1,
      customizations: data['customizations'] != null
          ? Map<String, dynamic>.from(data['customizations'])
          : {},
      image: data['image'],
      size: data['size'],
      cartItemKey: data['cartItemKey'],
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble(),
      discount: (data['discount'] as num?)?.toDouble(),
      deliveryType: data['deliveryType'],
      time: data['time'],
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : data['timestamp'] as DateTime?,
      estimatedTime: data['estimatedTime'],
      deliveryAddress: data['deliveryAddress'] != null
          ? Address.fromMap(Map<String, dynamic>.from(data['deliveryAddress']))
          : null,
      specialInstructions: data['specialInstructions'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'customizations': customizations,
      if (image != null) 'image': image,
      if (size != null) 'size': size,
      if (cartItemKey != null) 'cartItemKey': cartItemKey,
      if (deliveryFee != null) 'deliveryFee': deliveryFee,
      if (discount != null) 'discount': discount,
      if (deliveryType != null) 'deliveryType': deliveryType,
      if (time != null) 'time': time,
      if (timestamp != null) 'timestamp': Timestamp.fromDate(timestamp!),
      if (estimatedTime != null) 'estimatedTime': estimatedTime,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress!.toMap(),
      if (specialInstructions != null)
        'specialInstructions': specialInstructions,
    };
  }

  OrderItem copyWith({
    String? menuItemId,
    String? name,
    double? price,
    int? quantity,
    Map<String, dynamic>? customizations,
    String? image,
    String? size,
    String? cartItemKey,
    double? deliveryFee,
    double? discount,
    String? deliveryType,
    String? time,
    DateTime? timestamp,
    int? estimatedTime,
    Address? deliveryAddress,
    String? specialInstructions,
  }) {
    return OrderItem(
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      customizations: customizations ?? this.customizations,
      image: image ?? this.image,
      size: size ?? this.size,
      cartItemKey: cartItemKey ?? this.cartItemKey,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      deliveryType: deliveryType ?? this.deliveryType,
      time: time ?? this.time,
      timestamp: timestamp ?? this.timestamp,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  double get totalPrice => price * quantity;
}
