import 'package:flutter/material.dart';

/// Central responsive helper for Medinote.
/// Use R.of(context) to access sizing helpers anywhere.
class R {
  final BuildContext _context;
  final Size _size;

  R._(this._context, this._size);

  /// Access the responsive helper from any widget
  factory R.of(BuildContext context) {
    return R._(context, MediaQuery.sizeOf(context));
  }

  // ─── Screen Dimensions ────────────────────────────────────────────────────
  double get width => _size.width;
  double get height => _size.height;

  // ─── Device Breakpoints ───────────────────────────────────────────────────
  bool get isPhone => width < 600;
  bool get isTablet => width >= 600 && width < 1024;
  bool get isDesktop => width >= 1024;
  bool get isSmallPhone => width < 360;

  // ─── Dynamic Spacing (% of screen width) ──────────────────────────────────
  /// Standard horizontal padding: 4% of screen width (min 16, max 32)
  double get hPad => (width * 0.05).clamp(16.0, 32.0);

  /// Standard vertical padding
  double get vPad => (height * 0.02).clamp(12.0, 24.0);

  /// Card internal padding
  double get cardPad => (width * 0.045).clamp(14.0, 24.0);

  // ─── Dynamic Font Sizes ───────────────────────────────────────────────────
  double get fontXs => isPhone ? 10.0 : 12.0;
  double get fontSm => isPhone ? 12.0 : 13.0;
  double get fontMd => isPhone ? 14.0 : 15.0;
  double get fontLg => isPhone ? 16.0 : 18.0;
  double get fontXl => isPhone ? 20.0 : 22.0;
  double get fontHero => isPhone ? 26.0 : 32.0;

  // ─── Dynamic Sizing ───────────────────────────────────────────────────────
  /// Button height
  double get btnHeight => isPhone ? 52.0 : 58.0;

  /// Avatar / icon container size
  double get avatarSm => isPhone ? 44.0 : 52.0;
  double get avatarMd => isPhone ? 56.0 : 64.0;
  double get avatarLg => isPhone ? 90.0 : 110.0;

  /// AppBar height hint
  double get appBarHeight => isPhone ? 56.0 : 64.0;

  /// Bottom nav bar height
  double get navBarHeight => isPhone ? 74.0 : 84.0;

  /// Card border radius
  double get cardRadius => isPhone ? 20.0 : 28.0;

  // ─── Grid Columns ─────────────────────────────────────────────────────────
  int get statsColumns => isTablet || isDesktop ? 3 : 2;
  int get appointmentColumns => isTablet || isDesktop ? 2 : 1;

  // ─── Safe Area Padding (from MediaQuery) ──────────────────────────────────
  EdgeInsets get safePadding => MediaQuery.paddingOf(_context);

  // ─── Prescription Canvas (scales to screen) ───────────────────────────────
  /// Canvas width fits within screen excluding toolbar
  double get canvasWidth {
    final toolbarWidth = isPhone ? 60.0 : 70.0;
    return (width - toolbarWidth - hPad).clamp(280.0, 850.0);
  }

  /// Canvas height scales with screen
  double get canvasHeight => (height * 1.3).clamp(600.0, 1100.0);
}

/// Convenience extension so you can do: context.r.width
extension ResponsiveContext on BuildContext {
  R get r => R.of(this);
}
