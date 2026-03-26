import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ───────────────────────── GROUP LIST ─────────────────────────
  final RxList<Map<String, dynamic>> groups = <Map<String, dynamic>>[].obs;

  // ───────────────────────── CREATE GROUP STATE ─────────────────────────
  final RxList<Map<String, dynamic>> selectedMembers =
      <Map<String, dynamic>>[].obs;

  StreamSubscription<QuerySnapshot>? _groupSubscription;
  late final StreamSubscription<User?> _authStateSubscription;

  // ───────────────────────── INIT ─────────────────────────
  @override
  void onInit() {
    super.onInit();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authStateSubscription = _auth.authStateChanges().listen((user) {
      // Cancel existing subscription
      _groupSubscription?.cancel();
      
      if (user != null) {
        // Clear selected members when user changes
        selectedMembers.clear();
        _listenToGroups(user.uid);
      } else {
        groups.clear();
        selectedMembers.clear();
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
            groups.assignAll(
              snapshot.docs.map((doc) {
                return {
                  'id': doc.id,
                  ...doc.data(),
                };
              }).toList(),
            );
          },
          onError: (error) {
            // Silently handle errors
          },
        );
  }

  // ───────────────────────── USER LOOKUP ─────────────────────────
  Future<Map<String, dynamic>?> _fetchUserByEmail(String email) async {
    try {
      final query = await _firestore
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

  // ───────────────────────── CREATE GROUP FLOW ─────────────────────────

  Future<void> addMemberByEmail(String email) async {
    final user = await _fetchUserByEmail(email);

    if (user == null) {
      Get.snackbar('Error', 'User not found');
      return;
    }

    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == user['uid']) {
      Get.snackbar('Info', 'You cannot add yourself');
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

    try {
      await _firestore.collection('groups').add({
        'name': name.trim(),
        'members': memberIds,
        'memberCount': memberIds.length,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      selectedMembers.clear();
      Get.snackbar('Success', 'Group created successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to create group');
    }
  }

  // ───────────────────────── LIVE GROUP MANAGEMENT ─────────────────────────

  Future<void> addMemberToGroup(String groupId, String email) async {
    final user = await _fetchUserByEmail(email);
    if (user == null) {
      Get.snackbar('Error', 'User not found');
      return;
    }

    final ref = _firestore.collection('groups').doc(groupId);
    final snap = await ref.get();

    if (!snap.exists) {
      Get.snackbar('Error', 'Group not found');
      return;
    }

    final List members = List.from(snap['members'] ?? []);

    if (members.contains(user['uid'])) {
      Get.snackbar('Info', 'User already in group');
      return;
    }

    members.add(user['uid']);

    await ref.update({
      'members': members,
      'memberCount': members.length,
    });

    Get.snackbar('Success', '${user['fullName'] ?? 'User'} added to group');
  }

  Future<void> removeMemberFromGroup(String groupId, String memberId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final ref = _firestore.collection('groups').doc(groupId);
    final snap = await ref.get();

    if (!snap.exists) {
      Get.snackbar('Error', 'Group not found');
      return;
    }

    final List members = List.from(snap['members'] ?? []);
    
    if (!members.contains(memberId)) {
      Get.snackbar('Error', 'Member not found');
      return;
    }

    // Don't allow removing the last member (group would have 0 or 1 member)
    if (members.length <= 2) {
      Get.snackbar('Error', 'Group must have at least 2 members');
      return;
    }

    members.remove(memberId);

    await ref.update({
      'members': members,
      'memberCount': members.length,
    });

    Get.snackbar('Success', 'Member removed');
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      final ref = _firestore.collection('groups').doc(groupId);

      // Delete all expenses in the group
      final expenses = await ref.collection('expenses').get();
      for (var doc in expenses.docs) {
        await doc.reference.delete();
      }

      // Delete the group
      await ref.delete();
      
      Get.snackbar('Success', 'Group deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete group');
    }
  }

  // ───────────────────────── CLEANUP ─────────────────────────
  @override
  void onClose() {
    _groupSubscription?.cancel();
    _authStateSubscription.cancel();
    super.onClose();
  }
}