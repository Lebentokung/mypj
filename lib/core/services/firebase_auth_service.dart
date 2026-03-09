import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final usernameLower = username.trim().toLowerCase();
    final emailTrimmed = email.trim();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: emailTrimmed,
      password: password,
    );

    final uid = credential.user?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'register-failed',
        message: 'ไม่สามารถสร้างผู้ใช้ได้',
      );
    }

    final usernameRef = _firestore.collection('usernames').doc(usernameLower);
    final userRef = _firestore.collection('users').doc(uid);

    try {
      await _firestore.runTransaction((transaction) async {
        final usernameDoc = await transaction.get(usernameRef);
        if (usernameDoc.exists) {
          throw StateError('username-already-in-use');
        }

        transaction.set(usernameRef, {
          'uid': uid,
          'username': username.trim(),
          'email': emailTrimmed,
          'created_at': FieldValue.serverTimestamp(),
        });

        transaction.set(userRef, {
          'uid': uid,
          'username': username.trim(),
          'username_lowercase': usernameLower,
          'email': emailTrimmed,
          'created_at': FieldValue.serverTimestamp(),
        });
      });
    } on StateError catch (e) {
      if (e.message == 'username-already-in-use') {
        await credential.user?.delete();
        throw FirebaseAuthException(
          code: 'username-already-in-use',
          message: 'Username นี้ถูกใช้งานแล้ว',
        );
      }
      rethrow;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw FirebaseAuthException(
          code: 'permission-denied',
          message: 'Firestore rules ยังไม่อนุญาตให้สมัครสมาชิก',
        );
      }
      rethrow;
    }
  }

  Future<String> login({
    required String identifier,
    required String password,
  }) async {
    final normalizedIdentifier = identifier.trim();
    if (normalizedIdentifier.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-identifier',
        message: 'กรุณากรอก Username หรือ Email',
      );
    }

    String? emailForLogin;
    String displayName = normalizedIdentifier;

    if (normalizedIdentifier.contains('@')) {
      emailForLogin = normalizedIdentifier;
    } else {
      final usernameDoc = await _firestore
          .collection('usernames')
          .doc(normalizedIdentifier.toLowerCase())
          .get();

      if (!usernameDoc.exists) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'ไม่มีผู้ใช้ในระบบ',
        );
      }

      final data = usernameDoc.data();
      if (data == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'ไม่มีผู้ใช้ในระบบ',
        );
      }
      emailForLogin = data['email'] as String?;
      displayName = (data['username'] as String?) ?? normalizedIdentifier;
    }

    if (emailForLogin == null || emailForLogin.isEmpty) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'ไม่มีผู้ใช้ในระบบ',
      );
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: emailForLogin,
        password: password,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw FirebaseAuthException(
          code: 'permission-denied',
          message: 'Firestore rules ยังไม่อนุญาตให้อ่านข้อมูลผู้ใช้',
        );
      }
      rethrow;
    }

    return displayName;
  }
}
