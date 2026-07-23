import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  CLINICAL EDITORIAL DESIGN TOKENS — Medinote 
//  All visual decisions are centralized here.
// ═══════════════════════════════════════════════════════════════════════════

// ── Color System ────────────────────────────────────────────────────────────

class AppColors {
  // ── Core Clinical Brand (Clinical Editorial Spec) ───────────────────────
  static const Color ink             = Color(0xFF0A1214);
  static const Color panelDark1      = Color(0xFF0B2A2C);
  static const Color panelDark2      = Color(0xFF0E1A1C);
  
  static const Color teal            = Color(0xFF14C6AE); // Positive/normal
  static const Color tealDeep        = Color(0xFF0C8C79);
  static const Color tealGlow        = Color(0x5914C6AE); // rgba(20,198,174,0.35)
  static const Color gold            = Color(0xFFE3B15B); // Premium accents
  
  static const Color coral           = Color(0xFFFF6B57); // Urgent/attention
  static const Color coralTint       = Color(0xFFFFF0ED); 

  static const Color paper           = Color(0xFFF6F8F7); // App background
  static const Color card            = Color(0xFFFFFFFF); // Card surfaces
  static const Color line            = Color(0xFFE7ECEA); // Borders/dividers
  
  static const Color muted           = Color(0xFF6B7680); // Secondary text
  static const Color mutedSoft       = Color(0xFF9AA6A2); // Tertiary text
  static const Color textMain        = Color(0xFF101B1D); // Primary body text

  // ── Backward Compatibility Mappings ──────────────────────────────────────
  static const Color primary         = tealDeep;
  static const Color primaryDark     = panelDark1;
  static const Color primaryLight    = Color(0xFFE7F3F1);
  static const Color secondary       = muted;
  static const Color accent          = gold;
  static const Color background      = paper;
  static const Color surface         = card;
  static const Color cardBg          = card;
  static const Color border          = line;
  static const Color divider         = line;
  
  static const Color textPrimary     = textMain;
  static const Color textSecondary   = muted;
  static const Color textTertiary    = mutedSoft;
  
  static const Color success         = teal;
  static const Color successLight    = Color(0xFFE7F3F1);
  static const Color warning         = gold;
  static const Color warningLight    = Color(0xFFFFF4D9);
  static const Color error           = coral;
  static const Color errorLight      = coralTint;
  static const Color info            = Color(0xFF3B82F6);
  static const Color infoLight       = Color(0xFFDBEAFE);

  static const Color cmdBackground   = ink;
  static const Color cmdSurface      = panelDark1;
  static const Color cmdPanel        = panelDark2;
  static const Color cmdBorder       = Color(0xFF30363D);
  static const Color cmdBorderLight  = Color(0xFF3D444D);
  static const Color cmdText         = Colors.white;
  static const Color cmdTextMuted    = mutedSoft;
  static const Color cmdTextFaint    = muted;
  static const Color cmdTeal         = teal;
  static const Color cmdTealDim      = tealDeep;

  static const Color headerStart     = panelDark1;
  static const Color headerEnd       = panelDark2;
  static const Color headerAccent    = teal;

  static const List<Color> avatarPalette = [
    Color(0xFF6366F1), Color(0xFF0EA5E9), Color(0xFF8B5CF6), Color(0xFFEC4899),
    gold, teal, coral
  ];

  static const Color darkAppBackground  = ink;
  static const Color deepMedicalTeal    = tealDeep;
  static const Color darkCardBg         = panelDark2;
  static const Color vibrantTeal        = teal;
  static const Color accentRed          = coral;
  static const Color accentOrange       = gold;
  static const Color accentPurple       = Color(0xFF8B5CF6);
  static const Color tealGradientStart  = teal;
  static const Color tealGradientEnd    = tealDeep;
  static const Color darkFieldBg        = panelDark1;
  static const Color glassWhite         = Colors.white;
  static const Color vibrantTealStart   = teal;
  static const Color vibrantTealEnd     = tealDeep;
  static const Color vibrantBlueStart   = Color(0xFF4A90E2);
  static const Color vibrantBlueEnd     = Color(0xFF6EC6FF);
  static const Color vibrantPurpleStart = Color(0xFF9B5DE5);
  static const Color vibrantPurpleEnd   = Color(0xFFC77DFF);
  static const Color vibrantOrangeStart = gold;
  static const Color vibrantOrangeEnd   = Color(0xFFFFC371);
  static const Color mintBg             = paper;

