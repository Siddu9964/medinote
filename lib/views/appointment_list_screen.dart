import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../utils/session_manager.dart';
import 'prescription_screen.dart';
import 'login_screen.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _isLoading = true;
  List<Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await SessionManager.getUser();
    if (user != null) {
      final appointments = await _apiService.getAppointments(user.id);
      
      final now = DateTime.now();
      final todayAppointments = appointments.where((app) {
        if (app.appointmentDate == null) return false;
        return app.appointmentDate!.year == now.year &&
               app.appointmentDate!.month == now.month &&
               app.appointmentDate!.day == now.day &&
               app.status == 1;
      }).toList();

      setState(() {
        _currentUser = user;
        _appointments = todayAppointments;
        _isLoading = false;
      });
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Modern Header Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(context.r.hPad, context.r.isSmallPhone ? 20 : 32, context.r.hPad, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("CLINICAL DASHBOARD", style: AppStyles.caption.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w900, color: AppColors.primary)),
                                    const SizedBox(height: 8),
                                    Text(
                                      _currentUser != null ? "Welcome, Dr. ${_currentUser!.username}" : "Welcome, Doctor",
                                      style: AppStyles.heading.copyWith(fontSize: 24),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 24),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Quick Stats/Info Card (Modern Gradient)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${_appointments.length} Patients for Today",
                                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          "Your dedicated care makes a difference. Let's start the healing.",
                                          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 32),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Appointment Title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Today's Schedule", style: AppStyles.subheading),
                            TextButton(
                              onPressed: () {},
                              child: Text("VIEW ALL", style: AppStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    _appointments.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.event_available_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.4)),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text("No Appointments", style: AppStyles.subheading),
                                  const SizedBox(height: 8),
                                  const Text("Your schedule is currently clear.", style: AppStyles.caption),
                                ],
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: EdgeInsets.fromLTRB(context.r.hPad, 8, context.r.hPad, 32),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final appointment = _appointments[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 15),
                                    child: Container(
                                      decoration: AppDecorations.standardCard,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => PrescriptionScreen(
                                                  appointment: appointment,
                                                  doctor: _currentUser!,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(20.0),
                                            child: Row(
                                              children: [
                                                // Modern Avatar
                                                Container(
                                                  width: 56,
                                                  height: 56,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.background,
                                                    borderRadius: BorderRadius.circular(18),
                                                    border: Border.all(color: AppColors.border),
                                                  ),
                                                  child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
                                                ),
                                                const SizedBox(width: 20),
                                                // Details
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(appointment.patientName, style: AppStyles.bodyBold),
                                                      const SizedBox(height: 6),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.badge_outlined, size: 14, color: AppColors.textSecondary),
                                                          const SizedBox(width: 4),
                                                          Text("ID: ${appointment.patientId}", style: AppStyles.caption),
                                                          const SizedBox(width: 16),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: AppColors.success.withValues(alpha: 0.1),
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              "ACTIVE",
                                                              style: AppStyles.caption.copyWith(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w900),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Interactive Arrow
                                                Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary.withValues(alpha: 0.05),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 18),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                childCount: _appointments.length,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
