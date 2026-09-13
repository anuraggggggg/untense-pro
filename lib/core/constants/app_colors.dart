import 'package:flutter/material.dart';

/// Centralized color palette derived from UnTense Pro brand assets & mood board.
class AppColors {
  // Brand Core Colors
  static const Color primaryNavy = Color(0xFF0B1B3D); // Deep Midnight Navy
  static const Color primaryCyan =
      Color(0xFF0CA5F8); // Vibrant Electric Cyan / Blue
  static const Color accentMint =
      Color(0xFF1DF0D4); // Glowing Mint / Teal Accent
  static const Color mintBg = Color(0xFFF0FDF9); // Soft Mint Tinted Background

  // Legacy / Direct Aliases for Brand System Compatibility
  static const Color primaryTeal =
      Color(0xFF0B1B3D); // Primary Dark Header / Brand
  static const Color primaryTealLight =
      Color(0xFF0CA5F8); // Primary Vibrant Accent
  static const Color mintAccent = Color(0xFF1DF0D4); // Accent Mint

  // Surface & Background Colors
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF0B1B3D);
  static const Color cardDark = Color(0xFF132448);

  // Status Colors
  static const Color onlineGreen = Color(0xFF10B981);
  static const Color offlineGrey = Color(0xFF64748B);
  static const Color pendingYellow = Color(0xFFF59E0B);
  static const Color rejectedRed = Color(0xFFEF4444);
  static const Color approvedBlue = Color(0xFF0284C7);

  // Audio / Video Accent Colors
  static const Color audioCallAccent = Color(0xFF8B5CF6);
  static const Color videoCallAccent = Color(0xFFEC4899);
  static const Color chatAccent = Color(0xFF0CA5F8);

  // Neutral Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);
  static const Color dividerGrey = Color(0xFFCBD5E1);

  // Dark Mode Text & Elements
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF1E293B);
}
