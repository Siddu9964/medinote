import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../models/consultation.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';

class ClinicalChronicleScreen extends StatefulWidget {
  final List<ConsultationRecord> history;
  final String patientName;
  final String patientId;

  const ClinicalChronicleScreen({
    super.key,
    required this.history,
    required this.patientName,
    required this.patientId,
  });

  @override
  State<ClinicalChronicleScreen> createState() =>
      _ClinicalChronicleScreenState();
}

class _ClinicalChronicleScreenState extends State<ClinicalChronicleScreen>
    with TickerProviderStateMixin {
  late ConsultationRecord _selectedRecord;
  int _selectedIndex = 0;
  late PageController _pageController;

  static const Color primaryOrange = Color(0xFFE67E22);
  static const Color bgFlesh = Color(0xFFFFEBD8);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color bgFaint = Color(0xFFF3EFE6);
  static const Color dividerColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _selectedRecord = widget.history.first;
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildCompactPatientHeader(),
      body: Column(
        children: [
          _buildHorizontalTimeline(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                  _selectedRecord = widget.history[index];
                });
              },
              itemCount: widget.history.length,
              itemBuilder: (context, index) {
                return _buildDetailsViewport(r, widget.history[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── APP BAR: Patient Metadata ─────────────────────────────
  PreferredSizeWidget _buildCompactPatientHeader() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, color: textDark, size: 28),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFFFEBD8),
            child: Icon(Icons.person, color: primaryOrange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.patientName,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _tag(
                      "OPD",
                      primaryOrange.withValues(alpha: 0.1),
                      textColor: primaryOrange,
                    ),
                  ],
                ),
                Text(
                  "ID: ${widget.patientId}  •  37Y / Male  •  Blood: O+",
                  style: const TextStyle(color: textMuted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _iconBtn(Icons.search),
        // Removed Share, Print, Export
        _iconBtn(Icons.more_vert),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _iconBtn(IconData icon) => Container(
    margin: const EdgeInsets.only(left: 8),
    decoration: BoxDecoration(
      color: Color(0xFFF3EFE6),
      borderRadius: BorderRadius.circular(8),
    ),
    child: IconButton(
      icon: Icon(icon, color: textDark, size: 20),
      onPressed: () {},
    ),
  );

  Widget _buildHorizontalTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: const Text(
            "Visit Timeline",
            style: TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: widget.history.length,
            itemBuilder: (context, index) {
              final record = widget.history[index];
              final isSelected =
                  _selectedRecord.consultationId == record.consultationId;
              final dt =
                  DateTime.tryParse(record.consultationDate ?? '') ??
                  DateTime.now();

              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 90,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryOrange : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? primaryOrange : dividerColor,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primaryOrange.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd').format(dt),
                        style: TextStyle(
                          color: isSelected ? Colors.white : textDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(dt).toUpperCase(),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        record.consultationTime?.substring(0, 5) ?? '--:--',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.7)
                              : textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Consultation",
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : primaryOrange,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1, color: dividerColor),
      ],
    );
  }

  Widget _smBtn(IconData icon, {bool filled = false}) => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: filled ? primaryOrange : Colors.white,
      borderRadius: BorderRadius.circular(6),
      border: filled ? null : Border.all(color: dividerColor),
    ),
    child: Icon(icon, size: 16, color: filled ? Colors.white : textMuted),
  );

  // ── VIEWPORT: Visit Details ────────────────────────────────
  Widget _buildDetailsViewport(R r, ConsultationRecord record) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildVisitSummaryHero(record),
          const SizedBox(height: 24),
          _buildGridSnapshot(record),
          const SizedBox(height: 24),
          _buildObservationsBlock(record),
          const SizedBox(height: 24),
          _buildInvestigationChips(record),
          const SizedBox(height: 24),
          _buildMedSchedule(record),
          const SizedBox(height: 24),
          _buildClinicalCanvas(record),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildVisitSummaryHero(ConsultationRecord record) {
    final dt =
        DateTime.tryParse(record.consultationDate ?? '') ?? DateTime.now();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgFlesh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryOrange.withValues(alpha: 0.1)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 60,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.favorite, size: 140, color: primaryOrange),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEEE').format(dt).toUpperCase(),
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      DateFormat('dd').format(dt),
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(dt),
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                Container(width: 1, height: 60, color: dividerColor),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _tag(
                        "OPD CONSULTATION",
                        primaryOrange.withValues(alpha: 0.1),
                        textColor: primaryOrange,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Session ID",
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            "SESS-${record.consultationId ?? '000'}",
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.copy, color: textMuted, size: 12),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Dr. ${record.doctorName ?? 'Staff'}",
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridSnapshot(ConsultationRecord record) {
    final v = record.vitals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "- PHYSICAL VITALS",
          style: TextStyle(
            color: textDark,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _snap(
                    "BP",
                    v['bp'] ?? '--',
                    Icons.favorite,
                    const Color(0xFFFEE2E2),
                    primaryOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _snap(
                    "SPO2",
                    v['spo2'] ?? '--',
                    Icons.bloodtype,
                    const Color(0xFFE0F2FE),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _snap(
                    "Pulse",
                    v['pulse'] ?? '--',
                    Icons.monitor_heart,
                    const Color(0xFFFEF3C7),
                    Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _snap(
                    "Temp",
                    v['temp'] ?? '--',
                    Icons.thermostat,
                    const Color(0xFFF3E8FF),
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _snap(
                    "Weight",
                    v['weight'] ?? '--',
                    Icons.scale,
                    const Color(0xFFD1FAE5),
                    Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _snap(
                    "Height",
                    v['height'] ?? '--',
                    Icons.height,
                    const Color(0xFFE0E7FF),
                    Colors.indigo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _snap(String label, String val, dynamic icon, Color bg, Color tint) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: icon is IconData
                ? Icon(icon, color: tint, size: 18)
                : Icon(Icons.vaccines, color: tint, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: textMuted,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildObservationsBlock(ConsultationRecord record) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.assignment, color: primaryOrange, size: 22),
              const SizedBox(width: 12),
              const Text(
                "PHYSICIAN OBSERVATIONS",
                style: TextStyle(
                  color: textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.auto_awesome,
                color: Colors.deepOrange,
                size: 14,
              ),
              const SizedBox(width: 6),
              const Text(
                "AI Transcribed",
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              _iconAction(Icons.edit_outlined),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.format_quote,
                color: Color(0xFFEFF6FF),
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Removed Vitals Row from here as they are now in Snapshot
                    Text(
                      record.clinicalNotes ?? 'Routine checkup.',
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgFaint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.bubble_chart, color: primaryOrange, size: 16),
                const SizedBox(width: 8),
                const Text(
                  "Auto transcribed via Clinical Voice AI  •  10:39 AM",
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestigationChips(ConsultationRecord record) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ORDERED INVESTIGATIONS",
                style: TextStyle(
                  color: textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                "View All",
                style: TextStyle(
                  color: primaryOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: (record.labData?.split('|') ?? [])
                .map((t) => _pill(t.trim()))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7ED),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFFFEDD5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.biotech, color: primaryOrange, size: 14),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: primaryOrange,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );

  Widget _buildMedSchedule(ConsultationRecord record) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "MEDICATION SCHEDULE",
            style: TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          ...record.medications.map(
            (m) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgFaint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: dividerColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.wb_sunny_outlined,
                    color: Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Morning",
                    style: TextStyle(
                      color: textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['name'] ?? 'N/A',
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "1 - 0 - 1  •  After Food",
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _tag(
                    "${m['duration']} Remaining",
                    const Color(0xFFECFDF5),
                    textColor: primaryOrange,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalCanvas(ConsultationRecord record) {
    if (record.imageUrls.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "HANDWRITTEN CLINICAL CANVAS",
                style: TextStyle(
                  color: textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.fullscreen_rounded,
                  color: textMuted,
                  size: 22,
                ),
                onPressed: () => _showFullScreenImage(
                  context,
                  ApiService.sanitizeImageUrl(record.imageUrls[0]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showFullScreenImage(
              context,
              ApiService.sanitizeImageUrl(record.imageUrls[0]),
            ),
            child: Container(
              height: 320,
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgFaint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: dividerColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  ApiService.sanitizeImageUrl(record.imageUrls[0]),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────
  Widget _tag(String text, Color bg, {Color? textColor}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: textColor ?? Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  Widget _iconAction(IconData icon) => Icon(icon, color: textMuted, size: 20);
}

