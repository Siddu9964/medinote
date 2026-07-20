import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'drawing_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  STROKE PAINTER
//  repaint: is set to controller.repaintNotifier so ONLY the canvas pixels
//  are invalidated per point — the widget tree is NEVER rebuilt during draw.
// ─────────────────────────────────────────────────────────────────────────────
class StrokePainter extends CustomPainter {
  final List<Stroke> strokes;
  final bool showLinedPaper;

  StrokePainter({
    required this.strokes,
    this.showLinedPaper = false,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showLinedPaper) _drawLinedPaper(canvas, size);

    for (final stroke in strokes) {
      final outline = stroke.outline;
      if (outline.length < 4) {
        // Not enough points yet — draw a dot so the first tap is visible
        if (stroke.points.isNotEmpty) {
          final p = stroke.points.first;
          canvas.drawCircle(
            Offset(p.x, p.y),
            stroke.size * 0.35,
            Paint()
              ..color = stroke.color
              ..isAntiAlias = true,
          );
        }
        continue;
      }

      final paint = Paint()
        ..color = stroke.color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      if (stroke.isHighlighter) paint.blendMode = BlendMode.multiply;

      canvas.drawPath(_outlineToPath(outline), paint);
    }
  }

  // Quadratic bezier through midpoints for silky smooth rendering
  Path _outlineToPath(List<Offset> pts) {
    final path = Path();
    path.moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final mid = Offset(
        (pts[i].dx + pts[i + 1].dx) / 2,
        (pts[i].dy + pts[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    path.close();
    return path;
  }

  void _drawLinedPaper(Canvas canvas, Size size) {
    // Horizontal guide lines
    final linePaint = Paint()
      ..color = const Color(0xFFDDE8FF)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    const lineSpacing = 34.0;
    for (double y = lineSpacing; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    // Red margin line
    canvas.drawLine(
      const Offset(52, 0),
      Offset(52, size.height),
      Paint()
        ..color = const Color(0xFFFFCDD2).withValues(alpha: 0.7)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant StrokePainter old) => false;
  // shouldRepaint is irrelevant when using repaint: listenable — Flutter
  // calls paint() directly when the listenable fires, bypassing shouldRepaint.
}

// ─────────────────────────────────────────────────────────────────────────────
//  ERASER CURSOR PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _EraserCursorPainter extends CustomPainter {
  final Offset? position;
  final double radius;

  _EraserCursorPainter(this.position, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    if (position == null) return;
    canvas.drawCircle(
      position!,
      radius,
      Paint()
        ..color = Colors.grey.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _EraserCursorPainter old) =>
      old.position != position;
}

// ─────────────────────────────────────────────────────────────────────────────
//  DRAWING CANVAS
//
//  KEY POINTS:
//  • RepaintBoundary isolates this subtree from the rest of the widget tree.
//  • StrokePainter(repaint: controller.repaintNotifier) means Flutter calls
//    painter.paint() DIRECTLY when repaintNotifier fires — no build() call,
//    no widget diff, no setState anywhere.
//  • Palm rejection: only stylus / invertedStylus / mouse accepted.
//  • Finger touches are silently swallowed (no scroll, no pan, no draw).
// ─────────────────────────────────────────────────────────────────────────────
class DrawingCanvas extends StatefulWidget {
  final DrawingController controller;
  final int pageIndex;
  final bool enabled;

  const DrawingCanvas({
    super.key,
    required this.controller,
    required this.pageIndex,
    this.enabled = true,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  Offset? _eraserPos;

  bool _isPen(PointerDeviceKind kind) =>
      kind == PointerDeviceKind.stylus ||
      kind == PointerDeviceKind.invertedStylus ||
      kind == PointerDeviceKind.mouse;

  void _onDown(PointerDownEvent e) {
    if (!widget.enabled) return;

    // Palm rejection — ignore finger / unknown
    if (!_isPen(e.kind)) return;

    final ctrl = widget.controller;

    if (e.kind == PointerDeviceKind.invertedStylus) {
      // Physical eraser tip — use public setTool to avoid protected call
      ctrl.setTool('Eraser');
      ctrl.eraseAt(e.localPosition);
      setState(() => _eraserPos = e.localPosition);
      return;
    }

    if (ctrl.tool == 'Eraser') {
      ctrl.eraseAt(e.localPosition);
      setState(() => _eraserPos = e.localPosition);
    } else {
      ctrl.startStroke(
        e.localPosition,
        e.pressure > 0.01 ? e.pressure : 0.0,
        e.timeStamp.inMilliseconds,
      );
    }
  }

  void _onMove(PointerMoveEvent e) {
    if (!widget.enabled) return;
    if (!_isPen(e.kind)) return;

    final ctrl = widget.controller;

    if (e.kind == PointerDeviceKind.invertedStylus) {
      ctrl.eraseAt(e.localPosition);
      // Update eraser cursor — cheap setState on a tiny subtree
      if (_eraserPos != e.localPosition) {
        setState(() => _eraserPos = e.localPosition);
      }
      return;
    }

    if (ctrl.tool == 'Eraser') {
      ctrl.eraseAt(e.localPosition);
      if (_eraserPos != e.localPosition) {
        setState(() => _eraserPos = e.localPosition);
      }
    } else {
      // addPoint only fires repaintNotifier — NO setState, NO widget rebuild
      ctrl.addPoint(
        e.localPosition,
        e.pressure > 0.01 ? e.pressure : 0.0,
        e.timeStamp.inMilliseconds,
      );
    }
  }

  void _onUp(PointerUpEvent e) {
    if (!widget.enabled) return;
    widget.controller.endStroke();
    if (_eraserPos != null) setState(() => _eraserPos = null);
  }

  void _onCancel(PointerCancelEvent e) {
    widget.controller.endStroke();
    if (_eraserPos != null) setState(() => _eraserPos = null);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final strokes = ctrl.currentStrokes;
    final isEraser = ctrl.tool == 'Eraser';

    return RepaintBoundary(
      child: Stack(
        children: [
          // ── Main drawing canvas
          // StrokePainter receives repaintNotifier as its repaint listenable.
          // Flutter calls paint() directly — ZERO widget rebuilds per point.
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _onDown,
              onPointerMove: _onMove,
              onPointerUp: _onUp,
              onPointerCancel: _onCancel,
              child: CustomPaint(
                painter: StrokePainter(
                  strokes: strokes,
                  showLinedPaper: false,
                  repaint: ctrl.repaintNotifier,
                ),
                size: Size.infinite,
              ),
            ),
          ),

          // ── Eraser cursor (only rebuilt when eraser moves, tiny subtree)
          if (isEraser)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _EraserCursorPainter(_eraserPos, 20.0),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
