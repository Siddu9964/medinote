import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  COMMAND CENTER DESIGN TOKENS — Medinote Clinical Interface
//  All visual decisions are centralized here.
// ═══════════════════════════════════════════════════════════════════════════

// ── Color System ────────────────────────────────────────────────────────────

class AppColors {
  // ── Core Clinical Brand ─────────────────────────────────────────────────
  static const Color primary         = Color(0xFF1F6B4A); // Forest Teal
  static const Color primaryDark     = Color(0xFF1F6B4A); // Dark Forest
  static const Color primaryLight    = Color(0xFFBBF7D0); // Clinical Mint
  static const Color secondary       = Color(0xFF475569); // Slate Gray
  static const Color accent          = Color(0xFFBBF7D0); // Clinical Mint

  // ── Light Surface System ────────────────────────────────────────────────
  static const Color background      = Color(0xFFF3EFE6); // Parchment
  static const Color surface         = Color(0xFFFFFFFF); // Pure White
  static const Color cardBg          = Color(0xFFFFFFFF); // White Card
  static const Color border          = Color(0xFFE2E8F0); // Soft border
  static const Color divider         = Color(0xFFF3EFE6); // Very subtle divider

  // ── Text Hierarchy ───────────────────────────────────────────────────────
  static const Color textPrimary     = Color(0xFF0F172A); // Deep Slate
  static const Color textSecondary   = Color(0xFF64748B); // Muted Slate
  static const Color textTertiary    = Color(0xFF94A3B8); // Light Slate

  // ── Status Colors ────────────────────────────────────────────────────────
  static const Color success         = Color(0xFF22C55E); // Clinical Green
  static const Color successLight    = Color(0xFFDCFCE7); // Green tint
  static const Color warning         = Color(0xFFF59E0B); // Warning Amber
  static const Color warningLight    = Color(0xFFFEF3C7); // Amber tint
  static const Color error           = Color(0xFFEF4444); // Error Red
  static const Color errorLight      = Color(0xFFFEE2E2); // Red tint
  static const Color info            = Color(0xFF3B82F6); // Info Blue
  static const Color infoLight       = Color(0xFFDBEAFE); // Blue tint

  // ── Command Center Dark System ───────────────────────────────────────────
  // Used for high-authority areas: AppBars, headers, sidebars
  static const Color cmdBackground   = Color(0xFF1F6B4A); // Dark Forest
  static const Color cmdSurface      = Color(0xFF161B22); // Elevated Surface
  static const Color cmdPanel        = Color(0xFF21262D); // Panel background
  static const Color cmdBorder       = Color(0xFF30363D); // Dark border
  static const Color cmdBorderLight  = Color(0xFF3D444D); // Lighter dark border
  static const Color cmdText         = Color(0xFFE6EDF3); // Primary text on dark
  static const Color cmdTextMuted    = Color(0xFF8D96A0); // Muted text on dark
  static const Color cmdTextFaint    = Color(0xFF4A5568); // Faint text on dark
  static const Color cmdTeal         = Color(0xFF1F6B4A); // Bright teal on dark
  static const Color cmdTealDim      = Color(0xFF1F6B4A); // Dimmer teal on dark

  // ── Dashboard Header (Deep Clinical Authority) ───────────────────────────
  static const Color headerStart     = Color(0xFF1F6B4A); // Dark Forest Start
  static const Color headerEnd       = Color(0xFF1F6B4A); // Dark Forest End
  static const Color headerAccent    = Color(0xFFBBF7D0); // Clinical Mint accent

