import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../utils/session_manager.dart';
import 'doctor_detailed_dashboard.dart';
import 'notes_screen.dart';
import 'profile_screen.dart';

class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});

  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentIndex = 0;
  bool _isNavOpen = false;

  final List<Widget> _screens = [
    const DoctorDetailedDashboard(),
    const NotesScreen(),
    const ProfileScreen(),
  ];

  String _branchCode = "GM";

  @override
  void initState() {
    super.initState();
    _loadBranchName();
  }

  Future<void> _loadBranchName() async {
    final branch = await SessionManager.getBranchName();
    if (branch != null && mounted) {
      setState(() {
        if (branch.contains("Nagarabhavi")) {
          _branchCode = "NGBV";
        } else if (branch.contains("Basaveshwaranagar")) {
          _branchCode = "BSVG";
        } else {
          _branchCode = "GM";
        }
      });
    }
  }

  // Navigation destinations — single source of truth
  static const List<_NavDestination> _destinations = [
    _NavDestination(icon: Icons.grid_view_rounded,      activeIcon: Icons.grid_view,          label: 'Dashboard'),
    _NavDestination(icon: Icons.description_outlined,   activeIcon: Icons.description_rounded, label: 'Notes'),
    _NavDestination(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,      label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return r.isTablet || r.isDesktop
        ? _buildTabletLayout()
        : _buildPhoneLayout();
  }

  // ─────────────────────────────────────────────────────────────
  //  TABLET — Fixed left NavigationRail
  // ─────────────────────────────────────────────────────────────

  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Row(
            children: [
              // ── Left Navigation Rail ───────────────────────────────────────────
              _buildNavigationRail(),

              // ── Vertical divider ───────────────────────────────────────────────
              if (_isNavOpen)
                Container(
                  width: 1,
                  color: AppColors.cmdBorder.withValues(alpha: 0.6),
                ),

              // ── Main Content ───────────────────────────────────────────────────
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
            ],
          ),

          // ── The 3-Dots Tab Handle ──────────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: _isNavOpen ? 72 : 0,
            top: MediaQuery.of(context).size.height / 2 - 30,
            child: GestureDetector(
              onTap: () {
                 HapticFeedback.selectionClick();
                 setState(() => _isNavOpen = !_isNavOpen);
              },
              child: Container(
                height: 60,
                width: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                  boxShadow: [
                    if (!_isNavOpen) ...AppShadows.tealGlow(intensity: 0.3)
                  ]
                ),
                child: Icon(
                  _isNavOpen ? Icons.close_rounded : Icons.more_vert_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: _isNavOpen ? 72 : 0,
      decoration: const BoxDecoration(
        color: AppColors.cmdBackground,
      ),
      child: ClipRect(
        child: OverflowBox(
          minWidth: 0,
          maxWidth: 72,
          alignment: Alignment.centerLeft,
          child: SafeArea(
        right: false,
        child: Column(
          children: [
            // ── Logo mark ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 4),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppShadows.tealGlow(intensity: 0.4),
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),

            // ── Rail separator ──────────────────────────────────────────────
            const SizedBox(height: 24),
            Container(height: 1, color: AppColors.cmdBorder),
            const SizedBox(height: 20),

            // ── Nav Items ────────────────────────────────────────────────────
            ..._destinations.asMap().entries.map((entry) {
              return _buildRailItem(entry.key, entry.value);
            }),

            const Spacer(),

            // ── Status indicator at bottom ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  Container(height: 1, color: AppColors.cmdBorder),
                  const SizedBox(height: 16),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Branch Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      _branchCode,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildRailItem(int index, _NavDestination destination) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 72,
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Active left accent bar
            if (isActive)
              Positioned(
                left: 0,
                top: 12,
                bottom: 12,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                  ),
                ),
              ),

            // Icon + label column
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive ? destination.activeIcon : destination.icon,
                    color: isActive ? AppColors.cmdTeal : AppColors.cmdTextMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  destination.label,
                  style: TextStyle(
                    color: isActive ? AppColors.cmdTeal : AppColors.cmdTextMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  PHONE — Floating bottom pill nav
  // ─────────────────────────────────────────────────────────────

  Widget _buildPhoneLayout() {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    final r = context.r;
    return Container(
      height: r.navBarHeight,
      padding: EdgeInsets.fromLTRB(r.hPad, 0, r.hPad, r.safePadding.bottom + 10),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _destinations.asMap().entries.map((entry) {
            return _buildNavItem(entry.key, entry.value);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, _NavDestination destination) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? destination.activeIcon : destination.icon,
              color: isActive ? Colors.white : AppColors.textSecondary.withValues(alpha: 0.5),
              size: 22,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                destination.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Value object for nav items
// ─────────────────────────────────────────────────────────────
class _NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavDestination({required this.icon, required this.activeIcon, required this.label});
}
