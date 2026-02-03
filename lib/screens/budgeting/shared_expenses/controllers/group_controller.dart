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
        .listen((snapshot) {
      groups.assignAll(
        snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList(),
      );
    });
  }

  // ───────────────────────── USER LOOKUP ─────────────────────────
  Future<Map<String, dynamic>?> _fetchUserByEmail(String email) async {
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
  }

  // ───────────────────────── CREATE GROUP FLOW ─────────────────────────

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

    await _firestore.collection('groups').add({
      'name': name.trim(),
      'members': memberIds,
      'memberCount': memberIds.length,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    selectedMembers.clear();
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

    final List members = List.from(snap['members']);

    if (members.contains(user['uid'])) return;

    members.add(user['uid']);

    await ref.update({
      'members': members,
      'memberCount': members.length,
    });
  }

  Future<void> removeMemberFromGroup(String groupId, String memberId) async {
    final ref = _firestore.collection('groups').doc(groupId);
    final snap = await ref.get();

    final List members = List.from(snap['members']);
    members.remove(memberId);

    if (members.length < 2) {
      Get.snackbar('Error', 'Group must have at least 2 members');
      return;
    }

    await ref.update({
      'members': members,
      'memberCount': members.length,
    });
  }

  Future<void> deleteGroup(String groupId) async {
    final ref = _firestore.collection('groups').doc(groupId);

    final expenses = await ref.collection('expenses').get();
    for (var doc in expenses.docs) {
      await doc.reference.delete();
    }

    await ref.delete();
  }

  // ───────────────────────── CLEANUP ─────────────────────────
  @override
  void onClose() {
    _groupSubscription?.cancel();
    super.onClose();
  }
}
