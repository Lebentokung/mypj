import 'package:flutter/material.dart';
import 'package:flutter_application_2/core/theme/app_theme.dart';
import 'package:flutter_application_2/presentation/layout/main_layout.dart';

void main() async {

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BUILDSPHERE2503',
      theme: AppTheme.lightTheme,
      home: const MainLayout(),

    );
  }
}
