import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RAW INPUT POINT
// ─────────────────────────────────────────────────────────────────────────────
class InputPoint {
  final double x;
  final double y;
  final double pressure;
  final int timestamp;

  const InputPoint(this.x, this.y, this.pressure, this.timestamp);
}

// ─────────────────────────────────────────────────────────────────────────────
//  STROKE
// ─────────────────────────────────────────────────────────────────────────────
class Stroke {
  final List<InputPoint> points;
  final Color color;
  final double size;
  final bool isHighlighter;
  final String tool;

  List<Offset>? _outlineCache;
  // Tracks how many points were used to build the current cache.
  // When new points are added we only need to rebuild from the last few.
  int _cachedPointCount = 0;

  Stroke({
    required this.points,
    required this.color,
    required this.size,
    this.isHighlighter = false,
    this.tool = 'Pen',
  });

  /// Returns the precomputed outline, rebuilding only what changed.
  List<Offset> get outline {
    if (_outlineCache == null || _cachedPointCount != points.length) {
      _outlineCache = _buildOutline();
      _cachedPointCount = points.length;
    }
    return _outlineCache!;
  }

  /// Called when the stroke is permanently finished (pointer up).
  /// Forces a full clean rebuild so the final outline is authoritative.
  void invalidateCache() {
    _outlineCache = null;
    _cachedPointCount = 0;
  }

  StrokeOptions get _opts => StrokeOptions(
    size: size,
    thinning: tool == 'Marker' ? 0.0 : 0.68,
    smoothing: 0.65,
    streamline: 0.55,
    simulatePressure: false,
    start: StrokeEndOptions.start(cap: true, taperEnabled: true, customTaper: 4.0),
    end: StrokeEndOptions.end(cap: true, taperEnabled: true, customTaper: 7.0),
  );

