import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/profile_controller.dart';
import '../../repository/authentication_repository.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

    return SafeArea(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = controller.user.value;
        if (user == null) {
          return const Center(child: Text('Profile not found'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 24),

              /// Avatar
              CircleAvatar(
                radius: 44,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              /// Name
              Text(
                user.fullName,
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 4),

              /// Email & Phone
              Text(user.email),
              Text(user.phone),

              const SizedBox(height: 32),

              /// Edit Profile
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Profile'),
                onTap: () => Get.to(() => const EditProfilePage()),
              ),

              /// Logout
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await AuthRepository.instance.logout();
                  // 🚫 NO navigation here
                  // AuthRepository handles redirect to WelcomeScreen
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}
