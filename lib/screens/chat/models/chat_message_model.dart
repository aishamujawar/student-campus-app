import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String message;
  final String senderId;
  final String senderName;
  final DateTime createdAt;
  final DateTime expiresAt;

  ChatMessageModel({
    required this.id,
    required this.message,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    required this.expiresAt,
  });

  factory ChatMessageModel.fromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatMessageModel(
      id: doc.id,
      message: data['message'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'User',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      expiresAt: data['expiresAt'] != null 
          ? (data['expiresAt'] as Timestamp).toDate() 
          : DateTime.now().add(const Duration(days: 7)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'senderId': senderId,
      'senderName': senderName,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }
}