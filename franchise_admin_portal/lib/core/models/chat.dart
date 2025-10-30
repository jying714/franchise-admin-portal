import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final String userId;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String status;
  final String? userName; // Optionally store the user's name

  Chat({
    required this.id,
    required this.userId,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.status,
    this.userName,
  });

  factory Chat.fromFirestore(Map<String, dynamic> data, String id) {
    return Chat(
      id: id,
      userId: data['userId'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt: (data['lastMessageAt'] is Timestamp)
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: data['status'] ?? 'open',
      userName:
          data['userName'], // Optional, only if you store this in Firestore
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'lastMessage': lastMessage,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'status': status,
      if (userName != null) 'userName': userName,
    };
  }

  /// Getter for userName (falls back to userId if not available)
  String get userNameOrId => userName ?? userId;
}