  // ── Avatar Palette ───────────────────────────────────────────────────────
  static const List<Color> avatarPalette = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF0EA5E9), // Sky
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFFEF4444), // Red
  ];

  // ── Legacy HealFlow Palette (kept for backward compat) ──────────────────
  static const Color darkAppBackground  = Color(0xFF040F0E);
  static const Color deepMedicalTeal    = Color(0xFF1F6B4A);
  static const Color darkCardBg         = Color(0xFF1C1F26);
  static const Color vibrantTeal        = Color(0xFF1F6B4A);
  static const Color accentRed          = Color(0xFFF43F5E);
  static const Color accentOrange       = Color(0xFFFB923C);
  static const Color accentPurple       = Color(0xFF8B5CF6);
  static const Color tealGradientStart  = Color(0xFF1F6B4A);
  static const Color tealGradientEnd    = Color(0xFF1F6B4A);
  static const Color darkFieldBg        = Color(0xFF1F2937);
  static const Color glassWhite         = Color(0xFFFFFFFF);
  static const Color vibrantTealStart   = Color(0xFF1F6B4A);
  static const Color vibrantTealEnd     = Color(0xFF1F6B4A);
  static const Color vibrantBlueStart   = Color(0xFF4A90E2);
  static const Color vibrantBlueEnd     = Color(0xFF6EC6FF);
  static const Color vibrantPurpleStart = Color(0xFF9B5DE5);
  static const Color vibrantPurpleEnd   = Color(0xFFC77DFF);
  static const Color vibrantOrangeStart = Color(0xFFFF9F43);
  static const Color vibrantOrangeEnd   = Color(0xFFFFC371);
  static const Color mintBg             = Color(0xFFF3EFE6);

  // ── Gradients ────────────────────────────────────────────────────────────
  static const Gradient tealGradient = LinearGradient(
    colors: [vibrantTealStart, vibrantTealEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient blueGradient = LinearGradient(
    colors: [vibrantBlueStart, vibrantBlueEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient purpleGradient = LinearGradient(
    colors: [vibrantPurpleStart, vibrantPurpleEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient orangeGradient = LinearGradient(
    colors: [vibrantOrangeStart, vibrantOrangeEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient primaryGradient = tealGradient;

  // ── Command Center Header Gradient ───────────────────────────────────────
  static const Gradient cmdHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [headerStart, headerEnd],
  );
}

// ── Spacing System ──────────────────────────────────────────────────────────

class AppSpacing {
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xl2  = 24.0;
  static const double xl3  = 32.0;
  static const double xl4  = 40.0;
  static const double xl5  = 48.0;
  static const double xl6  = 64.0;
}

// ── Border Radius System ─────────────────────────────────────────────────────

class AppRadius {
  static const double xs     = 6.0;   // tiny chips
  static const double sm     = 8.0;   // status badges
  static const double md     = 12.0;  // buttons
  static const double lg     = 16.0;  // standard cards
  static const double xl     = 20.0;  // large cards
  static const double xl2    = 24.0;  // panels
  static const double xl3    = 32.0;  // dialogs
  static const double pill   = 100.0; // pills / tabs
}

// ── Shadow System ────────────────────────────────────────────────────────────

class AppShadows {
  static List<BoxShadow> get subtle => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get neoDiffuse => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.06),
      blurRadius: 32,
      spreadRadius: 4,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 12,
      spreadRadius: -2,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.14),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> tealGlow({double intensity = 0.28}) => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: intensity),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> colorGlow(Color color, {double intensity = 0.25}) => [
    BoxShadow(
      color: color.withValues(alpha: intensity),
      blurRadius: 16,
      offset: const Offset(0, 5),
    ),
  ];
}

// ── Typography System ────────────────────────────────────────────────────────

class AppStyles {
  // ── Section / Overline labels ────────────────────────────────────────────
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.5,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  static TextStyle sectionLabelOn(Color color) =>
      sectionLabel.copyWith(color: color);

  // ── Metric / Number displays ─────────────────────────────────────────────
  static const TextStyle metricHero = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    color: AppColors.textPrimary,
    height: 1.0,
  );

  static const TextStyle metricLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    height: 1.0,
  );

  static const TextStyle metricMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
    height: 1.0,
  );

  // ── Screen-level headings ────────────────────────────────────────────────
  static const TextStyle commandTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.75,
    height: 1.2,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle profileName = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: -0.5,
  );

  // ── Body ─────────────────────────────────────────────────────────────────
  static const TextStyle bodyBold = TextStyle(
    fontSize: 15,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w500,
    height: 1.6,
  );

  // ── Labels / Captions ────────────────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle captionBold = TextStyle(
    fontSize: 12,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.2,
  );

  static const TextStyle microLabel = TextStyle(
    fontSize: 10,
    color: AppColors.textTertiary,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  // ── Dark surface text ────────────────────────────────────────────────────
  static const TextStyle darkCaption = TextStyle(
    fontSize: 12,
    color: Colors.white60,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle darkBody = TextStyle(
    fontSize: 14,
    color: AppColors.cmdText,
    fontWeight: FontWeight.w500,
    height: 1.6,
  );

  static const TextStyle darkHeading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: AppColors.cmdText,
    letterSpacing: -0.5,
  );
}

