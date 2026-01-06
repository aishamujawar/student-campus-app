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
    final theme = Theme.of(context);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = controller.user.value;
            if (user == null) {
              return const Center(child: Text('Profile not found'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.9,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.96),
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 30,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(theme),
                            const SizedBox(height: 20),
                            _buildProfileHero(context, controller),
                            const SizedBox(height: 24),
                            _buildInfoCard(
                              icon: Icons.email_rounded,
                              label: 'Email',
                              value: user.email,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoCard(
                              icon: Icons.phone_rounded,
                              label: 'Phone',
                              value: user.phone.isEmpty
                                  ? 'Not provided'
                                  : user.phone,
                            ),
                            const SizedBox(height: 28),
                            _buildActions(),
                            const SizedBox(height: 24),
                            _buildDangerZone(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  // 🔹 Header (Home-style)
  Widget _buildHeader(ThemeData theme) {
    return Row(
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
            Icons.person_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // 🔹 Profile hero with change picture option
  Widget _buildProfileHero(
    BuildContext context,
    ProfileController controller,
  ) {
    final user = controller.user.value!;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Get.bottomSheet(
              _ChangeAvatarSheet(),
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            );
          },
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4FC3F7),
                      Color(0xFF7E8BFF),
                    ],
                  ),
                ),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white,
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4C5D73),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF3AA8F7),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          user.fullName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF16222C),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Campus App User',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF7A8A9C),
          ),
        ),
      ],
    );
  }

  // 🔹 Info card
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFF4F7FB),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF3AA8F7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7A8A9C),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Actions
  Widget _buildActions() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.edit_rounded),
          title: const Text('Edit Profile'),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          onTap: () => Get.to(() => const EditProfilePage()),
        ),
        ListTile(
          leading: const Icon(Icons.lock_rounded),
          title: const Text('Change Password'),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          onTap: () {
            Get.snackbar(
              'Coming soon',
              'Password change will be added soon.',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),
      ],
    );
  }

  // 🔥 Danger zone
  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text(
          'Danger zone',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.redAccent,
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text(
            'Logout',
            style: TextStyle(color: Colors.redAccent),
          ),
          onTap: () async {
            await AuthRepository.instance.logout();
          },
        ),
      ],
    );
  }
}

/// 🔹 Bottom sheet for avatar change (UI-only, backend-safe)
class _ChangeAvatarSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Change profile picture',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Choose from gallery'),
            onTap: () {
              Get.back();
              Get.snackbar(
                'Not connected yet',
                'Gallery upload can be wired to Firebase Storage.',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_rounded),
            title: const Text('Remove picture'),
            onTap: () {
              Get.back();
              Get.snackbar(
                'Removed',
                'Profile picture removed.',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
    );
  }
}