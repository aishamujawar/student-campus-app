import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/group_controller.dart';

class CreateGroupScreen extends StatelessWidget {
  CreateGroupScreen({super.key});

  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final GroupController groupController = Get.find<GroupController>();

  Future<void> _addMember() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      Get.snackbar('Error', 'Please enter an email');
      return;
    }

    await groupController.addMemberByEmail(email);
    emailController.clear();
  }

  Future<void> _createGroup() async {
    final name = groupNameController.text.trim();

    if (name.isEmpty) {
      Get.snackbar('Error', 'Group name cannot be empty');
      return;
    }

    try {
      await groupController.createGroup(name);
      Get.back();
      Get.snackbar('Success', 'Group created successfully');
    } catch (_) {
      // error snackbar already handled in controller
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// GROUP NAME
            TextField(
              controller: groupNameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// ADD MEMBER BY EMAIL
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Add member by email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addMember,
                  icon: const Icon(Icons.person_add),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// SELECTED MEMBERS LIST
            Obx(() {
              if (groupController.selectedMembers.isEmpty) {
                return const Text(
                  'No members added yet',
                  style: TextStyle(color: Colors.grey),
                );
              }

              return Wrap(
                spacing: 8,
                runSpacing: 4,
                children: groupController.selectedMembers.map((member) {
                  return Chip(
                    label: Text(member['email'] ?? 'User'),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () =>
                        groupController.removeMember(member['uid']),
                  );
                }).toList(),
              );
            }),

            const Spacer(),

            /// CREATE GROUP BUTTON
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _createGroup,
                child: const Text('Create Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
