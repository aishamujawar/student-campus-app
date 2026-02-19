import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// =====================================================
// IMPORT YOUR REAL CONTROLLERS AND MODELS
// =====================================================
import 'controllers/expense_controller.dart';
import 'controllers/group_controller.dart';
import 'models/expense_model.dart';

// =====================================================
// GROUP DETAIL PAGE (LIKE CGPA/ASSIGNMENTS PAGE)
// =====================================================

class GroupDetailPage extends StatefulWidget {
  final String groupId;
  final Map<String, dynamic> groupData;

  const GroupDetailPage({
    super.key,
    required this.groupId,
    required this.groupData,
  });

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final ExpenseController _expenseController = Get.find<ExpenseController>();
  final GroupController _groupController = Get.find<GroupController>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RxMap<String, String> _memberNames = <String, String>{}.obs;
  
  late String _currentUserId;
  bool _isCreator = false;
  bool _loading = true;
  bool _handledDeletion = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser!.uid;
    _isCreator = widget.groupData['createdBy'] == _currentUserId;
    _expenseController.fetchExpenses(widget.groupId);
    _loadData();
  }

  Future<void> _loadData() async {
    final members = List<String>.from(widget.groupData['members'] ?? []);
    await _ensureMemberNames(members);
    setState(() => _loading = false);
  }

  Future<void> _ensureMemberNames(List<String> memberIds) async {
    for (final uid in memberIds) {
      if (_memberNames.containsKey(uid)) continue;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final fullName = doc.data()?['fullName'] ?? 'User';
      _memberNames[uid] = fullName.toString().split(' ').first;
    }
  }

  // ===== ADD EXPENSE BOTTOM SHEET =====
  void _openAddExpenseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddExpenseSheet(groupId: widget.groupId),
    );
  }

  // ===== ADD MEMBER DIALOG =====
  void _showAddMemberDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Add Member'),
          content: TextField(
            controller: emailController,
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
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  _showErrorSnackbar('Please enter an email');
                  return;
                }
                
                // Try to add member and catch any errors
                try {
                  await _groupController.addMemberToGroup(widget.groupId, email);
                  Navigator.pop(context);
                } catch (e) {
                  _showErrorSnackbar('User not found with this email');
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        content: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFEF5350),
                    size: 26,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: Color(0xFF16222C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== DELETE GROUP CONFIRMATION =====
  void _confirmDeleteGroup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Delete Group?'),
          content: const Text(
            'This will permanently delete the group and all its expenses.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteGroup();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteGroup() async {
    await _groupController.deleteGroup(widget.groupId);
    Navigator.pop(context);
  }

  Future<void> _settleUp() async {
    await _expenseController.settleGroup(widget.groupId);
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
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('groups')
                .doc(widget.groupId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasData &&
                  snapshot.data != null &&
                  !snapshot.data!.exists) {
                if (!_handledDeletion) {
                  _handledDeletion = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pop(context);
                  });
                }
                return const SizedBox.shrink();
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return _errorState();
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final members = List<String>.from(data['members'] ?? []);
              final Timestamp? ts = data['lastSettledAt'];
              final DateTime? lastSettledAt = ts?.toDate();

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: FractionallySizedBox(
                    widthFactor: 0.85,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: _card(context, data, members, lastSettledAt),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> data, 
      List<String> members, DateTime? lastSettledAt) {
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
          _header(data['name'] ?? 'Group'),
          const SizedBox(height: 16),
          _loading ? _loadingState() : _content(members, lastSettledAt),
        ],
      ),
    );
  }

  Widget _header(String groupName) => Row(
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
      Expanded(
        child: Text(
          groupName,
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
            'Loading group details...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(List<String> members, DateTime? lastSettledAt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== BALANCE CARD =====
        Obx(() {
          final balances = _expenseController.calculateBalances(
            members: members,
            lastSettledAt: lastSettledAt,
          );
          final yourBalance = balances[_currentUserId] ?? 0.0;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(
                  yourBalance == 0
                      ? 'You are settled up'
                      : yourBalance > 0
                          ? 'You will receive'
                          : 'You owe',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: yourBalance == 0
                        ? const Color(0xFF57E4C9)
                        : yourBalance > 0
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFEF5350),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  yourBalance == 0
                      ? '₹0.00'
                      : '₹${yourBalance.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: yourBalance == 0
                        ? const Color(0xFF57E4C9)
                        : yourBalance > 0
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFEF5350),
                  ),
                ),
              ],
            ),
          );
        }),

        // ===== MEMBERS SECTION =====
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Members',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              if (_isCreator)
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: _showAddMemberDialog,
                ),
            ],
          ),
        ),

        Obx(() {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: members.map((uid) {
              final name = uid == _currentUserId
                  ? 'You'
                  : _memberNames[uid] ?? 'Member';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: uid == _currentUserId
                      ? const Color(0xFF3AA8F7).withOpacity(0.1)
                      : const Color(0xFFF4F7FB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: uid == _currentUserId
                        ? const Color(0xFF3AA8F7)
                        : const Color(0xFFE0E6F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: uid == _currentUserId
                            ? const Color(0xFF3AA8F7)
                            : const Color(0xFF4C5D73),
                      ),
                    ),
                    if (_isCreator && uid != _currentUserId)
                      GestureDetector(
                        onTap: () => _groupController.removeMemberFromGroup(
                            widget.groupId, uid),
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
          );
        }),

        const SizedBox(height: 20),

        // ===== ADD EXPENSE BUTTON =====
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openAddExpenseSheet,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Expense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3AA8F7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),

        // ===== SETTLE UP BUTTON =====
        if (_isCreator)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _settleUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF57E4C9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Settle Up',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

        if (lastSettledAt != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Last settled: ${DateFormat('dd MMM yyyy').format(lastSettledAt)}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9AA6B5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        const SizedBox(height: 20),

        // ===== EXPENSES LIST =====
        const Text(
          'Recent Expenses',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),

        Obx(() {
          if (_expenseController.expenses.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 32,
                    color: Color(0xFF9AA6B5),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No expenses yet',
                    style: TextStyle(
                      color: Color(0xFF7A8A9C),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add your first expense above',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9AA6B5),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: _expenseController.expenses.map((expense) {
              final paidByYou = expense.paidBy == _currentUserId;
              final paidByName = paidByYou
                  ? 'You'
                  : _memberNames[expense.paidBy] ?? 'Member';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: paidByYou
                            ? const Color(0xFF3AA8F7).withOpacity(0.1)
                            : const Color(0xFF55D7C7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        paidByYou ? Icons.upload_rounded : Icons.download_rounded,
                        size: 18,
                        color: paidByYou
                            ? const Color(0xFF3AA8F7)
                            : const Color(0xFF55D7C7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Paid by $paidByName • ${DateFormat('dd MMM').format(expense.createdAt)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7A8A9C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${expense.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF3AA8F7),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }),

        if (_isCreator)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _confirmDeleteGroup,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF5350),
                ),
                child: const Text(
                  'Delete Group',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _errorState() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        borderRadius: BorderRadius.circular(32),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Color(0xFFEF5350),
          ),
          SizedBox(height: 16),
          Text(
            'Unable to load group',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFFEF5350),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// ADD EXPENSE BOTTOM SHEET
// =====================================================

class _AddExpenseSheet extends StatefulWidget {
  final String groupId;
  
  const _AddExpenseSheet({required this.groupId});
  
  @override
  State<_AddExpenseSheet> createState() => __AddExpenseSheetState();
}

class __AddExpenseSheetState extends State<_AddExpenseSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final ExpenseController _expenseController = Get.find<ExpenseController>();
  
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  String? _errorText;
  
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }
  
  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final rawAmount = _amountController.text.trim();
    
    if (title.isEmpty || rawAmount.isEmpty) {
      setState(() {
        _errorText = 'Please fill all fields';
      });
      return;
    }
    
    final amount = double.tryParse(rawAmount);
    if (amount == null) {
      setState(() {
        _errorText = 'Invalid amount';
      });
      return;
    }
    
    if (amount <= 0) {
      setState(() {
        _errorText = 'Amount must be greater than 0';
      });
      return;
    }
    
    setState(() {
      _loading = true;
      _errorText = null;
    });
    
    try {
      await _expenseController.addExpense(
        groupId: widget.groupId,
        title: title,
        amount: amount,
        createdAt: _selectedDate,
      );
      
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorText = 'Failed to add expense';
      });
    } finally {
      setState(() => _loading = false);
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
            'Add Expense',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _titleController,
            onChanged: (value) => setState(() => _errorText = null),
            decoration: InputDecoration(
              labelText: 'Title',
              filled: true,
              fillColor: const Color(0xFFF4F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            onChanged: (value) => setState(() => _errorText = null),
            decoration: InputDecoration(
              labelText: 'Amount',
              filled: true,
              fillColor: const Color(0xFFF4F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: Color(0xFF7A8A9C),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('dd MMM yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
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
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3AA8F7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Add Expense',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}