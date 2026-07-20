import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class PulseHubScreen extends StatefulWidget {
  const PulseHubScreen({super.key});

  @override
  State<PulseHubScreen> createState() => _PulseHubScreenState();
}

class _PulseHubScreenState extends State<PulseHubScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkAppBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "MEDINOTE PULSE",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient Nebula
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.darkAppBackground,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPulseHeader(),
                  const SizedBox(height: 32),
                  _buildBentoGrid(),
                  const SizedBox(height: 32),
                  _buildSectionTitle("INTELLIGENT INSIGHTS"),
                  const SizedBox(height: 16),
                  _buildInsightsCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppDecorations.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "REAL-TIME PULSE",
                    style: TextStyle(
                      color: AppColors.vibrantTeal.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Vital Monitoring",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.vibrantTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.vibrantTeal.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "72 BPM",
                      style: TextStyle(
                        color: AppColors.vibrantTeal,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 100,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ECGPainter(
                    animationValue: _pulseController.value,
                    color: AppColors.vibrantTeal,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 0.85,
      children: [
        _buildBentoTile(
          title: "SPO2",
          value: "98%",
          trend: "+1.2%",
          icon: Icons.air_rounded,
          color: Colors.blueAccent,
        ),
        _buildBentoTile(
          title: "TEMP",
          value: "36.5°C",
          trend: "Stable",
          icon: Icons.thermostat_rounded,
          color: Colors.orangeAccent,
        ),
        _buildBentoTile(
          title: "BP",
          value: "120/80",
          trend: "Optimal",
          icon: Icons.speed_rounded,
          color: Colors.purpleAccent,
        ),
        _buildBentoTile(
          title: "WEIGHT",
          value: "68.4 kg",
          trend: "-200g",
          icon: Icons.monitor_weight_rounded,
          color: Colors.greenAccent,
        ),
      ],
    );
  }

  Widget _buildBentoTile({
    required String title,
    required String value,
    required String trend,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.glassCard.copyWith(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                trend,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: AppDecorations.glassCard.copyWith(
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AUTO-DIAGNOSTIC INSIGHT",
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Stable Progress",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "Patient exhibits strong cardiovascular stability. Recommended follow-up in 2 weeks for metric recalibration. Vitals within 95th percentile of clinical benchmarks.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Risk Assessment",
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                Text(
                  "LOW RISK",
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ECGPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  ECGPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final path = Path();
    final double midY = size.height / 2;
    
    // Draw background guide line
    final guidePaint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), guidePaint);

    // ECG Logic
    path.moveTo(0, midY);
    
    for (double x = 0; x < size.width; x++) {
      // Create a repeating ECG pattern
      double localX = (x / size.width + animationValue) % 1.0;
      double y = midY;
      
      // The "PQRST" wave logic
      if (localX > 0.1 && localX < 0.15) { // P-wave
        y -= 5 * math.sin((localX - 0.1) * 20 * math.pi);
      } else if (localX > 0.2 && localX < 0.22) { // Q-wave
        y += 8;
      } else if (localX > 0.22 && localX < 0.28) { // R-peak
        y -= 60 * math.sin((localX - 0.22) * 16 * math.pi);
      } else if (localX > 0.28 && localX < 0.3) { // S-dip
        y += 12;
      } else if (localX > 0.4 && localX < 0.55) { // T-wave
        y -= 15 * math.sin((localX - 0.4) * 6 * math.pi);
      }

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Gradient effect for the wave
    final gradient = ui.Gradient.linear(
      Offset(0, midY),
      Offset(size.width, midY),
      [
        color.withValues(alpha: 0.0),
        color,
        color.withValues(alpha: 0.0),
      ],
      [
        0.0,
        animationValue,
        1.0,
      ],
    );
    
    paint.shader = gradient;
    canvas.drawPath(path, paint);
    
    // Glowing tip
    final glowPaint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    double tipX = animationValue * size.width;
    // Calculate tip Y using the same logic
    double tipLocalX = animationValue;
    double tipY = midY;
    if (tipLocalX > 0.1 && tipLocalX < 0.15) tipY -= 5 * math.sin((tipLocalX - 0.1) * 20 * math.pi);
    else if (tipLocalX > 0.2 && tipLocalX < 0.22) tipY += 8;
    else if (tipLocalX > 0.22 && tipLocalX < 0.28) tipY -= 60 * math.sin((tipLocalX - 0.22) * 16 * math.pi);
    else if (tipLocalX > 0.28 && tipLocalX < 0.3) tipY += 12;
    else if (tipLocalX > 0.4 && tipLocalX < 0.55) tipY -= 15 * math.sin((tipLocalX - 0.4) * 6 * math.pi);

    canvas.drawCircle(Offset(tipX, tipY), 4, glowPaint);
    canvas.drawCircle(Offset(tipX, tipY), 2, paint..shader = null..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant ECGPainter oldDelegate) => true;
}
