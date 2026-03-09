import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_2/core/services/firebase_auth_service.dart';
import 'package:flutter_application_2/core/theme/app_colors.dart';
import 'package:flutter_application_2/presentation/layout/main_layout.dart';
import 'package:flutter_application_2/presentation/screen/auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      final identifier = _identifierController.text.trim();
      final password = _passwordController.text;

      setState(() {
        _isLoading = true;
      });

      try {
        final username = await _authService.login(
          identifier: identifier,
          password: password,
        );

        if (!mounted) {
          return;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainLayout(username: username),
          ),
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) {
          return;
        }

        String message;
        if (e.code == 'user-not-found') {
          message = 'ไม่มีผู้ใช้ในระบบ';
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          message = 'รหัสผ่านไม่ถูกต้อง';
        } else if (e.code == 'permission-denied') {
          message = 'ยังไม่มีสิทธิ์เข้าถึง Firestore (ต้องแก้ Firestore Rules)';
        } else if (e.code == 'operation-not-allowed' ||
            (e.code == 'internal-error' &&
                (e.message ?? '').contains('CONFIGURATION_NOT_FOUND'))) {
          message =
              'Firebase Auth ยังไม่ได้เปิด Email/Password หรือยังตั้งค่าโปรเจกต์ไม่ครบ';
        } else {
          message = e.message ?? 'เข้าสู่ระบบไม่สำเร็จ';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _openRegisterScreen() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _identifierController,
                      decoration: const InputDecoration(
                        labelText: 'Username หรือ Email',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอก Username หรือ Email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอก Password';
                        }
                        if (value.length < 6) {
                          return 'Password ต้องมีอย่างน้อย 6 ตัวอักษร';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _openRegisterScreen,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          textStyle: Theme.of(context).textTheme.labelSmall,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('สมัครสมาชิค'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('เข้าสู่ระบบ'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}