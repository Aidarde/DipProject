import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.darkText,
  );

  static const TextStyle cardPrice = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.greyText,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle errorText = TextStyle(
    fontSize: 14,
    color: AppColors.error,
  );

  static const TextStyle inputLabel = TextStyle(
    fontSize: 14,
    color: AppColors.greyText,
  );
}
