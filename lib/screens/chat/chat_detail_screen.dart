import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'controllers/chat_controller.dart';
import 'models/chat_message_model.dart';

class ChatDetailScreen extends StatefulWidget {
  final String groupId;
  final Map<String, dynamic> groupData;
  
  const ChatDetailScreen({
    super.key,
    required this.groupId,
    required this.groupData,
  });
  
  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late String _currentUserId;
  late List<String> _members;
  final Map<String, String> _memberNames = {};
  bool _isCreator = false;
  
  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser!.uid;
    _members = List<String>.from(widget.groupData['members'] ?? []);
    _isCreator = widget.groupData['createdBy'] == _currentUserId;
    _loadMemberNames();
    _chatController.fetchMessages(widget.groupId);
  }
  
  Future<void> _loadMemberNames() async {
    for (final uid in _members) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final fullName = doc.data()?['fullName'] ?? 'User';
      _memberNames[uid] = fullName.toString().split(' ').first;
    }
    setState(() {});
  }
  
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    _chatController.sendMessage(
      groupId: widget.groupId,
      message: message,
    );
    _messageController.clear();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _GroupInfoSheet(
        groupId: widget.groupId,
        groupName: widget.groupData['name'],
        members: _members,
        memberNames: _memberNames,
        currentUserId: _currentUserId,
        isCreator: _isCreator,
        onMemberAdded: () => _loadMemberNames(),
      ),
    );
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatController.cancelListener();
    super.dispose();
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
                widthFactor: 0.9,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(),
          const SizedBox(height: 16),
          _chatArea(),
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
      Expanded(
        child: Text(
          widget.groupData['name'] ?? 'Chat Group',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.pop(context),
      ),
    ],
  );
  
  Widget _chatArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Member count and group info button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3AA8F7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.group_rounded,
                  size: 18,
                  color: Color(0xFF3AA8F7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_members.length} member${_members.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF16222C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Messages auto-delete after 7 days',
                      style: TextStyle(
                        fontSize: 10,
                        color: const Color(0xFF7A8A9C),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Color(0xFF3AA8F7),
                  ),
                  onPressed: _showGroupInfo,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Chat messages area
        Container(
          height: 450,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Obx(() {
            if (_chatController.messages.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3AA8F7), Color(0xFF47D6C4)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No messages yet',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF16222C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Be the first to send a message!\nMessages automatically delete after 7 days.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF7A8A9C),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: _chatController.messages.length,
              itemBuilder: (context, index) {
                final message = _chatController.messages[index];
                final isMe = message.senderId == _currentUserId;
                
                return _MessageBubble(
                  message: message,
                  isMe: isMe,
                  senderName: message.senderName,
                );
              },
            );
          }),
        ),
        
        const SizedBox(height: 16),
        
        // Message input bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FB),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE0E6F0),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  maxLines: 5,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onSubmitted: (value) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF3AA8F7), Color(0xFF47D6C4)],
                    ),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── MESSAGE BUBBLE ─────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final String senderName;
  
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.senderName,
  });
  
  @override
  Widget build(BuildContext context) {
    final timeLeft = message.expiresAt.difference(DateTime.now());
    final isExpiring = timeLeft.inDays < 1;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  senderName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5A6A7A),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                // Changed from gradient to solid blue color
                color: isMe ? const Color(0xFF3AA8F7) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : const Color(0xFF16222C),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.createdAt),
                        style: TextStyle(
                          fontSize: 9,
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey[500],
                        ),
                      ),
                      if (isExpiring) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.white.withOpacity(0.7)
                                : const Color(0xFFEF5350),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Expires soon',
                          style: TextStyle(
                            fontSize: 8,
                            color: isMe
                                ? Colors.white.withOpacity(0.7)
                                : const Color(0xFFEF5350),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── GROUP INFO SHEET ─────────────────────────
class _GroupInfoSheet extends StatefulWidget {
  final String groupId;
  final String groupName;
  final List<String> members;
  final Map<String, String> memberNames;
  final String currentUserId;
  final bool isCreator;
  final VoidCallback onMemberAdded;
  
  const _GroupInfoSheet({
    required this.groupId,
    required this.groupName,
    required this.members,
    required this.memberNames,
    required this.currentUserId,
    required this.isCreator,
    required this.onMemberAdded,
  });
  
  @override
  State<_GroupInfoSheet> createState() => __GroupInfoSheetState();
}

class __GroupInfoSheetState extends State<_GroupInfoSheet> {
  final ChatController _chatController = Get.find<ChatController>();
  final TextEditingController _emailController = TextEditingController();
  
  void _addMember() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    
    await _chatController.addMemberToGroup(widget.groupId, email);
    _emailController.clear();
    widget.onMemberAdded();
    Navigator.pop(context);
    _showAddMemberSheet();
  }
  
  void _showAddMemberSheet() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Add Member'),
        content: TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Member email',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addMember,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  void _leaveGroup() async {
    Navigator.pop(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Leave Group?'),
        content: const Text('You will no longer see messages from this group.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _chatController.leaveGroup(widget.groupId);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E6F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3AA8F7), Color(0xFF47D6C4)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.chat_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.groupName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Members',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              if (widget.isCreator)
                IconButton(
                  icon: const Icon(Icons.person_add_rounded),
                  onPressed: _showAddMemberSheet,
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.members.map((uid) {
            final name = uid == widget.currentUserId
                ? 'You'
                : widget.memberNames[uid] ?? 'Member';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3AA8F7).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3AA8F7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.isCreator && uid != widget.currentUserId)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded,
                          size: 18, color: Colors.red),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _chatController.leaveGroup(widget.groupId);
                      },
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _leaveGroup,
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Leave Group'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}