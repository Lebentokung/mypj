import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_2/core/services/cloudinary_service.dart';

class ProfileService {
  ProfileService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
      CloudinaryService? cloudinary,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
      _cloudinary = cloudinary ?? CloudinaryService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
    final CloudinaryService _cloudinary;

  Future<Map<String, String?>> getProfileData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return {
        'profileImageUrl': null,
        'displayName': null,
      };
    }

    final snapshot = await _firestore.collection('users').doc(uid).get();
    final data = snapshot.data();
    final firestoreDisplayName = data?['display_name'] as String?;
    final authDisplayName = _auth.currentUser?.displayName;

    return {
      'profileImageUrl': data?['profile_image_url'] as String?,
      'displayName': firestoreDisplayName ?? authDisplayName,
    };
  }

  Future<String> uploadProfileImage(File imageFile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'กรุณาเข้าสู่ระบบก่อน',
      );
    }

    final url = await _cloudinary.uploadImage(
      filePath: imageFile.path,
      folder: 'profile_images/$uid',
    );

    await _firestore.collection('users').doc(uid).set({
      'profile_image_url': url,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return url;
  }

  Future<void> updateDisplayName(String displayName) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'กรุณาเข้าสู่ระบบก่อน',
      );
    }

    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-display-name',
        message: 'กรุณากรอกชื่อโปรไฟล์',
      );
    }

    await _auth.currentUser?.updateDisplayName(trimmed);
    await _firestore.collection('users').doc(uid).set({
      'display_name': trimmed,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
