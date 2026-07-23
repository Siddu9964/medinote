import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../models/user.dart';
import '../models/appointment.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../utils/session_manager.dart';
import 'prescription_screen.dart';
import 'clinical_chronicle_screen.dart';
import '../models/consultation.dart';
import 'widgets/prescription_viewer.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  DoctorDetailedDashboard  —  Command Center Edition
// ═══════════════════════════════════════════════════════════════════════════

class DoctorDetailedDashboard extends StatefulWidget {
  const DoctorDetailedDashboard({super.key});

  @override
  State<DoctorDetailedDashboard> createState() =>
      _DoctorDetailedDashboardState();
}

class _DoctorDetailedDashboardState extends State<DoctorDetailedDashboard>
    with TickerProviderStateMixin {
  // ── Animation Controllers ───────────────────────────────────────────────
  late AnimationController _headerController;
  late AnimationController _pulseController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  // ── Data State ──────────────────────────────────────────────────────────
  User? _doctorUser;
  bool _isPageLoading = true;
  List<Appointment> _allAppointments = [];
  List<Appointment> _filteredAppointments = [];
  String _currentFilter = 'Today';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  Appointment? _selectedAppointment;
  String _branchName = "GM Hospital";

  // ── Design Tokens (local overrides from Command Center palette) ──────────
  static const Color _pageBg = AppColors.paper;
  static const Color _activeColor = AppColors.teal;
  static const Color _completedColor = Color(0xFF94A3B8);

  // ═══════════════════════════════════════════════════════════════════════
  //  Lifecycle
  // ═══════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _loadBranchName();
    _setupAnimations();
    _loadData();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  Future<void> _loadBranchName() async {
    final branch = await SessionManager.getBranchName();
    if (branch != null && mounted) {
      setState(() => _branchName = branch);
    }
  }

  void _setupAnimations() {
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _headerController,
            curve: Curves.easeOutQuart,
          ),
        );
  }

  void _onFocusChanged() {
    if (mounted) setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _headerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Data Loading & Filtering  — UNCHANGED
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _loadData() async {
    final user = await SessionManager.getUser();
    if (user != null) {
      final appointments = await ApiService().getAppointments(user.id);
      if (mounted) {
        setState(() {
          _doctorUser = user;
          _allAppointments = appointments;
          _isPageLoading = false;
        });
        _applyFilter(_currentFilter);
        _headerController.forward(from: 0);
      }
    }
  }

  void _onSearchChanged() => _applyFilter(_currentFilter);

  void _applyFilter(String filter) {
    setState(() {
      _currentFilter = filter;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      _filteredAppointments = _allAppointments.where((app) {
        bool dateMatch = false;
        final appDate = app.appointmentDate != null
            ? DateTime(
                app.appointmentDate!.year,
                app.appointmentDate!.month,
                app.appointmentDate!.day,
              )
            : null;

        if (filter == 'Today') {
          dateMatch =
              appDate != null &&
              appDate.year == today.year &&
              appDate.month == today.month &&
              appDate.day == today.day &&
              app.status == 1;
        } else if (filter == 'Upcoming') {
          dateMatch =
              appDate != null && appDate.isAfter(today) && app.status == 1;
        } else if (filter == 'Completed') {
          dateMatch = app.status == 0;
        } else {
          dateMatch = true;
        }

        final query = _searchController.text.toLowerCase();
        final searchMatch =
            app.patientName.toLowerCase().contains(query) ||
            app.patientId.toLowerCase().contains(query);

        return dateMatch && searchMatch;
      }).toList();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Computed Stats & Helpers  — UNCHANGED
  // ═══════════════════════════════════════════════════════════════════════

  int get _totalPatientsToday => _allAppointments.where((a) {
    if (a.appointmentDate == null) return false;
    final n = DateTime.now();
    return a.appointmentDate!.year == n.year &&
        a.appointmentDate!.month == n.month &&
        a.appointmentDate!.day == n.day;
  }).length;

  int get _completedToday => _allAppointments.where((a) {
    if (a.appointmentDate == null) return false;
    final n = DateTime.now();
    return a.appointmentDate!.year == n.year &&
        a.appointmentDate!.month == n.month &&
        a.appointmentDate!.day == n.day &&
        a.status == 0;
  }).length;

  int get _pendingToday => _totalPatientsToday - _completedToday;

  int get _activeFilteredCount =>
      _filteredAppointments.where((a) => a.status == 1).length;

  // Count helpers for filter tab badges
  int get _todayCount => _allAppointments.where((a) {
    if (a.appointmentDate == null) return false;
    final n = DateTime.now();
    return a.appointmentDate!.year == n.year &&
        a.appointmentDate!.month == n.month &&
        a.appointmentDate!.day == n.day &&
        a.status == 1;
  }).length;

  int get _upcomingCount => _allAppointments.where((a) {
    if (a.appointmentDate == null) return false;
    final today = DateTime.now();
    final appDate = DateTime(
      a.appointmentDate!.year,
      a.appointmentDate!.month,
      a.appointmentDate!.day,
    );
    final todayDate = DateTime(today.year, today.month, today.day);
    return appDate.isAfter(todayDate) && a.status == 1;
  }).length;

  int get _completedCount =>
      _allAppointments.where((a) => a.status == 0).length;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getProfileImageUrl(String? path) => ApiService.sanitizeImageUrl(path);

  Color _avatarColor(String patientId) =>
      AppColors.avatarPalette[patientId.length %
          AppColors.avatarPalette.length];

  // ═══════════════════════════════════════════════════════════════════════
  //  Business Logic — UNCHANGED (prescriptions, patient details, etc.)
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _viewPrescriptions(Appointment appointment) async {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
    try {
      final List<ConsultationRecord> history = await ApiService()
          .getPrescriptions(patientId: appointment.patientId);

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (history.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClinicalChronicleScreen(
                history: history,
                patientName: appointment.patientName,
                patientId: appointment.patientId,
              ),
            ),
          );
        } else {
          _showNoHistoryDialog(appointment.patientName);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar('Error fetching history: $e');
      }
    }
  }

  void _showNoHistoryDialog(String patientName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl3),
        ),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF3EFE6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No History Found',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'There are no previous clinical records or prescriptions found for $patientName.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headerStart,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'CLOSE',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _showPatientDetails(String patientId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
    final response = await ApiService().getPatientDetails(patientId);
    if (mounted) {
      Navigator.pop(context);
      if (response['status'] == 'success') {
        showDialog(
          context: context,
          builder: (_) => _buildPatientDetailsDialog(response['patient_data']),
        );
      } else {
        _showErrorSnackBar(
          response['message'] ?? 'Failed to fetch patient details',
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Dialog Widgets — UNCHANGED logic, refined visuals
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildPatientDetailsDialog(Map<String, dynamic> data) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl3),
      ),
      elevation: 20,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl3),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.teal.shade50],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.headerStart,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${data['first_name']} ${data['last_name']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Patient ID: ${data['patient_id']}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_note_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditPatientDialog(data);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildInfoSection('Basic Information', [
                      _buildDetailRow(
                        Icons.title_rounded,
                        'Title',
                        data['title'],
                      ),
                      _buildDetailRow(Icons.wc_rounded, 'Gender', data['sex']),
                      _buildDetailRow(
                        Icons.cake_rounded,
                        'Age',
                        '${data['age']} Years',
                      ),
                      _buildDetailRow(
                        Icons.bloodtype_rounded,
                        'Blood Group',
                        data['blood_group'],
                        highlight: true,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildInfoSection('Contact & Identity', [
                      _buildDetailRow(
                        Icons.phone_rounded,
                        'Phone',
                        data['phone'],
                      ),
                      _buildDetailRow(
                        Icons.badge_rounded,
                        'Aadhar Number',
                        data['aadhar'],
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildInfoSection('Record Details', [
                      _buildDetailRow(
                        Icons.calendar_today_rounded,
                        'Registration Date',
                        data['date'],
                      ),
                      _buildDetailRow(
                        Icons.calendar_month_rounded,
                        'Date of Birth',
                        data['birth_date'],
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.headerStart,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPatientDialog(Map<String, dynamic> data) {
    final fName = TextEditingController(text: data['first_name']);
    final lName = TextEditingController(text: data['last_name']);
    final phoneC = TextEditingController(text: data['phone']);
    final ageC = TextEditingController(text: data['age']?.toString());
    final bloodC = TextEditingController(text: data['blood_group']);
    final aadharC = TextEditingController(text: data['aadhar']);
    final addressC = TextEditingController(text: data['address']);
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl3),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Update Patient',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildModalField(
                          'First Name',
                          fName,
                          Icons.person_rounded,
                        ),
                        _buildModalField(
                          'Last Name',
                          lName,
                          Icons.person_outline_rounded,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModalField(
                                'Age',
                                ageC,
                                Icons.cake_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModalField(
                                'Blood',
                                bloodC,
                                Icons.bloodtype_rounded,
                              ),
                            ),
                          ],
                        ),
                        _buildModalField(
                          'Phone',
                          phoneC,
                          Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        _buildModalField(
                          'Aadhar',
                          aadharC,
                          Icons.badge_rounded,
                          keyboardType: TextInputType.number,
                        ),
                        _buildModalField(
                          'Address',
                          addressC,
                          Icons.home_rounded,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setModalState(() => saving = true);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final res = await ApiService()
                                  .updatePatientDetails(
                                    patientId: data['patient_id'],
                                    firstName: fName.text,
                                    lastName: lName.text,
                                    age: ageC.text,
                                    bloodGroup: bloodC.text,
                                    phone: phoneC.text,
                                    aadhar: aadharC.text,
                                    address: addressC.text,
                                  );
                              if (res['status'] == 'success') {
                                if (mounted) {
                                  final nav = Navigator.of(ctx);
                                  nav.pop();
                                  _showPatientDetails(data['patient_id']);
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Record updated successfully!',
                                      ),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } else {
                                if (mounted) {
                                  _showErrorSnackBar(
                                    res['message'] ?? 'Update failed',
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) _showErrorSnackBar('Error: $e');
                            } finally {
                              setModalState(() => saving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: saving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'SAVE CHANGES',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: AppColors.primary.withValues(alpha: 0.5),
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xFFF3EFE6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.teal.shade900,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: Colors.teal.shade100),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    dynamic value, {
    bool highlight = false,
  }) {
    String displayValue = (value?.toString().isEmpty ?? true)
        ? 'N/A'
        : value.toString();
    if (displayValue != 'N/A' &&
        displayValue.contains('-') &&
        displayValue.length >= 10) {
      try {
        final dt = DateTime.tryParse(displayValue);
        if (dt != null) displayValue = DateFormat('dd MMM yyyy').format(dt);
      } catch (_) {}
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal.shade700),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            displayValue,
            style: TextStyle(
              color: highlight
                  ? AppColors.headerStart
                  : const Color(0xFF1E293B),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDOB(String? dob) {
    if (dob == null || dob.isEmpty || dob == 'N/A') return 'N/A';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(dob));
    } catch (_) {
      return dob;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  MAIN BUILD — Responsive two-column on tablet
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Scaffold(
      backgroundColor: _pageBg,
      extendBody: true,
      body: _isPageLoading
          ? _buildLoadingState()
          : r.isTablet || r.isDesktop
          ? _buildTabletLayout(r)
          : _buildPhoneLayout(r),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  TABLET LAYOUT — Two column
  // ─────────────────────────────────────────────────────────────

  Widget _buildTabletLayout(R r) {
    return Column(
      children: [
        // ── Fixed Command Header ──────────────────────────────────────────
        _buildGradientHeader(r),

        // Add spacing to clear the overlapping stats from the Hero
        const SizedBox(height: 48),

        // ── Live Vitals (Full Width) ──────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(r.hPad, 0, r.hPad, 16),
          child: _buildLiveVitalsGraph(),
        ),

        // ── Body ───────────────────────────────────────────────
        Expanded(
          child: _buildAppointmentColumn(r),
        ),
      ],
    );
  }

  Widget _buildAppointmentColumn(R r) {
    final hPad = r.hPad;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── FIXED: Search bar ──────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 14),
          child: _buildSearchBar(),
        ),

        // ── FIXED: Section header ──────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 10),
          child: _buildSectionHeader(),
        ),

        // ── FIXED: Filter tabs (Today / Upcoming / Completed) ──────────
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 10),
          child: _buildFilterTabs(),
        ),

        // ── Fine separator line ────────────────────────────────────────
        Container(height: 1, color: AppColors.border),

        // ── SCROLLABLE: Patient cards only ─────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primary,
            backgroundColor: Colors.white,
            child: _filteredAppointments.isEmpty
                ? LayoutBuilder(
                    builder: (ctx, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: _buildEmptyState(),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 32),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: _filteredAppointments.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildStaggeredCard(_filteredAppointments[i], i),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildContextualPanel(R r) {
    // Determine the appointment to show: Explicit selection OR next pending
    Appointment? activeAppt = _selectedAppointment;
    if (activeAppt == null) {
      activeAppt = _filteredAppointments.where((a) => a.status == 1).isNotEmpty
          ? _filteredAppointments.firstWhere((a) => a.status == 1)
          : null;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(r.hPad, 0, r.hPad, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Quick Action Dock ─────────────────────────────────────────
          _buildQuickActionDock(),
          const SizedBox(height: 12),

          _buildSummaryLabel(
            _selectedAppointment != null ? 'SELECTED PATIENT' : 'NEXT PATIENT',
          ),
          const SizedBox(height: 12),
          activeAppt != null
              ? _buildNextPatientCard(activeAppt)
              : _buildNoNextPatient(),

          const SizedBox(height: 20),
          _buildDateTimeCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryLabel(String text) {
    return Text(
      text,
      style: AppStyles.sectionLabel.copyWith(
        color: AppColors.textTertiary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildMetricCard(String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: AppStyles.metricLarge.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppStyles.microLabel),
        ],
      ),
    );
  }

  Widget _buildProgressCard(double completion) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Session Progress',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '${(completion * 100).round()}%',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completion,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_completedToday completed',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$_pendingToday remaining',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextPatientCard(Appointment patient) {
    final color = _avatarColor(patient.patientId);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: AppShadows.tealGlow(intensity: 0.08),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.65)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    patient.patientName.isNotEmpty
                        ? patient.patientName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.patientName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${patient.patientId}',
                      style: AppStyles.microLabel,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusActive,
                child: const Text(
                  'Ready',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_doctorUser != null) {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (ctx, a1, a2) => PrescriptionScreen(
                        appointment: patient,
                        doctor: _doctorUser!,
                      ),
                      transitionsBuilder: (ctx, anim, secAnim, child) =>
                          SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: anim,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                            child: child,
                          ),
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                  ).then((_) => _loadData());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: const Icon(Icons.medical_services_rounded, size: 14),
              label: const Text(
                'START CONSULTATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoNextPatient() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(
          'No pending patients for this filter.',
          style: AppStyles.caption,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDateTimeCard() {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d, y').format(now);
    final timeStr = DateFormat('hh:mm a').format(now);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.headerStart.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.headerStart.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.headerStart.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: AppColors.headerStart,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.headerStart,
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  PHONE LAYOUT — Single column
  // ─────────────────────────────────────────────────────────────

  Widget _buildPhoneLayout(R r) {
    final hPad = r.hPad;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── HERO ─────────────────────────────────────
        _buildGradientHeader(r),

        // Add spacing to clear the overlapping stats from the Hero
        const SizedBox(height: 48),

        // ── LIVE VITALS GRAPH (Neo-Minimalist) ─────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
          child: _buildLiveVitalsGraph(),
        ),

        // ── SEARCH BAR ──────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 12),
          child: _buildSearchBar(),
        ),

        // ── SECTION HEADER & TABS ───────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(),
              const SizedBox(height: 16),
              _buildFilterTabs(),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── SCROLLABLE: Patient cards ─────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.teal,
            backgroundColor: Colors.white,
            child: _filteredAppointments.isEmpty
                ? LayoutBuilder(
                    builder: (ctx, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: _buildEmptyState(),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 120), // Bottom padding for sticky nav
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: _filteredAppointments.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildStaggeredCard(_filteredAppointments[i], i),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  LOADING STATE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildLoadingState() {
    return Column(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.cmdHeaderGradient,
          ),
          child: const SafeArea(
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 4,
            itemBuilder: (context, index) => _buildSkeletonCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppRadius.lg),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 80,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: List.generate(
                      3,
                      (i) => Container(
                        margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                        width: 70,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  COMMAND HEADER
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildGradientHeader(R r) {
    final doctorName = _doctorUser?.fullName?.startsWith('Dr.') == true
        ? _doctorUser!.fullName!
        : 'Dr. ${_doctorUser?.fullName ?? 'Assistant'}';

    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: Container(
          // No bottom radius here; we'll let the overlapping stats row break the bounds
          padding: EdgeInsets.only(bottom: 24), // Space for overlapping stats
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Hero Background
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(r.hPad, r.safePadding.top + 20, r.hPad, 60),
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  image: DecorationImage(
                    image: AssetImage('assets/noise.png'), // Subtle noise texture if available, fallback to solid
                    opacity: 0.05,
                    fit: BoxFit.cover,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Hospital + Profile
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHospitalBadge(),
                        _buildProfileAvatar(r),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Greeting
                    Text(
                      _greeting,
                      style: AppStyles.functionalLabel.copyWith(
                        color: AppColors.mutedSoft,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctorName,
                      style: AppStyles.editorialHeading.copyWith(
                        color: Colors.white,
                        fontSize: r.isPhone ? 32 : 40,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Date & Status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.teal,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'On Duty',
                                style: AppStyles.functionalLabel.copyWith(
                                  color: AppColors.teal,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE, MMMM d').format(DateTime.now()),
                          style: AppStyles.functionalLabel.copyWith(
                            color: AppColors.mutedSoft,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Overlapping Stats Row
              Positioned(
                left: r.hPad,
                right: r.hPad,
                bottom: -24,
                child: _buildHeaderStatsRow(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_hospital_rounded,
            color: AppColors.mutedSoft,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            _doctorUser?.hospitalName ?? 'GM Hospital',
            style: AppStyles.functionalLabel.copyWith(
              color: AppColors.mutedSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(R r) {
    return Hero(
      tag: 'profile_photo',
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.line.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: CircleAvatar(
          radius: r.isPhone ? 22 : 28,
          backgroundImage:
              _doctorUser?.photo != null && _doctorUser!.photo!.isNotEmpty
              ? NetworkImage(_getProfileImageUrl(_doctorUser!.photo))
              : const AssetImage('assets/doctor.jpeg') as ImageProvider,
        ),
      ),
    );
  }

  Widget _buildHeaderStatsRow() {
    final completion = _totalPatientsToday > 0
        ? _completedToday / _totalPatientsToday
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.cardFloat,
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', _totalPatientsToday.toString(), AppColors.textMain),
          Container(width: 1, height: 30, color: AppColors.line),
          _buildStatItem('Done', _completedToday.toString(), AppColors.muted),
          Container(width: 1, height: 30, color: AppColors.line),
          _buildStatItem('Active', _pendingToday.toString(), AppColors.teal),
          Container(width: 1, height: 30, color: AppColors.line),
          _buildStatProgress(completion),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppStyles.editorialHeading.copyWith(
            color: color,
            fontSize: 22,
            fontStyle: FontStyle.normal, // Override italic for raw stats
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppStyles.functionalLabel.copyWith(
            color: AppColors.muted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStatProgress(double completion) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${(completion * 100).round()}%',
          style: AppStyles.functionalBody.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 50,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.line,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: completion,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.sm + 4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  SEARCH BAR
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: _isSearchFocused
            ? AppShadows.tealGlow(intensity: 0.22)
            : AppShadows.subtle,
        border: Border.all(
          color: _isSearchFocused
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.border,
          width: _isSearchFocused ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: _isSearchFocused ? AppColors.primary : Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Search patients by name or ID...',
                hintStyle: AppStyles.caption,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _searchFocusNode.unfocus();
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.grey.shade500,
                  size: 16,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: Colors.grey.shade500,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  SECTION HEADER & FILTER TABS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appointments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '$_activeFilteredCount active  •  ${_filteredAppointments.length} shown',
              style: AppStyles.microLabel,
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: AppDecorations.tealChip,
          child: Text(
            '${_filteredAppointments.length} Found',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    final filterData = {
      'Today': _todayCount,
      'Upcoming': _upcomingCount,
      'Completed': _completedCount,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filterData.entries.map((entry) {
          final filter = entry.key;
          final count = entry.value;
          final isActive = _currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _applyFilter(filter);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isActive ? AppColors.teal : AppColors.line,
                    width: 1,
                  ),
                  boxShadow: isActive ? AppShadows.tealGlow(intensity: 0.2) : null,
                ),
                child: Row(
                  children: [
                    Text(
                      filter,
                      style: AppStyles.functionalLabel.copyWith(
                        color: isActive ? Colors.white : AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withValues(alpha: 0.25)
                            : AppColors.line,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        count.toString(),
                        style: AppStyles.clinicalData.copyWith(
                          color: isActive ? Colors.white : AppColors.mutedSoft,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  NEO-MINIMALIST COMPONENTS (Live Vitals & Action Dock)
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildLiveVitalsGraph() {
    return Container(
      height: 90,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: AppDecorations.glassCard.copyWith(
        color: Colors.white.withValues(alpha: 0.6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
        boxShadow: AppShadows.glass,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
            ),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (ctx, child) => Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.15),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  color: AppColors.teal,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _LiveVitalsPainter(
                    progress: _pulseController.value,
                    color: AppColors.teal,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'LIVE SYSTEM',
                style: AppStyles.functionalLabel.copyWith(
                  fontSize: 9,
                  color: AppColors.mutedSoft,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.colorGlow(AppColors.teal, intensity: 0.4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Online',
                    style: AppStyles.functionalLabel.copyWith(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionDock() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.cardFloat,
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDockItem(Icons.edit_note_rounded, 'New Note', AppColors.teal),
          _buildDockItem(Icons.qr_code_scanner_rounded, 'Scan', AppColors.gold),
          _buildDockItem(Icons.person_add_alt_1_rounded, 'Add Patient', AppColors.textMain),
          _buildDockItem(Icons.history_rounded, 'History', AppColors.muted),
        ],
      ),
    );
  }

  Widget _buildDockItem(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Center(
              child: Icon(icon, color: color, size: 24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppStyles.functionalLabel.copyWith(
              fontSize: 10,
              color: AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  APPOINTMENT CARDS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStaggeredCard(Appointment appointment, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 50).clamp(0, 400)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuart,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: _buildAppointmentCard(appointment),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final bool isCompleted = appointment.status == 0;
    final Color statusColor = isCompleted ? _completedColor : _activeColor;
    final Color avatarColor = _avatarColor(appointment.patientId);

    final String timeStr = appointment.appointmentDate != null
        ? DateFormat('hh:mm a').format(appointment.appointmentDate!)
        : '——';

    final bool isSelected =
        _selectedAppointment?.appointmentId == appointment.appointmentId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAppointment = appointment;
        });
        HapticFeedback.selectionClick();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg + 8),
          gradient: LinearGradient(
            colors: isSelected 
              ? [AppColors.primary.withValues(alpha: 0.08), AppColors.primary.withValues(alpha: 0.02)]
              : [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.06),
              blurRadius: isSelected ? 24 : 16,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.6)
                : Colors.grey.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg + 4),
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Row 1: Avatar + Name + Status ──────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              _showPatientDetails(appointment.patientId),
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  avatarColor,
                                  avatarColor.withValues(alpha: 0.65),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.colorGlow(avatarColor),
                            ),
                            child: Center(
                              child: Text(
                                appointment.patientName.isNotEmpty
                                    ? appointment.patientName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment.patientName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'ID: ${appointment.patientId}',
                                      style: AppStyles.microLabel,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(isCompleted, statusColor),
                      ],
                    ),

                    const SizedBox(height: 11),

                    // ── Row 2: Info chips ──────────────────────────────────
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildInfoChip(
                          Icons.person_outline_rounded,
                          '${appointment.age} yrs',
                          const Color(0xFF6366F1),
                        ),
                        _buildInfoChip(
                          Icons.bloodtype_outlined,
                          appointment.bloodGroup ?? 'N/A',
                          const Color(0xFFE11D48),
                        ),
                        _buildInfoChip(
                          Icons.phone_outlined,
                          appointment.phoneNumber,
                          const Color(0xFF059669),
                        ),
                        if (appointment.birthDate != null &&
                            appointment.birthDate!.isNotEmpty)
                          _buildInfoChip(
                            Icons.cake_outlined,
                            _formatDOB(appointment.birthDate),
                            const Color(0xFFD97706),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ── Complaint ──────────────────────────────────────────
                    if (appointment.complaint != null &&
                        appointment.complaint!.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notes_rounded,
                            size: 14,
                            color: Colors.redAccent.shade200,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              appointment.complaint!,
                              style: TextStyle(
                                color: Colors.redAccent.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],

                    // ── Row 3: Doctor ──────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.headerEnd.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_hospital_outlined,
                            size: 10,
                            color: AppColors.headerEnd,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            appointment.doctorName ??
                                'Dr. ${_doctorUser?.fullName ?? 'Assistant'}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Row 4: Actions ──────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _buildOutlineAction(
                            'History',
                            Icons.history_rounded,
                            avatarColor,
                            onTap: () => _viewPrescriptions(appointment),
                          ),
                        ),
                        if (!isCompleted) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPrimaryAction(
                              'Consult',
                              Icons.medical_services_rounded,
                              onTap: () {
                                if (_doctorUser != null) {
                                  HapticFeedback.mediumImpact();
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (ctx, a1, a2) =>
                                          PrescriptionScreen(
                                            appointment: appointment,
                                            doctor: _doctorUser!,
                                          ),
                                      transitionsBuilder:
                                          (ctx, anim, secAnim, child) =>
                                              SlideTransition(
                                                position:
                                                    Tween<Offset>(
                                                      begin: const Offset(1, 0),
                                                      end: Offset.zero,
                                                    ).animate(
                                                      CurvedAnimation(
                                                        parent: anim,
                                                        curve:
                                                            Curves.easeOutCubic,
                                                      ),
                                                    ),
                                                child: child,
                                              ),
                                      transitionDuration: const Duration(
                                        milliseconds: 400,
                                      ),
                                    ),
                                  ).then((_) => _loadData());
                                }
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Left accent strip ───────────────────────────────────────
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        avatarColor,
                        avatarColor.withValues(alpha: 0.45),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CARD SUB-WIDGETS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStatusBadge(bool isCompleted, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            isCompleted ? 'Done' : 'Active',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction(
    String text,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.headerStart, AppColors.headerEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: AppColors.headerEnd.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlineAction(
    String text,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppShadows.subtle,
            ),
            child: Icon(
              Icons.event_note_outlined,
              size: 52,
              color: AppColors.headerEnd.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Appointments',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your schedule looks clear for this filter.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loadData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.headerStart, AppColors.headerEnd],
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Refresh',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveVitalsPainter extends CustomPainter {
  final double progress;
  final Color color;

  _LiveVitalsPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final midY = height / 2;

    path.moveTo(0, midY);
    for (double i = 0; i < width; i++) {
      // Simulate ECG pattern
      double yOffset = 0;
      double normalizedX = (i / width) * 10;
      
      // Add a couple of sharp "heartbeat" spikes
      if (normalizedX > 2.0 && normalizedX < 2.5) {
        yOffset = math.sin((normalizedX - 2.0) * math.pi * 4) * -15;
      } else if (normalizedX > 6.0 && normalizedX < 6.5) {
        yOffset = math.sin((normalizedX - 6.0) * math.pi * 4) * -15;
      } else {
        // Subtle base noise
        yOffset = math.sin(normalizedX * math.pi + (progress * math.pi * 2)) * 2;
      }

      path.lineTo(i, midY + yOffset);
    }

    // Draw faded background trace
    canvas.drawPath(path, paint);

    // Draw active animated highlight trace
    final pathMetric = path.computeMetrics().first;
    final extractPath = pathMetric.extractPath(0, pathMetric.length * progress);
    canvas.drawPath(extractPath, activePaint);
  }

  @override
  bool shouldRepaint(_LiveVitalsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