  static const Gradient tealGradient = LinearGradient(colors: [teal, tealDeep], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const Gradient blueGradient = LinearGradient(colors: [vibrantBlueStart, vibrantBlueEnd], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const Gradient purpleGradient = LinearGradient(colors: [vibrantPurpleStart, vibrantPurpleEnd], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const Gradient orangeGradient = LinearGradient(colors: [gold, vibrantOrangeEnd], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const Gradient primaryGradient = tealGradient;
  static const Gradient cmdHeaderGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [headerStart, headerEnd]);
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
  static const double xs     = 8.0;   // badges
  static const double sm     = 12.0;  // buttons
  static const double md     = 16.0;  // small cards
  static const double lg     = 22.0;  // large cards
  static const double xl     = 28.0;  
  static const double xl2    = 34.0;  // hero bottom radius
  static const double xl3    = 40.0;  
  static const double pill   = 100.0; // pills / tabs
}

// ── Shadow System ────────────────────────────────────────────────────────────
class AppShadows {
  static List<BoxShadow> get subtle => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> get medium => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> get neoDiffuse => [
    BoxShadow(color: AppColors.teal.withValues(alpha: 0.06), blurRadius: 32, spreadRadius: 4, offset: const Offset(0, 16)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, spreadRadius: -2, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> get elevated => [
    BoxShadow(color: AppColors.ink.withValues(alpha: 0.22), blurRadius: 40, spreadRadius: -14, offset: const Offset(0, 18)),
  ];
  static List<BoxShadow> get cardFloat => elevated; // Standard shadow for Clinical Editorial

  static List<BoxShadow> get navPill => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 32, offset: const Offset(0, 12)),
    BoxShadow(color: AppColors.teal.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> get glass => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8)),
  ];
  static List<BoxShadow> tealGlow({double intensity = 0.35}) => [
    BoxShadow(color: AppColors.teal.withValues(alpha: intensity), blurRadius: 20, offset: const Offset(0, 6)),
  ];
  static List<BoxShadow> colorGlow(Color color, {double intensity = 0.25}) => [
    BoxShadow(color: color.withValues(alpha: intensity), blurRadius: 16, offset: const Offset(0, 5)),
  ];
}

// ── Typography System ────────────────────────────────────────────────────────
class AppStyles {
  // Display / human moments
  static TextStyle get editorialHeading => GoogleFonts.newsreader(
    fontSize: 26, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: AppColors.textMain, letterSpacing: -0.01,
  );
  
  static TextStyle get editorialSection => GoogleFonts.newsreader(
    fontSize: 18, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: AppColors.textMain, letterSpacing: -0.01,
  );

  // Functional UI
  static TextStyle get functionalBody => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textMain, height: 1.6,
  );
  static TextStyle get functionalLabel => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.1,
  );

  // Data / Clinical
  static TextStyle get clinicalData => GoogleFonts.ibmPlexMono(
    fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMain,
  );

  // Backward compatibility mappings
  static TextStyle get sectionLabel => functionalLabel.copyWith(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, height: 1.2);
  static TextStyle sectionLabelOn(Color color) => sectionLabel.copyWith(color: color);
  static TextStyle get metricHero => GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0, color: AppColors.textPrimary, height: 1.0);
  static TextStyle get metricLarge => GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 0, color: AppColors.textPrimary, height: 1.0);
  static TextStyle get metricMedium => GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppColors.textPrimary, height: 1.0);
  static TextStyle get commandTitle => editorialSection.copyWith(fontSize: 22);
  static TextStyle get heading => editorialHeading;
  static TextStyle get subheading => editorialSection;
  static TextStyle get profileName => editorialHeading.copyWith(color: Colors.white, fontSize: 24);
  static TextStyle get bodyBold => functionalBody.copyWith(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.1);
  static TextStyle get body => functionalBody;
  static TextStyle get caption => functionalLabel;
  static TextStyle get captionBold => functionalLabel.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: 0.2);
  static TextStyle get microLabel => clinicalData.copyWith(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w500);
  static TextStyle get darkCaption => functionalLabel.copyWith(color: Colors.white60);
  static TextStyle get darkBody => functionalBody.copyWith(color: AppColors.cmdText);
  static TextStyle get darkHeading => editorialHeading.copyWith(color: AppColors.cmdText);
}

