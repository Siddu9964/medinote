import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'doctor_detailed_dashboard.dart';
import 'notes_screen.dart';
import 'profile_screen.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';

class MainNavigationContainer extends StatefulWidget {
  final int initialIndex;
  const MainNavigationContainer({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> 
    with SingleTickerProviderStateMixin {
  
  late int _currentIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  late AnimationController _navController;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    
    _navController = AnimationController(
      vsync: this,
      duration: AppAnimations.fast,
    )..forward();

    // The order of pages matches the navigation items
    // Schedule and Patients are currently mapped to Dashboard and Profile as placeholders
    _pages = const [
      DoctorDetailedDashboard(),
      DoctorDetailedDashboard(), // Placeholder for Schedule
      ProfileScreen(),           // Placeholder for Patients
      NotesScreen(),             // Settings/Notes
    ];
  }

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  void _onNavTapped(int index) {
    if (_currentIndex == index) return;
    
    HapticFeedback.selectionClick();
    _navController.reverse().then((_) {
      setState(() => _currentIndex = index);
      _navController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final isDesktop = r.isTablet || r.isDesktop;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.paper,
      extendBody: true, // Crucial for floating nav bar and FAB
      body: AnimatedSwitcher(
        duration: AppAnimations.page,
        switchInCurve: AppAnimations.spring,
        switchOutCurve: AppAnimations.decel,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: isDesktop ? null : _buildFab(),
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(r),
    );
  }

  // ── Floating Action Button (Central +) ────────────────────────────────────

  Widget _buildFab() {
    return Container(
      margin: const EdgeInsets.only(top: 30), // Push down slightly to overlap nav perfectly
      height: 56,
      width: 56,
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          // Action for the central FAB (e.g., Quick Add Menu)
        },
        backgroundColor: AppColors.teal,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  // ── Frosted Sticky Bottom Nav ─────────────────────────────────────────────

  Widget _buildBottomNav(R r) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            border: const Border(
              top: BorderSide(color: AppColors.line, width: 1),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: r.safePadding.bottom > 0 ? r.safePadding.bottom : 22,
            top: 12,
            left: 10,
            right: 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, "Home"),
              _buildNavItem(1, Icons.calendar_month_rounded, Icons.calendar_today_outlined, "Schedule"),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(2, Icons.people_alt_rounded, Icons.people_alt_outlined, "Patients"),
              _buildNavItem(3, Icons.settings_rounded, Icons.settings_outlined, "Settings"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.teal : AppColors.mutedSoft;
    
    return GestureDetector(
      onTap: () => _onNavTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AppAnimations.fast,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                key: ValueKey<bool>(isSelected),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppStyles.functionalLabel.copyWith(
                color: color,
                fontSize: 10,
                letterSpacing: 0,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
