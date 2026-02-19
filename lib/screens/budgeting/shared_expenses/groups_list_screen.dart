import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:student_campus_app/screens/budgeting/shared_expenses/group_detail_screen.dart';

// =====================================================
// IMPORT YOUR REAL CONTROLLERS
// =====================================================
import 'controllers/group_controller.dart';

// =====================================================
// GROUPS LIST PAGE (MAIN PAGE - LIKE CGPA/ASSIGNMENTS)
// =====================================================

class GroupsListPage extends StatefulWidget {
  const GroupsListPage({super.key});

  @override
  State<GroupsListPage> createState() => _GroupsListPageState();
}

class _GroupsListPageState extends State<GroupsListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserId;
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _loading = false);
  }
  
  // ===== CREATE GROUP BOTTOM SHEET =====
  void _openCreateGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateGroupSheet(),
    );
  }
  
  // ===== GROUP DETAIL PAGE =====
  void _openGroupDetailPage(String groupId, Map<String, dynamic> groupData) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupDetailPage(
          groupId: groupId,
          groupData: groupData,
        ),
      ),
    );
  }
  
  // =====================================================
  // UI BUILD
  // =====================================================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE7F2FF), Color(0xFFD8F7F8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FractionallySizedBox(
                widthFactor: 0.85,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: _card(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _card(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 16),
          _loading ? _loadingState() : _content(),
        ],
      ),
    );
  }
  
  Widget _header() => Row(
    children: [
      Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [Color(0xFF4CBBD1), Color(0xFF57E4C9)],
          ),
        ),
        child: const Icon(
          Icons.groups_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
      const SizedBox(width: 8),
      const Text(
        'Shared Expenses',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      const Spacer(),
      IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.pop(context),
      ),
    ],
  );
  
  Widget _loadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF3AA8F7),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your groups...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _content() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: _currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingState();
        }
        
        if (snapshot.hasError) {
          return _errorState();
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState();
        }
        
        final groups = snapshot.data!.docs;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Groups',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF16222C),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${groups.length} group${groups.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7A8A9C),
              ),
            ),
            const SizedBox(height: 16),
            ...groups.map((group) {
              final data = group.data() as Map<String, dynamic>;
              final members = (data['members'] ?? []) as List;
              
              return _groupCard(group.id, data, members.length);
            }).toList(),
            
            // ===== ADD ANOTHER GROUP BUTTON =====
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openCreateGroupSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3AA8F7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Add Another Group',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _groupCard(String groupId, Map<String, dynamic> data, int memberCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFF4F7FB),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openGroupDetailPage(groupId, data),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3AA8F7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Color(0xFF3AA8F7),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Unnamed Group',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF16222C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$memberCount member${memberCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7A8A9C),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF9AA6B5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _emptyState() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FB),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.groups_outlined,
                size: 48,
                color: Color(0xFF9AA6B5),
              ),
              const SizedBox(height: 12),
              const Text(
                'No groups yet',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF4C5D73),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a group to start sharing expenses',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF7A8A9C),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _openCreateGroupSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3AA8F7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Create Group',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _errorState() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3F3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFEF5350).withOpacity(0.3),
            ),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFEF5350),
              ),
              SizedBox(height: 12),
              Text(
                'Unable to load groups',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEF5350),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please check your connection and try again',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF7A8A9C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================
// CREATE GROUP BOTTOM SHEET
// =====================================================

class _CreateGroupSheet extends StatefulWidget {
  @override
  State<_CreateGroupSheet> createState() => __CreateGroupSheetState();
}

class __CreateGroupSheetState extends State<_CreateGroupSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final GroupController _groupController = Get.find<GroupController>();
  String? _errorText;
  
  Future<void> _addMember() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorText = 'Please enter an email';
      });
      return;
    }
    
    // Try to add member and catch any errors
    try {
      await _groupController.addMemberByEmail(email);
      setState(() {
        _errorText = null;
      });
      _emailController.clear();
    } catch (e) {
      setState(() {
        _errorText = 'User not found with this email';
      });
    }
  }
  
  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorText = 'Please enter a group name';
      });
      return;
    }

    if (_groupController.selectedMembers.isEmpty) {
      setState(() {
        _errorText = 'Please add at least one member';
      });
      return;
    }
    
    // Try to create group and catch any errors
    try {
      await _groupController.createGroup(name);
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorText = 'Failed to create group';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 36,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E6F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Create Group',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _nameController,
            onChanged: (value) => setState(() => _errorText = null),
            decoration: InputDecoration(
              labelText: 'Group name',
              filled: true,
              fillColor: const Color(0xFFF4F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Member email field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  onChanged: (value) => setState(() => _errorText = null),
                  decoration: InputDecoration(
                    labelText: 'Add member email',
                    filled: true,
                    fillColor: const Color(0xFFF4F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addMember,
                icon: const Icon(Icons.person_add_rounded),
              ),
            ],
          ),

          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorText!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Selected members list
          Obx(() {
            if (_groupController.selectedMembers.isEmpty) {
              return const SizedBox(height: 12);
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Selected Members:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A8A9C),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _groupController.selectedMembers.map((member) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3AA8F7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            member['email'] ?? 'User',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3AA8F7),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _groupController.removeMember(member['uid']),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Color(0xFF9AA6B5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          }),
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _createGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3AA8F7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Create Group',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}