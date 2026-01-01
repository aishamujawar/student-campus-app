import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Groups user belongs to
  final RxList<Map<String, dynamic>> groups = <Map<String, dynamic>>[].obs;

  /// Members selected while creating a group
  final RxList<Map<String, dynamic>> selectedMembers =
      <Map<String, dynamic>>[].obs;

  StreamSubscription<QuerySnapshot>? _groupSubscription;

  // ───────────────────────── INIT ─────────────────────────

  @override
  void onInit() {
    super.onInit();

    _auth.authStateChanges().listen((user) {
      _groupSubscription?.cancel();

      if (user != null) {
        _listenToGroups(user.uid);
      } else {
        groups.clear();
      }
    });
  }

  // ───────────────────────── GROUP LISTENER ─────────────────────────

  void _listenToGroups(String uid) {
    _groupSubscription = _firestore
        .collection('groups')
        .where('members', arrayContains: uid)
        .snapshots()
        .listen(
      (snapshot) {
        groups.value = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();
      },
      onError: (e) {
        debugPrint('Fetch groups error: $e');
      },
    );
  }

  // ───────────────────────── USER LOOKUP ─────────────────────────

  Future<Map<String, dynamic>?> fetchUserByEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final doc = query.docs.first;

      return {
        'uid': doc.id,
        ...doc.data(),
      };
    } catch (e) {
      debugPrint('Fetch user by email error: $e');
      return null;
    }
  }

  // ───────────────────────── MEMBER MANAGEMENT ─────────────────────────

  Future<void> addMemberByEmail(String email) async {
    if (email.trim().isEmpty) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final user = await fetchUserByEmail(email);

    if (user == null) {
      Get.snackbar('Error', 'User not found');
      return;
    }

    // ❌ Prevent adding yourself
    if (user['uid'] == currentUser.uid) {
      Get.snackbar('Info', 'You are already part of the group');
      return;
    }

    final alreadyAdded = selectedMembers.any((m) => m['uid'] == user['uid']);

    if (alreadyAdded) {
      Get.snackbar('Info', 'User already added');
      return;
    }

    selectedMembers.add(user);
  }

  void removeMember(String uid) {
    selectedMembers.removeWhere((m) => m['uid'] == uid);
  }

  void clearSelectedMembers() {
    selectedMembers.clear();
  }

  // ───────────────────────── CREATE GROUP ─────────────────────────

  Future<void> createGroup(String name) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      if (name.trim().isEmpty) {
        throw Exception('Group name cannot be empty');
      }

      final memberIds = {
        user.uid,
        ...selectedMembers.map((m) => m['uid'] as String),
      }.toList();

      await _firestore.collection('groups').add({
        'name': name.trim(),
        'members': memberIds,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      clearSelectedMembers();
    } catch (e) {
      debugPrint('Create group error: $e');
      Get.snackbar('Error', 'Something went wrong while creating group');
      rethrow;
    }
  }

  // ───────────────────────── CLEANUP ─────────────────────────

  @override
  void onClose() {
    _groupSubscription?.cancel();
    super.onClose();
  }
}
