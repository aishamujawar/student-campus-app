import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../controllers/main_shell_controller.dart';
import 'controllers/chat_controller.dart';
import 'chat_detail_screen.dart';

class ChatGroupsListScreen extends StatefulWidget {
  const ChatGroupsListScreen({super.key});

  @override
  State<ChatGroupsListScreen> createState() => _ChatGroupsListScreenState();
}

class _ChatGroupsListScreenState extends State<ChatGroupsListScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final MainShellController _shellController = Get.find<MainShellController>();
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
    // ✅ Check if widget is still mounted before calling setState
    if (mounted) {
      setState(() => _loading = true);
    }
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    // ✅ Check if widget is still mounted before calling setState again
    if (mounted) {
      setState(() => _loading = false);
    }
  }
  
  void _openCreateGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateChatGroupSheet(),
    );
  }
  
  void _openChatDetail(String groupId, ChatGroupModel group) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          groupId: groupId,
          groupData: {
            'name': group.name,
            'members': group.members,
            'createdBy': group.createdBy,
          },
        ),
      ),
    );
  }
  
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
          Icons.chat_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
      const SizedBox(width: 8),
      const Text(
        'Chat Groups',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      const Spacer(),
      IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () {
          // Use MainShellController to go back to Home (index 0)
          _shellController.changeTab(0);
        },
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
            'Loading your chats...',
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
    return Obx(() {
      if (_chatController.chatGroups.isEmpty) {
        return _emptyState();
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Chats',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF16222C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_chatController.chatGroups.length} group${_chatController.chatGroups.length == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7A8A9C),
            ),
          ),
          const SizedBox(height: 16),
          ..._chatController.chatGroups.map((group) {
            return _groupCard(group);
          }).toList(),
          
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
                'Create New Group',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
  
  Widget _groupCard(ChatGroupModel group) {
    final isMember = group.members.contains(_currentUserId);
    if (!isMember) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFF4F7FB),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openChatDetail(group.id, group),
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
                    Icons.chat_bubble_rounded,
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
                        group.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF16222C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group.lastMessage != null
                            ? (group.lastMessage!.length > 40
                                ? '${group.lastMessage!.substring(0, 40)}...'
                                : group.lastMessage!)
                            : 'No messages yet',
                        style: TextStyle(
                          fontSize: 12,
                          color: group.lastMessage != null
                              ? const Color(0xFF5A6A7A)
                              : const Color(0xFF9AA6B5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (group.lastMessageTime != null)
                  Text(
                    _formatTime(group.lastMessageTime!),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9AA6B5),
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF9AA6B5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
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
                Icons.chat_outlined,
                size: 48,
                color: Color(0xFF9AA6B5),
              ),
              const SizedBox(height: 12),
              const Text(
                'No chat groups yet',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF4C5D73),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a group to start chatting',
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
  
  @override
  void dispose() {
    // Clean up any resources
    super.dispose();
  }
}

// ───────────────────────── CREATE GROUP SHEET ─────────────────────────
class _CreateChatGroupSheet extends StatefulWidget {
  @override
  State<_CreateChatGroupSheet> createState() => __CreateChatGroupSheetState();
}

class __CreateChatGroupSheetState extends State<_CreateChatGroupSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final ChatController _chatController = Get.find<ChatController>();
  String? _errorText;
  
  Future<void> _addMember() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      // ✅ Check mounted before setState
      if (mounted) {
        setState(() => _errorText = 'Please enter an email');
      }
      return;
    }
    
    try {
      await _chatController.addMemberByEmail(email);
      // ✅ Check mounted before setState
      if (mounted) {
        setState(() => _errorText = null);
        _emailController.clear();
      }
    } catch (e) {
      // ✅ Check mounted before setState
      if (mounted) {
        setState(() => _errorText = 'User not found with this email');
      }
    }
  }
  
  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      // ✅ Check mounted before setState
      if (mounted) {
        setState(() => _errorText = 'Please enter a group name');
      }
      return;
    }
    
    if (_chatController.selectedMembers.isEmpty) {
      // ✅ Check mounted before setState
      if (mounted) {
        setState(() => _errorText = 'Please add at least one member');
      }
      return;
    }
    
    try {
      await _chatController.createGroup(name);
      // ✅ Check mounted before popping
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // ✅ Check mounted before setState
      if (mounted) {
        setState(() => _errorText = 'Failed to create group');
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
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
            'Create Chat Group',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _nameController,
            onChanged: (value) {
              // ✅ Check mounted before setState
              if (mounted) {
                setState(() => _errorText = null);
              }
            },
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
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  onChanged: (value) {
                    // ✅ Check mounted before setState
                    if (mounted) {
                      setState(() => _errorText = null);
                    }
                  },
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
          
          Obx(() {
            if (_chatController.selectedMembers.isEmpty) {
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
                  children: _chatController.selectedMembers.map((member) {
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
                            onTap: () => _chatController.removeMember(member['uid']),
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