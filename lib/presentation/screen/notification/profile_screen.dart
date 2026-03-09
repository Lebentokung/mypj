import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/core/services/profile_service.dart';
import 'package:flutter_application_2/core/theme/app_colors.dart';
import 'package:flutter_application_2/presentation/screen/auth/login_screen.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.username});

  final String username;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final ProfileService _profileService = ProfileService();
  File? _profileImage;
  String? _profileImageUrl;
  late String _displayName;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _displayName = widget.username;
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final profileData = await _profileService.getProfileData();
      if (!mounted) {
        return;
      }
      setState(() {
        _profileImageUrl = profileData['profileImageUrl'];
        _displayName = profileData['displayName']?.trim().isNotEmpty == true
            ? profileData['displayName']!
            : widget.username;
      });
    } catch (_) {
      // Keep UI usable even when profile image lookup fails.
    }
  }

  String get _emailDisplay {
    if (widget.username.contains('@')) {
      return widget.username;
    }
    return '${widget.username}@gmail.com';
  }

  Future<void> _pickProfileImage() async {
    final selected = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _profileImage = File(selected.path);
      _isUploadingImage = true;
    });

    try {
      final imageUrl = await _profileService.uploadProfileImage(_profileImage!);
      if (!mounted) {
        return;
      }
      setState(() {
        _profileImageUrl = imageUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปโหลดรูปโปรไฟล์สำเร็จ')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'อัปโหลดรูปโปรไฟล์ไม่สำเร็จ')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _openEditProfileDialog() async {
    final controller = TextEditingController(text: _displayName);
    final updatedName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขโปรไฟล์'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'ชื่อที่แสดง',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (!mounted || updatedName == null || updatedName.isEmpty) {
      return;
    }

    try {
      await _profileService.updateDisplayName(updatedName);
      if (!mounted) {
        return;
      }
      setState(() {
        _displayName = updatedName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('แก้ไขโปรไฟล์สำเร็จ')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'แก้ไขโปรไฟล์ไม่สำเร็จ')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.success,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              _ProfileHeaderCard(
                username: _displayName,
                email: _emailDisplay,
                profileImage: _profileImage,
                profileImageUrl: _profileImageUrl,
                isUploadingImage: _isUploadingImage,
                onTapProfileImage: _pickProfileImage,
              ),
              const SizedBox(height: 20),
              _ProfileMenuCard(
                icon: Icons.edit,
                title: 'แก้ไขโปรไฟล์',
                onTap: _openEditProfileDialog,
              ),
              const SizedBox(height: 10),
              _ProfileMenuCard(
                icon: Icons.history,
                title: 'ประวัติการวางหมุด',
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _ProfileMenuCard(
                icon: Icons.logout,
                title: 'ออกจากระบบ',
                onTap: () async {
                  final navigator = Navigator.of(context);
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) {
                    return;
                  }
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.username,
    required this.email,
    required this.profileImage,
    required this.profileImageUrl,
    required this.isUploadingImage,
    required this.onTapProfileImage,
  });

  final String username;
  final String email;
  final File? profileImage;
  final String? profileImageUrl;
  final bool isUploadingImage;
  final VoidCallback onTapProfileImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTapProfileImage,
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: isUploadingImage
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : profileImage != null
                        ? Image.file(profileImage!, fit: BoxFit.cover)
                        : (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                            ? Image.network(
                                profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return const Icon(
                                    Icons.person,
                                    color: AppColors.textHint,
                                    size: 42,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.person,
                                color: AppColors.textHint,
                                size: 42,
                              ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.info,
                        fontSize: 14,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.success,
      borderRadius: BorderRadius.circular(4),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          child: Row(
            children: [
              Icon(icon, size: 36, color: AppColors.textPrimary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
