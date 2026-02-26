import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // IMPORT ADDED
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/chatbot_service.dart';

class CampusAssistantScreen extends StatefulWidget {
  const CampusAssistantScreen({super.key});

  @override
  State<CampusAssistantScreen> createState() =>
      _CampusAssistantScreenState();
}

class _CampusAssistantScreenState extends State<CampusAssistantScreen> {
  static const int maxMessages = 20;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _chatbotService = ChatbotService();

  final TextEditingController _messageController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final RxBool _isAssistantTyping = false.obs;
  final RxList<_ChatMessage> _messages = <_ChatMessage>[].obs;

  String get _uid => _auth.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ───────────────────────── FIRESTORE ─────────────────────────

  Future<void> _loadChatHistory() async {
    final doc =
        await _db.collection('chat_history').doc(_uid).get();

    if (!doc.exists || doc.data()?['messages'] == null) {
      _messages.add(
        const _ChatMessage(
          role: MessageRole.assistant,
          text:
              'Hi! I\'m your Campus Assistant.\n\nI can help you with:\n• Classes & Timetable\n• Assignments & Deadlines\n• CGPA & Grades\n• Calendar Events\n\nTry asking: "Do I have class tomorrow?"',
        ),
      );
      return;
    }

    final List data = doc.data()!['messages'];

    _messages.assignAll(
      data.map(
        (m) => _ChatMessage(
          role: m['role'] == 'user'
              ? MessageRole.user
              : MessageRole.assistant,
          text: m['text'],
        ),
      ),
    );

    _scrollToBottom();
  }

  Future<void> _saveMessagesToFirestore() async {
    final trimmed = _messages
        .where((m) => m.role != MessageRole.typing)
        .takeLast(maxMessages)
        .map((m) => {
              'role': m.role == MessageRole.user
                  ? 'user'
                  : 'assistant',
              'text': m.text,
              'createdAt': DateTime.now().toIso8601String(),
            })
        .toList();

    await _db.collection('chat_history').doc(_uid).set({
      'messages': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ───────────────────────── CHAT LOGIC ─────────────────────────

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isAssistantTyping.value) return;

    _messages.add(
      _ChatMessage(role: MessageRole.user, text: text),
    );
    _messageController.clear();

    _isAssistantTyping.value = true;
    _messages.add(const _ChatMessage(role: MessageRole.typing));

    _scrollToBottom();
    _saveMessagesToFirestore();

    // 🔥 USING THE NEW DATA-AWARE CHATBOT SERVICE
    _chatbotService.askBot(text).then((reply) {
      _messages.removeWhere((m) => m.role == MessageRole.typing);

      _messages.add(
        _ChatMessage(
          role: MessageRole.assistant,
          text: reply,
        ),
      );

      _isAssistantTyping.value = false;
      _scrollToBottom();
      _saveMessagesToFirestore();
    }).catchError((error) {
      _messages.removeWhere((m) => m.role == MessageRole.typing);

      _messages.add(
        _ChatMessage(
          role: MessageRole.assistant,
          text: error.toString().contains('Failed host lookup')
              ? 'I\'m having trouble connecting to the server. Please check your backend is running on http://localhost:3000'
              : 'Sorry, I encountered an error while fetching your data: ${error.toString()}',
        ),
      );

      _isAssistantTyping.value = false;
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE7F2FF),
              Color(0xFFD8F7F8),
            ],
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
                  child: _card(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card() => Container(
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

  Widget _header() => Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF3AA8F7),
                  Color(0xFF47D6C4),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Campus Assistant',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          // No close button - removed as requested
        ],
      );

  Widget _chatArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Welcome section at the top (only when no messages)
        Obx(() {
          if (_messages.isNotEmpty && _messages.length > 1) {
            return const SizedBox.shrink();
          }
          
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can I help you today?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF16222C),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'I can access your:\n• Timetable • Assignments • CGPA • Calendar',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF7A8A9C),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        }),
        
        // Chat messages area - Fixed height container
        Container(
          height: 500, // Fixed height to prevent unbounded constraints
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Obx(() {
            if (_messages.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF3AA8F7),
                            Color(0xFF47D6C4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Campus AI Assistant',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: const Color(0xFF16222C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Ask about classes, assignments, CGPA, or calendar events',
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
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _ChatBubble(message: _messages[index]);
              },
            );
          }),
        ),
        
        const SizedBox(height: 16),
        
        // Input bar with Enter key support
        _inputBar(),
      ],
    );
  }

  // FIXED: Enter sends message, Shift+Enter adds new line
  Widget _inputBar() {
    return Obx(() {
      return Container(
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
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (KeyEvent event) {
                  if (event is KeyDownEvent) {
                    // Check if Enter is pressed WITHOUT Shift
                    if (event.logicalKey == LogicalKeyboardKey.enter) {
                      // Check if Shift is not pressed
                      final shiftPressed = HardwareKeyboard.instance.isShiftPressed;
                      
                      if (!shiftPressed) {
                        // Enter without Shift -> send message
                        _sendMessage();
                      }
                      // If Shift+Enter, do nothing here (TextField will handle new line)
                    }
                  }
                },
                child: TextField(
                  controller: _messageController,
                  enabled: !_isAssistantTyping.value,
                  maxLines: 5,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline, // Shows return key
                  decoration: InputDecoration(
                    hintText: _isAssistantTyping.value
                        ? 'Assistant is analyzing your data...'
                        : 'Ask about classes, assignments, CGPA...',
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    hintStyle: TextStyle(
                      color: const Color(0xFF7A8A9C),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isAssistantTyping.value ? null : _sendMessage,
              child: Opacity(
                opacity: _isAssistantTyping.value ? 0.4 : 1,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF3AA8F7),
                        Color(0xFF47D6C4),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ───────────────────────── MODELS & WIDGETS ─────────────────────────

enum MessageRole { user, assistant, typing }

class _ChatMessage {
  final MessageRole role;
  final String? text;

  const _ChatMessage({required this.role, this.text});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.role == MessageRole.typing) {
      return const _TypingBubble();
    }

    final isUser = message.role == MessageRole.user;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment:
            isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            color: isUser
                ? const Color(0xFF3AA8F7)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isUser
                ? [
                    BoxShadow(
                      color: const Color(0xFF3AA8F7).withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isUser)
                Row(
                  children: [
                    Icon(
                      Icons.smart_toy_rounded,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Assistant',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              Text(
                message.text ?? '',
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : const Color(0xFF16222C),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// BETTER LOADING ANIMATION
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Create three dots with staggered animations
    _animations = List.generate(3, (index) {
      return Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.15,
            (index * 0.15) + 0.5,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated dots
              Row(
                children: List.generate(3, (index) {
                  return AnimatedBuilder(
                    animation: _animations[index],
                    builder: (context, child) {
                      return Opacity(
                        opacity: _animations[index].value,
                        child: Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF3AA8F7),
                                Color(0xFF47D6C4),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                'Assistant is thinking',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  Iterable<T> takeLast(int n) =>
      skip(length - n < 0 ? 0 : length - n);
}