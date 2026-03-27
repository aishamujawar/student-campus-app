import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'dart:html' as html; // For web file handling

import '../models/user_model.dart';

class ProfileController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();
  
  late final StreamSubscription<User?> _authStateSubscription;

  final user = Rxn<UserModel>();
  final isLoading = false.obs;
  final isUploadingImage = false.obs;

  @override
  void onInit() {
    super.onInit();
    _authStateSubscription = _auth.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser != null) {
        fetchUser();
      } else {
        _clearUserData();
      }
    });
  }
  
  void _clearUserData() {
    user.value = null;
    isLoading.value = false;
  }

  Future<void> fetchUser() async {
    final uid = _auth.currentUser?.uid;
    
    if (uid == null) {
      _clearUserData();
      return;
    }

    if (isLoading.value) return;

    try {
      isLoading.value = true;

      final doc = await _db.collection('users').doc(uid).get();
      
      if (!doc.exists) {
        user.value = null;
        return;
      }

      user.value = UserModel.fromMap(doc.data()!);
    } catch (e) {
      user.value = null;
    } finally {
      if (_auth.currentUser?.uid == uid) {
        isLoading.value = false;
      }
    }
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    try {
      isLoading.value = true;

      await _db
          .collection('users')
          .doc(updatedUser.uid)
          .update(updatedUser.toMap());

      user.value = updatedUser;
      Get.snackbar('Success', 'Profile updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 📸 Upload profile picture - Works on both mobile and web
  Future<void> uploadProfilePicture(ImageSource source) async {
    try {
      isUploadingImage.value = true;
      
      Uint8List? imageBytes;
      String? fileName;
      
      if (kIsWeb) {
        // 🌐 WEB PLATFORM
        if (source == ImageSource.gallery) {
          // Pick image from gallery on web
          final mediaData = await ImagePickerWeb.getImageAsBytes();
          if (mediaData != null) {
            imageBytes = mediaData;
            fileName = 'web_upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
          } else {
            isUploadingImage.value = false;
            return;
          }
        } else {
          // Camera is not supported on web
          Get.snackbar(
            'Not Available',
            'Camera capture is not supported on web. Please use gallery instead.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
          isUploadingImage.value = false;
          return;
        }
      } else {
        // 📱 MOBILE PLATFORM
        final pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );
        
        if (pickedFile == null) {
          isUploadingImage.value = false;
          return;
        }
        
        final File imageFile = File(pickedFile.path);
        imageBytes = await imageFile.readAsBytes();
        fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      }
      
      if (imageBytes == null) {
        isUploadingImage.value = false;
        return;
      }
      
      final String uid = _auth.currentUser!.uid;
      
      // Create a unique filename
      final String storagePath = 'profile_pictures/$uid/$fileName';
      
      // Upload to Firebase Storage
      final Reference ref = _storage.ref().child(storagePath);
      
      // Upload bytes (works for both mobile and web)
      final UploadTask uploadTask = ref.putData(imageBytes);
      
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Update Firestore with new profile picture URL
      await _db.collection('users').doc(uid).update({
        'profilePictureUrl': downloadUrl,
      });
      
      // Update local user model
      final currentUser = user.value;
      if (currentUser != null) {
        user.value = UserModel(
          uid: currentUser.uid,
          fullName: currentUser.fullName,
          email: currentUser.email,
          phone: currentUser.phone,
          profilePictureUrl: downloadUrl,
        );
      }
      
      Get.snackbar(
        'Success',
        'Profile picture updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      
    } catch (e) {
      print('Error uploading image: $e');
      Get.snackbar(
        'Error',
        'Failed to upload profile picture. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isUploadingImage.value = false;
    }
  }
  
  /// 🗑️ Remove profile picture - Works on both mobile and web
  Future<void> removeProfilePicture() async {
    try {
      final currentUser = user.value;
      if (currentUser == null || currentUser.profilePictureUrl == null) return;
      
      isUploadingImage.value = true;
      
      final String uid = _auth.currentUser!.uid;
      
      // Delete from Firebase Storage (optional - you can keep old files)
      try {
        final Reference ref = _storage.refFromURL(currentUser.profilePictureUrl!);
        await ref.delete();
      } catch (e) {
        // File might not exist or already deleted, continue
        print('Error deleting old image: $e');
      }
      
      // Update Firestore - remove the URL
      await _db.collection('users').doc(uid).update({
        'profilePictureUrl': FieldValue.delete(),
      });
      
      // Update local user model
      user.value = UserModel(
        uid: currentUser.uid,
        fullName: currentUser.fullName,
        email: currentUser.email,
        phone: currentUser.phone,
        profilePictureUrl: null,
      );
      
      Get.snackbar(
        'Success',
        'Profile picture removed',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      
    } catch (e) {
      print('Error removing profile picture: $e');
      Get.snackbar(
        'Error',
        'Failed to remove profile picture',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isUploadingImage.value = false;
    }
  }
  
  Future<void> refreshUser() async {
    await fetchUser();
  }
  
  @override
  void onClose() {
    _authStateSubscription.cancel();
    super.onClose();
  }
}