// McDonald's-style palette + нейтральные оттенки
import 'package:flutter/material.dart';

class AppColors {
  // Брендовые
  static const red      = Color(0xFFD71921); // Golden Arches Red
  static const yellow   = Color(0xFFFFC72C); // Golden Arches Yellow

  // Светлая тема
  static const lightBg          = Colors.white;
  static const lightCard        = Color(0xFFF5F5F5);
  static const lightText        = Color(0xFF101010);
  static const lightGreyText    = Color(0xFF707070);

  // Тёмная тема
  static const darkBg           = Color(0xFF121212);
  static const darkCard         = Color(0xFF1E1E1E);
  static const darkText         = Colors.white;
  static const darkGreyText     = Color(0xFFAAAAAA);
  static const surfaceLight = Color(0xFFF5F5F5);

  static const cardBackground = surfaceLight;
  static const success        = Color(0xFF23A657);
}
