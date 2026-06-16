import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceLight = Color(0xFF1E1E1E); // Elevated Card Surface
  
  static const Color primaryGold = Color(0xFFFFD700); // Gold Primary
  static const Color primaryGoldDark = Color(0xFFB8860B); // Gold Dark
  static const Color goldLight = Color(0xFFFFE55C); // Gold Light
  
  static const Color accentOrange = Color(0xFFFF6B00); // Orange
  static const Color accentOrangeLight = Color(0xFFFFA500); // Amber
  
  static const Color textLight = Color(0xFFF5F5F5);
  static const Color textMuted = Color(0xFFA0A0A0);
  static const Color textDark = Color(0xFF0A0A0A);

  static const Color statusPending = Color(0xFFFFA500); // Amber
  static const Color statusReady = Color(0xFF00C853); // Ready Green
  static const Color statusCancelled = Color(0xFFFF1744); // Cancelled Red

  // Gradients
  static const Gradient goldGradient = LinearGradient(
    colors: [primaryGold, accentOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient cardGradient = LinearGradient(
    colors: [surfaceLight, surface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryGold,
      fontFamily: GoogleFonts.poppins().fontFamily,
      
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: accentOrange,
        surface: surface,
        background: background,
        error: statusCancelled,
        onPrimary: textDark,
        onSecondary: textLight,
        onSurface: textLight,
      ),

      // Text Theme
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.bebasNeue(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: primaryGold,
          letterSpacing: 6.0,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 2.0,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: primaryGold,
          letterSpacing: 0.5,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textLight,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: textMuted.withOpacity(0.7),
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: surface,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF222222), width: 1),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        fillColor: surfaceLight,
        filled: true,
        hintStyle: GoogleFonts.poppins(color: textMuted, fontSize: 14),
        labelStyle: GoogleFonts.poppins(color: primaryGold, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF222222)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: statusCancelled, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: textDark,
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGold,
          side: const BorderSide(color: primaryGold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarTheme(
        labelColor: primaryGold,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        unselectedLabelColor: textMuted,
        indicatorColor: primaryGold,
        indicatorSize: TabBarIndicatorSize.tab,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.bebasNeue(fontSize: 24, letterSpacing: 2.0, color: primaryGold),
        iconTheme: const IconThemeData(color: primaryGold),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentOrange,
        foregroundColor: textLight,
        shape: CircleBorder(),
      ),

      // Bottom Navigation Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primaryGold,
        unselectedItemColor: textMuted,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
    );
  }
}
