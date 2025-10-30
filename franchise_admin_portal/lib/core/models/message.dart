import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final String status;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.status,
  });

  /// Serialization for Firestore
  Map<String, dynamic> toFirestore() => {
        'senderId': senderId,
        'content': content,
        'timestamp': Timestamp.fromDate(timestamp),
        'status': status,
      };

  /// Deserialization from Firestore (requires document ID)
  static Message fromFirestore(Map<String, dynamic> data, String id) {
    return Message(
      id: id,
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      status: data['status'] ?? '',
    );
  }

  /// For local caching or general Dart usage (same as Firestore serialization)
  Map<String, dynamic> toMap() => toFirestore();

  /// Factory for deserialization if you have both the data map and ID
  factory Message.fromMap(Map<String, dynamic> data, String id) =>
      Message.fromFirestore(data, id);
}