  List<Offset> _buildOutline() {
    if (points.length < 2) return [];
    final pfPoints = points.map((p) => PointVector(p.x, p.y, p.pressure)).toList();
    return getStroke(pfPoints, options: _opts);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DRAWING CONTROLLER
//
//  TWO notification channels:
//    1. repaintNotifier  — fired on every addPoint/eraseAt.
//                          Used by StrokePainter as its `repaint:` listenable.
//                          Only the canvas pixels redraw — ZERO widget rebuilds.
//
//    2. notifyListeners() — fired only on structural changes:
//                          startStroke, endStroke, undo, clear, addPage, etc.
//                          The outer screen listens here to update badges/pill.
//                          Fires ~2× per stroke — NOT per point.
// ─────────────────────────────────────────────────────────────────────────────
class DrawingController extends ChangeNotifier {

  /// Listenable passed to StrokePainter(repaint:).
  /// Fires on EVERY point — only invalidates the canvas, no widget rebuild.
  final ChangeNotifier repaintNotifier = ChangeNotifier();

  // ── Storage ───────────────────────────────────────────────────────────────
  final List<List<Stroke>> _pages = [[]];
  final List<List<List<Stroke>>> _undoStacks = [[]];

  int _currentPage = 0;
  int get currentPage => _currentPage;
  int get pageCount => _pages.length;

  // ── Tool state ────────────────────────────────────────────────────────────
  Color strokeColor = Colors.black;
  double strokeSize = 1.5;  // S = 1.5 (thin fine pen), M = 3.5
  String tool = 'Pen';
  bool get isHighlighter => tool == 'Marker';

  /// Public API to change tool and notify all listeners (badge + canvas)
  void setTool(String newTool) {
    if (tool == newTool) return;
    tool = newTool;
    notifyListeners();
  }

  // ── Active stroke ─────────────────────────────────────────────────────────
  Stroke? _activeStroke;
  InputPoint? _lastPt;
  double _velPressure = 0.5;
  static const double _velSmoothing = 0.72;

  // ── Accessors ─────────────────────────────────────────────────────────────
  List<Stroke> get currentStrokes => _pages[_currentPage];
  bool get hasStrokes => _pages[_currentPage].isNotEmpty;
  int get undoCount => _undoStacks[_currentPage].length;

  // ── Page management ───────────────────────────────────────────────────────
  void switchPage(int i) {
    _currentPage = i.clamp(0, _pages.length - 1);
    notifyListeners();
    repaintNotifier.notifyListeners();
  }

  void addPage() {
    _pages.add([]);
    _undoStacks.add([]);
    _currentPage = _pages.length - 1;
    notifyListeners();
  }

  void removePage(int i) {
    if (_pages.length <= 1) return;
    _pages.removeAt(i);
    _undoStacks.removeAt(i);
    if (_currentPage >= _pages.length) _currentPage = _pages.length - 1;
    notifyListeners();
    repaintNotifier.notifyListeners();
  }

  // ── Undo / Clear ──────────────────────────────────────────────────────────
  void _saveUndo() {
    final snap = _pages[_currentPage].map((s) => s).toList();
    _undoStacks[_currentPage].add(snap);
    if (_undoStacks[_currentPage].length > 60) {
      _undoStacks[_currentPage].removeAt(0);
    }
  }

  void undo() {
    final stack = _undoStacks[_currentPage];
    if (stack.isEmpty) return;
    _pages[_currentPage] = stack.removeLast();
    notifyListeners();           // update badge
    repaintNotifier.notifyListeners(); // repaint canvas
  }

  void clearPage() {
    _saveUndo();
    _pages[_currentPage].clear();
    notifyListeners();           // update badge & eraser pill
    repaintNotifier.notifyListeners();
  }

  // ── Stroke lifecycle ──────────────────────────────────────────────────────

  void startStroke(Offset pos, double rawPressure, int ts) {
    _saveUndo();
    final initialPressure = rawPressure > 0.01 ? rawPressure : 0.5;
    _velPressure = initialPressure;
    final p = InputPoint(pos.dx, pos.dy, initialPressure, ts);
    _lastPt = p;
    _activeStroke = Stroke(
      points: [p],
      color: isHighlighter ? strokeColor.withValues(alpha: 0.38) : strokeColor,
      size: strokeSize,
      isHighlighter: isHighlighter,
      tool: tool,
    );
    _pages[_currentPage].add(_activeStroke!);
    notifyListeners();           // show eraser pill immediately
    repaintNotifier.notifyListeners();
  }

  void addPoint(Offset pos, double rawPressure, int ts) {
    final s = _activeStroke;
    if (s == null) return;

    // Distance gate — skip near-duplicates (< 0.5px²)
    final last = _lastPt;
    if (last != null) {
      final dx = pos.dx - last.x;
      final dy = pos.dy - last.y;
      if (dx * dx + dy * dy < 0.25) return;
    }

    // Velocity-based pressure simulation
    double pressure;
    if (rawPressure > 0.01) {
      pressure = rawPressure;
    } else if (last != null) {
      final dt = (ts - last.timestamp).toDouble().clamp(1.0, 80.0);
      final dx2 = pos.dx - last.x, dy2 = pos.dy - last.y;
      final speed = math.sqrt(dx2 * dx2 + dy2 * dy2) / dt;
      final p = (1.0 - (speed / 1.8)).clamp(0.15, 0.95);
      _velPressure = _velPressure * _velSmoothing + p * (1.0 - _velSmoothing);
      pressure = _velPressure;
    } else {
      pressure = 0.5;
    }

    final pt = InputPoint(pos.dx, pos.dy, pressure, ts);
    _lastPt = pt;
    s.points.add(pt);
    // Do NOT call invalidateCache() here — the outline getter checks
    // _cachedPointCount vs points.length and rebuilds automatically.
    // This avoids the O(n) full-rebuild on every single point.

    // ▶ ONLY repaintNotifier fires here — NO setState in outer screen
    repaintNotifier.notifyListeners();
  }

  void endStroke() {
    _activeStroke?.invalidateCache();
    _activeStroke = null;
    _lastPt = null;
    notifyListeners();           // update undo count badge
    repaintNotifier.notifyListeners();
  }

  // ── Eraser ────────────────────────────────────────────────────────────────
  void eraseAt(Offset pos, {double radius = 20.0}) {
    final r2 = radius * radius;
    final before = _pages[_currentPage].length;
    _pages[_currentPage].removeWhere((stroke) {
      for (final p in stroke.points) {
        final dx = p.x - pos.dx, dy = p.y - pos.dy;
        if (dx * dx + dy * dy <= r2) return true;
      }
      return false;
    });
    if (_pages[_currentPage].length != before) {
      repaintNotifier.notifyListeners(); // only canvas repaint
    }
  }

  // ── Export ────────────────────────────────────────────────────────────────
  List<List<Stroke>> get allPagesSnapshot =>
      _pages.map((page) => List<Stroke>.from(page)).toList();

  @override
  void dispose() {
    repaintNotifier.dispose();
    super.dispose();
  }
}
