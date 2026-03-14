import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_2/core/services/cloudinary_service.dart';
import 'package:flutter_application_2/core/models/map_pin_model.dart';
import 'package:latlong2/latlong.dart';

class PinService {
  PinService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
      CloudinaryService? cloudinary,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
      _cloudinary = cloudinary ?? CloudinaryService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
    final CloudinaryService _cloudinary;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'กรุณาเข้าสู่ระบบก่อน',
      );
    }
    return uid;
  }

  Future<List<MapPin>> getMyPins() async {
    try {
      final snapshot = await _firestore
          .collection('pins')
          .where('user_id', isEqualTo: _uid)
          .get();

      final pins = snapshot.docs
          .map((doc) => MapPin.fromMap(doc.id, doc.data()))
          .toList();

      pins.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return pins;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw FirebaseAuthException(
          code: 'permission-denied',
          message: 'ยังไม่มีสิทธิ์เข้าถึงหมุด (ต้องอัปเดต Firestore Rules)',
        );
      }
      rethrow;
    }
  }

  Future<MapPin> addPin({
    required double lat,
    required double lng,
    required String title,
    required String description,
    required List<String> imagePaths,
  }) async {
    try {
      final newDoc = _firestore.collection('pins').doc();
      final imageUrls = await _uploadPinImages(
        pinId: newDoc.id,
        sourcePaths: imagePaths,
      );

      final pin = MapPin(
        id: newDoc.id,
        userId: _uid,
        location: LatLng(lat, lng),
        title: title,
        description: description,
        imagePaths: imageUrls,
        createdAt: DateTime.now(),
      );

      await newDoc.set(pin.toMap());
      return pin;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw FirebaseAuthException(
          code: 'permission-denied',
          message: 'ไม่มีสิทธิ์บันทึกหมุด (ต้องอัปเดต Firestore Rules)',
        );
      }
      rethrow;
    }
  }

  Future<MapPin> updatePin(MapPin pin, List<String> updatedImagePaths) async {
    try {
      final imageUrls = await _uploadPinImages(
        pinId: pin.id,
        sourcePaths: updatedImagePaths,
      );

      final updatedPin = pin.copyWith(
        imagePaths: imageUrls,
      );

      await _firestore.collection('pins').doc(pin.id).set(updatedPin.toMap());
      return updatedPin;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw FirebaseAuthException(
          code: 'permission-denied',
          message: 'ไม่มีสิทธิ์แก้ไขหมุดนี้',
        );
      }
      rethrow;
    }
  }

  Future<void> deletePin(String pinId) async {
    try {
      await _firestore.collection('pins').doc(pinId).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw FirebaseAuthException(
          code: 'permission-denied',
          message: 'ไม่มีสิทธิ์ลบหมุดนี้',
        );
      }
      rethrow;
    }
  }

  Future<List<String>> _uploadPinImages({
    required String pinId,
    required List<String> sourcePaths,
  }) async {
    final urls = <String>[];

    for (var i = 0; i < sourcePaths.length; i++) {
      final path = sourcePaths[i];
      if (path.startsWith('http://') || path.startsWith('https://')) {
        urls.add(path);
        continue;
      }

      final file = File(path);
      if (!await file.exists()) {
        continue;
      }

      final uploadedUrl = await _cloudinary.uploadImage(
        filePath: file.path,
        folder: 'pin_images/$_uid/$pinId',
      );
      urls.add(uploadedUrl);
    }

    return urls;
  }
}
