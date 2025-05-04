import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {
  static const appBarTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20,
    color: Colors.white,
  );

  static const cardTitle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );

  static const buttonText = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  static const inputLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const errorText = TextStyle(
    color: Colors.redAccent,
    fontSize: 13,
  );

  static const cardPrice = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
    color: AppColors.red,
  );
  static const sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const headline = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.lightText,   // lightText нужно в AppColors
  );
}