// ── Decoration Presets ───────────────────────────────────────────────────────
class AppDecorations {
  static BoxDecoration standardCard = BoxDecoration(
    color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(color: AppColors.border, width: 1), boxShadow: AppShadows.subtle,
  );
  static BoxDecoration elevatedCard = BoxDecoration(
    color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(color: AppColors.border.withValues(alpha: 0.5), width: 1), boxShadow: AppShadows.cardFloat,
  );
  static BoxDecoration premiumDarkCard = BoxDecoration(
    color: AppColors.darkCardBg, borderRadius: BorderRadius.circular(AppRadius.xl2), boxShadow: AppShadows.elevated,
  );
  static BoxDecoration glassCard = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(32),
    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 15))],
  );
  static BoxDecoration cmdSurface = BoxDecoration(
    color: AppColors.cmdSurface, borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(color: AppColors.cmdBorder, width: 1),
  );
  static BoxDecoration tealChip = BoxDecoration(
    color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm),
    border: Border.all(color: AppColors.teal.withValues(alpha: 0.2), width: 1),
  );
  static BoxDecoration statusActive = BoxDecoration(
    color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm),
    border: Border.all(color: AppColors.teal.withValues(alpha: 0.25), width: 1),
  );
  static BoxDecoration statusCompleted = BoxDecoration(
    color: AppColors.textTertiary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm),
    border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.2), width: 1),
  );

  static InputDecoration inputDecoration({required String hintText, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText, hintStyle: AppStyles.caption.copyWith(color: Colors.white60),
      prefixIcon: prefixIcon, suffixIcon: suffixIcon, filled: true, fillColor: AppColors.darkFieldBg.withValues(alpha: 0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.error, width: 1)),
    );
  }
  static InputDecoration cssInputDecoration({required String labelText, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText, labelStyle: const TextStyle(color: Colors.white38, fontSize: 16),
      floatingLabelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
      suffixIcon: suffixIcon, filled: false, contentPadding: const EdgeInsets.symmetric(vertical: 10),
      border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10, width: 1.5)),
      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10, width: 1.5)),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent, width: 0)),
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
    );
  }
  static InputDecoration lightInput({required String hintText, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText, hintStyle: AppStyles.caption.copyWith(fontWeight: FontWeight.w500),
      prefixIcon: prefixIcon, suffixIcon: suffixIcon, filled: true, fillColor: AppColors.divider,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }
}

// ── Animation System ─────────────────────────────────────────────────────────
class AppAnimations {
  static const Duration fast    = Duration(milliseconds: 180);
  static const Duration normal  = Duration(milliseconds: 300);
  static const Duration medium  = Duration(milliseconds: 420);
  static const Duration slow    = Duration(milliseconds: 550);
  static const Duration page    = Duration(milliseconds: 400);
  static const Duration stagger = Duration(milliseconds: 80);
  static const Curve spring  = Curves.easeOutCubic;
  static const Curve smooth  = Curves.easeInOutCubic;
  static const Curve bounce  = Curves.elasticOut;
  static const Curve decel   = Curves.decelerate;
}

class AppTransitions {
  static PageRoute<T> fadeSlide<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: AppAnimations.page, reverseTransitionDuration: AppAnimations.normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: AppAnimations.spring));
        return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
      },
    );
  }
  static PageRoute<T> slideUp<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: AppAnimations.page, reverseTransitionDuration: AppAnimations.normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: AppAnimations.spring));
        return SlideTransition(position: slide, child: child);
      },
    );
  }
  static PageRoute<T> slideRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: AppAnimations.page, reverseTransitionDuration: AppAnimations.normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: AppAnimations.spring));
        return SlideTransition(position: slide, child: child);
      },
    );
  }
}

// ── API Config ───────────────────────────────────────────────────────────────
class ApiConfig {
  static const String machineIp = "192.168.0.103";
  static const String baseUrl = "https://$machineIp/medinote/api";
}