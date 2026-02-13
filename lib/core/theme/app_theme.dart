import 'package:flutter/material.dart';
import 'package:flutter_application_2/core/constants/radii.dart';
import 'package:flutter_application_2/core/theme/app_colors.dart';
import 'package:flutter_application_2/core/theme/app_text_theme.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: AppTextTheme.textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.secondary),
      titleTextStyle: AppTextTheme.textTheme.bodyMedium?.copyWith(
        color: AppColors.secondary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        textStyle: AppTextTheme.textTheme.labelLarge?.copyWith(
          color: AppColors.secondary,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextTheme.textTheme.labelLarge?.copyWith(
          color: AppColors.primary,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        textStyle: AppTextTheme.textTheme.labelLarge?.copyWith(
          color: AppColors.primary,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: AppColors.primary, width: 3),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: AppColors.primary),
      ),
      labelStyle: AppTextTheme.textTheme.labelMedium,
      // helperStyle: AppTextTheme.textTheme.labelMedium?.copyWith(
      //   color: AppColors.textSecondary,
      // ),
      floatingLabelStyle: AppTextTheme.textTheme.labelMedium?.copyWith(
        color: AppColors.primary,
      ),
      errorStyle: AppTextTheme.textTheme.labelMedium?.copyWith(
        color: AppColors.error,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      // shape: RoundedRectangleBorder(
      //   borderRadius: BorderRadius.circular(AppRadii.sm),
      // ),
      checkColor: WidgetStateProperty.all(AppColors.primary),
      fillColor: WidgetStateProperty.all(AppColors.secondary),
    ),
    // สามารถเพิ่มปุ่ม, card, tabBarTheme ฯลฯ ได้ที่นี่
  );
}
