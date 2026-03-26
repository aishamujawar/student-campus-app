import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message_model.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;
  final RxList<ChatGroupModel> chatGroups = <ChatGroupModel>[].obs;
  final RxList<Map<String, dynamic>> selectedMembers = <Map<String, dynamic>>[].obs;
  
  String? _currentGroupId;
  StreamSubscription<QuerySnapshot>? _messageListener;
  StreamSubscription<QuerySnapshot>? _groupsListener;
  late final StreamSubscription<User?> _authStateSubscription;
  
  @override
  void onInit() {
    super.onInit();
    _setupAuthListener();
  }
  
  void _setupAuthListener() {
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // User logged in - listen to groups
        _listenToGroups();
      } else {
        // User logged out - clear all data and cancel listeners
        _clearAllData();
      }
    });
  }
  
  void _clearAllData() {
    chatGroups.clear();
    selectedMembers.clear();
    messages.clear();
    _groupsListener?.cancel();
    _groupsListener = null;
    cancelListener();
  }
  
  // ───────────────────────── GROUP LISTENER ─────────────────────────
  void _listenToGroups() {
    final user = _auth.currentUser;
    if (user == null) return;
    
    // Cancel existing listener if any
    _groupsListener?.cancel();
    
    _groupsListener = _db
        .collection('chat_groups')
        .where('members', arrayContains: user.uid)
        .snapshots()
        .listen((snapshot) {
      chatGroups.assignAll(
        snapshot.docs.map((doc) => ChatGroupModel.fromDoc(doc)).toList(),
      );
    }, onError: (error) {
      // Silently handle errors
    });
  }
  
  // ───────────────────────── FETCH MESSAGES ─────────────────────────
  void fetchMessages(String groupId) {
    if (_currentGroupId == groupId && _messageListener != null) {
      return;
    }
    
    _messageListener?.cancel();
    messages.clear();
    _currentGroupId = groupId;
    
    _messageListener = _db
        .collection('chat_groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final now = DateTime.now();
      final validMessages = snapshot.docs
          .map((doc) => ChatMessageModel.fromDoc(doc))
          .where((msg) => msg.expiresAt.isAfter(now))
          .toList();
      
      messages.value = validMessages;
    }, onError: (error) {
      // Silently handle errors
    });
  }
  
  // ───────────────────────── SEND MESSAGE ─────────────────────────
  Future<void> sendMessage({
    required String groupId,
    required String message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final userName = await _getUserName(user.uid);
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 7));
    
    await _db
        .collection('chat_groups')
        .doc(groupId)
        .collection('messages')
        .add({
      'message': message.trim(),
      'senderId': user.uid,
      'senderName': userName,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expiresAt),
    });
    
    // Update last message in group
    await _db.collection('chat_groups').doc(groupId).update({
      'lastMessage': message.trim(),
      'lastMessageTime': Timestamp.fromDate(now),
    });
  }
  
  // ───────────────────────── GET USER NAME ─────────────────────────
  Future<String> _getUserName(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data();
      return data?['fullName']?.toString().split(' ').first ?? 'User';
    } catch (e) {
      return 'User';
    }
  }
  
  // ───────────────────────── CREATE GROUP ─────────────────────────
  Future<void> createGroup(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final memberIds = {
      user.uid,
      ...selectedMembers.map((m) => m['uid'] as String),
    }.toList();
    
    if (memberIds.length < 2) {
      Get.snackbar('Error', 'Add at least one member');
      return;
    }
    
    await _db.collection('chat_groups').add({
      'name': name.trim(),
      'members': memberIds,
      'memberCount': memberIds.length,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
      'lastMessageTime': null,
    });
    
    selectedMembers.clear();
  }
  
  // ───────────────────────── ADD MEMBER BY EMAIL ─────────────────────────
  Future<Map<String, dynamic>?> _fetchUserByEmail(String email) async {
    try {
      final query = await _db
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) return null;
      
      return {
        'uid': query.docs.first.id,
        ...query.docs.first.data(),
      };
    } catch (e) {
      return null;
    }
  }
  
  Future<void> addMemberByEmail(String email) async {
    final user = await _fetchUserByEmail(email);
    
    if (user == null) {
      Get.snackbar('Error', 'User not found');
      return;
    }
    
    if (selectedMembers.any((m) => m['uid'] == user['uid'])) {
      Get.snackbar('Info', 'User already added');
      return;
    }
    
    selectedMembers.add(user);
  }
  
  void removeMember(String uid) {
    selectedMembers.removeWhere((m) => m['uid'] == uid);
  }
  
  // ───────────────────────── ADD MEMBER TO EXISTING GROUP ─────────────────────────
  Future<void> addMemberToGroup(String groupId, String email) async {
    final user = await _fetchUserByEmail(email);
    if (user == null) {
      Get.snackbar('Error', 'User not found');
      return;
    }
    
    final ref = _db.collection('chat_groups').doc(groupId);
    final snap = await ref.get();
    
    final List members = List.from(snap['members']);
    
    if (members.contains(user['uid'])) {
      Get.snackbar('Info', 'User already in group');
      return;
    }
    
    members.add(user['uid']);
    
    await ref.update({
      'members': members,
      'memberCount': members.length,
    });
    
    Get.snackbar('Success', 'Member added');
  }
  
  // ───────────────────────── LEAVE GROUP ─────────────────────────
  Future<void> leaveGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final ref = _db.collection('chat_groups').doc(groupId);
    final snap = await ref.get();
    
    final List members = List.from(snap['members']);
    members.remove(user.uid);
    
    if (members.isEmpty) {
      await ref.delete();
    } else {
      await ref.update({
        'members': members,
        'memberCount': members.length,
      });
    }
    
    Get.back();
    Get.snackbar('Success', 'Left group');
  }
  
  // ───────────────────────── CLEANUP ─────────────────────────
  void cancelListener() {
    _messageListener?.cancel();
    _messageListener = null;
    _currentGroupId = null;
    messages.clear();
  }
  
  @override
  void onClose() {
    cancelListener();
    _groupsListener?.cancel();
    _authStateSubscription.cancel();
    super.onClose();
  }
}

// ───────────────────────── CHAT GROUP MODEL ─────────────────────────
class ChatGroupModel {
  final String id;
  final String name;
  final List<String> members;
  final String createdBy;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  ChatGroupModel({
    required this.id,
    required this.name,
    required this.members,
    required this.createdBy,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory ChatGroupModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatGroupModel(
      id: doc.id,
      name: data['name'] ?? 'Chat Group',
      members: List<String>.from(data['members'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null 
          ? (data['lastMessageTime'] as Timestamp).toDate() 
          : null,
    );
  }
}