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
      if (!mounted) return;

      setState(() {
        _profileImageUrl = profileData['profileImageUrl'];
        _displayName = profileData['displayName']?.trim().isNotEmpty == true
            ? profileData['displayName']!
            : widget.username;
      });
    } catch (_) {}
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
    );

    if (!mounted || selected == null) return;

    setState(() {
      _profileImage = File(selected.path);
      _isUploadingImage = true;
    });

    try {
      final imageUrl = await _profileService.uploadProfileImage(_profileImage!);
      if (!mounted) return;

      setState(() {
        _profileImageUrl = imageUrl;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('อัปโหลดรูปโปรไฟล์สำเร็จ')));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'อัปโหลดรูปโปรไฟล์ไม่สำเร็จ')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปโหลดรูปโปรไฟล์ไม่สำเร็จ')),
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
          style: const TextStyle(fontSize: 16),
          decoration: const InputDecoration(labelText: 'ชื่อที่แสดง'),
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

    if (!mounted || updatedName == null || updatedName.isEmpty) return;

    try {
      await _profileService.updateDisplayName(updatedName);

      if (!mounted) return;

      setState(() {
        _displayName = updatedName;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('แก้ไขโปรไฟล์สำเร็จ')));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

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
        automaticallyImplyLeading: false,
        title: const Text('Profile'),
        backgroundColor: AppColors.success,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
              const SizedBox(height: 16),
              _ProfileMenuCard(
                icon: Icons.edit,
                title: 'แก้ไขโปรไฟล์',
                onTap: _openEditProfileDialog,
              ),
              const SizedBox(height: 12),
              _ProfileMenuCard(
                icon: Icons.history,
                title: 'ประวัติการวางหมุด',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _ProfileMenuCard(
                icon: Icons.logout,
                title: 'ออกจากระบบ',
                isLogout: true,
                onTap: () async {
                  final navigator = Navigator.of(context);
                  await FirebaseAuth.instance.signOut();

                  if (!mounted) return;

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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: onTapProfileImage,
            child: CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: isUploadingImage
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : profileImage != null
                    ? Image.file(
                        profileImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                    ? Image.network(
                        profileImageUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.person, size: 40),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ],
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
    this.isLogout = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLogout;

  @override
  Widget build(BuildContext context) {
    final color = isLogout ? Colors.red : AppColors.success;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: isLogout ? Colors.red : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