// ── Decoration Presets ───────────────────────────────────────────────────────

class AppDecorations {
  // ── Standard light card ─────────────────────────────────────────────────
  static BoxDecoration standardCard = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(color: AppColors.border, width: 1),
    boxShadow: AppShadows.subtle,
  );

  // ── Elevated card ────────────────────────────────────────────────────────
  static BoxDecoration elevatedCard = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(color: AppColors.border.withValues(alpha: 0.5), width: 1),
    boxShadow: AppShadows.medium,
  );

  // ── Premium dark card ────────────────────────────────────────────────────
  static BoxDecoration premiumDarkCard = BoxDecoration(
    color: AppColors.darkCardBg,
    borderRadius: BorderRadius.circular(AppRadius.xl2),
    boxShadow: AppShadows.elevated,
  );

  // ── Glass card ───────────────────────────────────────────────────────────
  static BoxDecoration glassCard = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(32),
    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 30,
        offset: const Offset(0, 15),
      ),
    ],
  );

  // ── Command Center surface ───────────────────────────────────────────────
  static BoxDecoration cmdSurface = BoxDecoration(
    color: AppColors.cmdSurface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(color: AppColors.cmdBorder, width: 1),
  );

  // ── Teal accent chip ─────────────────────────────────────────────────────
  static BoxDecoration tealChip = BoxDecoration(
    color: AppColors.primary.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(AppRadius.sm),
    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
  );

  // ── Status chip decorations ──────────────────────────────────────────────
  static BoxDecoration statusActive = BoxDecoration(
    color: AppColors.success.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(AppRadius.sm),
    border: Border.all(color: AppColors.success.withValues(alpha: 0.25), width: 1),
  );

  static BoxDecoration statusCompleted = BoxDecoration(
    color: AppColors.textTertiary.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(AppRadius.sm),
    border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.2), width: 1),
  );

  // ── Input Decorations ────────────────────────────────────────────────────
  static InputDecoration inputDecoration({required String hintText, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppStyles.caption.copyWith(color: Colors.white60),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.darkFieldBg.withValues(alpha: 0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
    );
  }

  static InputDecoration cssInputDecoration({required String labelText, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 16),
      floatingLabelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
      suffixIcon: suffixIcon,
      filled: false,
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white10, width: 1.5),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white10, width: 1.5),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.transparent, width: 0),
      ),
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
    );
  }

  // ── Clean light input (for light screens) ────────────────────────────────
  static InputDecoration lightInput({required String hintText, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppStyles.caption.copyWith(fontWeight: FontWeight.w500),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.divider,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

// ── API Config ───────────────────────────────────────────────────────────────

class ApiConfig {
  static const String machineIp = "erp.gmhospitals.co.in";
  
  // The correct folder on the server is 'medinote', not 'GM_HMS'
  static const String baseUrl = "https://$machineIp/medinote/api";
}


//class ApiConfig {
  // static const String machineIp = "erp.gmhospitals.co.in";
  // //static const String machineIp = "192.168.0.109";
  // static const String baseUrl   = "https://$machineIp/medinote/api";
  // //static const String webBaseUrl = "http://localhost/medinote/api";