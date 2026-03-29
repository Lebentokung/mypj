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

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขโปรไฟล์'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // รูปโปรไฟล์แบบวงกลมที่กดได้
            InkWell(
              onTap: () async {
                // เลือกรูปโดยไม่ปิด dialog
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

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('อัปโหลดรูปโปรไฟล์สำเร็จ')),
                  );
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
              },
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[200],
                child: ClipOval(
                  child: _isUploadingImage
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : _profileImage != null
                      ? Image.file(
                          _profileImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                      ? Image.network(
                          _profileImageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.person, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(labelText: 'ชื่อที่แสดง'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              final updatedName = controller.text.trim();
              if (updatedName.isNotEmpty && updatedName != _displayName) {
                try {
                  await _profileService.updateDisplayName(updatedName);
                  if (!mounted) return;

                  setState(() {
                    _displayName = updatedName;
                  });

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('แก้ไขโปรไฟล์สำเร็จ')),
                  );
                } on FirebaseAuthException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message ?? 'แก้ไขโปรไฟล์ไม่สำเร็จ')),
                  );
                }
              }
              Navigator.of(context).pop();
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
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
              ),
              const SizedBox(height: 16),
              _ProfileMenuCard(
                icon: Icons.edit,
                title: 'แก้ไขโปรไฟล์',
                onTap: _openEditProfileDialog,
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
  });

  final String username;
  final String email;
  final File? profileImage;
  final String? profileImageUrl;
  final bool isUploadingImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success,
            AppColors.success.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: isUploadingImage
                      ? const CircularProgressIndicator()
                      : profileImage != null
                          ? Image.file(
                              profileImage!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : (profileImageUrl != null &&
                                  profileImageUrl!.isNotEmpty)
                              ? Image.network(
                                  profileImageUrl!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.person, size: 50),
                ),
              ),

          
              
            ],
          ),
          const SizedBox(height: 16),
          Text(
            username,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
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
