import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui';
import '../services/api_service.dart';
import '../models/user.dart';
import '../utils/session_manager.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  // ── State (UNCHANGED logic) ──────────────────────────────────────────────
  User? _user;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isAboutExpanded = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _avatarKey = GlobalKey();
  
  late AnimationController _revealController;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
    );
    _loadData();
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = await SessionManager.getUser();
    setState(() => _user = user);
    if (user != null) {
      _revealController.forward(from: 0);
    }
  }

  // ── Overlay / Picker Logic (UNCHANGED) ───────────────────────────────────

  void _togglePickerMenu() {
    if (_overlayEntry != null) {
      _hideOverlay();
    } else {
      _showOverlay();
    }
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    final renderBox = _avatarKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _hideOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              top: offset.dy + size.height + 10,
              left: offset.dx + size.width / 2 - 100,
              child: Material(
                color: Colors.transparent,
                child: TweenAnimationBuilder<double>(
                  duration: AppAnimations.fast,
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, val, child) => Opacity(
                    opacity: val,
                    child: Transform.scale(
                      scale: 0.95 + (0.05 * val),
                      child: child,
                    ),
                  ),
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                      boxShadow: AppShadows.elevated,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildPickerItem(Icons.camera_alt_rounded, "Take Photo", () => _pickAndUploadPhoto(ImageSource.camera, CameraDevice.rear)),
                            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
                            _buildPickerItem(Icons.camera_front_rounded, "Selfie", () => _pickAndUploadPhoto(ImageSource.camera, CameraDevice.front)),
                            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
                            _buildPickerItem(Icons.photo_library_rounded, "Gallery", () => _pickAndUploadPhoto(ImageSource.gallery, null)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildPickerItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        _hideOverlay();
        onTap();
      },
      splashColor: AppColors.primary.withValues(alpha: 0.1),
      highlightColor: AppColors.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source, CameraDevice? preferredCamera) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        preferredCameraDevice: preferredCamera ?? CameraDevice.rear,
        maxWidth: 1200, maxHeight: 1200, imageQuality: 85,
      );
      if (image == null) return;

      setState(() => _isUploading = true);
      final result = await ApiService().updateProfilePhoto(_user!.id, File(image.path));
      if (result['status'] == 'success') {
        final updatedUser = User(
          id: _user!.id, username: _user!.username, role: _user!.role,
          fullName: _user!.fullName, specialization: _user!.specialization, photo: result['photo_path'],
          qualification: _user!.qualification, experienceYears: _user!.experienceYears, phoneNumber: _user!.phoneNumber,
        );
        
        await SessionManager.saveUser(updatedUser);
        setState(() { _user = updatedUser; _isUploading = false; });
        
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile photo updated successfully!"), backgroundColor: AppColors.success));
      } else {
        setState(() => _isUploading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: ${result['message']}"), backgroundColor: AppColors.error));
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error picking image: $e"), backgroundColor: AppColors.error));
    }
  }

  String _getProfileImageUrl(String? path) {
    return ApiService.sanitizeImageUrl(path);
  }

  // ── Build Methods ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      body: _user == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeroHeader(),
                    _buildAnimatedSection(1, _buildStatsGrid()),
                    _buildAnimatedSection(2, _buildAboutSection()),
                    _buildAnimatedSection(3, _buildDetailsSection()),
                    const SizedBox(height: 120), // Bottom padding for nav
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAnimatedSection(int index, Widget child) {
    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, child) {
        // Create staggered cascade effect
        final delay = (index * 0.15).clamp(0.0, 1.0);
        final val = ((_revealController.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        
        return Opacity(
          opacity: val,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - val)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildHeroHeader() {
    final r = context.r;
    final double avatarSize = r.isTablet ? 140 : 120;
    
    return Stack(
      children: [
        // Premium Curved Background
        ClipPath(
          clipper: _HeaderClipper(),
          child: Container(
            height: 280,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF2A8A5E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CustomPaint(painter: _HeaderPatternPainter()),
          ),
        ),
        
        // Content
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(r.hPad, r.safePadding.top + 50, r.hPad, 30),
          child: Column(
            children: [
              // Avatar Stack
              Stack(
                alignment: Alignment.center,
                key: _avatarKey,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: avatarSize, height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: AppShadows.elevated,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(avatarSize / 2),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _user!.photo != null && _user!.photo!.isNotEmpty
                            ? Image.network(_getProfileImageUrl(_user!.photo), fit: BoxFit.cover)
                            : Image.asset('assets/doctor.jpeg', fit: BoxFit.cover),
                          if (_isUploading)
                             Container(
                               color: Colors.white.withValues(alpha: 0.7),
                               child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                             ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Edit Button
                  Positioned(
                    top: 0, right: 0,
                    child: GestureDetector(
                      onTap: _togglePickerMenu,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 2),
                          boxShadow: AppShadows.subtle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 16),
                      ),
                    ),
                  ),
                  
                  // Qualification Badge
                  Positioned(
                    bottom: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A), // Slate
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: Text(
                        _user!.qualification?.toUpperCase() ?? "MBBS",
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 11, 
                          fontWeight: FontWeight.w900, 
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Name and Title
              Text(
                _user!.fullName ?? "Dr. ${_user!.username}",
                style: const TextStyle(
                  fontSize: 26, 
                  fontWeight: FontWeight.w900, 
                  color: AppColors.textPrimary, 
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _user!.specialization ?? "General Physician",
                style: const TextStyle(
                  fontSize: 15, 
                  color: AppColors.primary, 
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final r = context.r;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.hPad),
      child: r.isTablet
          ? Row(
              children: [
                Expanded(child: _buildVibrantStatCard("19+", "Patients", Icons.people_outline_rounded)),
                const SizedBox(width: 16),
                Expanded(child: _buildVibrantStatCard("${_user?.experienceYears ?? '5'}+", "Years", Icons.military_tech_outlined)),
                const SizedBox(width: 16),
                Expanded(child: _buildVibrantStatCard("98%", "Success", Icons.trending_up_rounded)),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildVibrantStatCard("19+", "Patients", Icons.people_outline_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _buildVibrantStatCard("${_user?.experienceYears ?? '5'}+", "Years", Icons.military_tech_outlined)),
                const SizedBox(width: 12),
                Expanded(child: _buildVibrantStatCard("98%", "Success", Icons.trending_up_rounded)),
              ],
            ),
    );
  }

  Widget _buildVibrantStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value, 
            style: const TextStyle(
              color: AppColors.textPrimary, 
              fontSize: 20, 
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label, 
            style: const TextStyle(
              color: AppColors.textSecondary, 
              fontSize: 11, 
              fontWeight: FontWeight.w700, 
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.r.hPad, 24, context.r.hPad, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.subtle,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4, height: 20, 
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 12),
                const Text(
                  "About Doctor", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedSize(
              duration: AppAnimations.normal,
              curve: AppAnimations.spring,
              alignment: Alignment.topCenter,
              child: Text(
                "Experienced ${_user!.specialization ?? 'General Physician'} specializing in primary healthcare and patient wellness. Dedicated to providing high-quality medical services with cutting edge precision instrumentation and a patient-first approach." +
                (_isAboutExpanded ? "\n\nProven track record of high success rates across diverse cases. Additional background includes years of specialized clinic practice and numerous positive outcomes in complex diagnosis scenarios." : ""),
                style: const TextStyle(color: AppColors.textSecondary, height: 1.6, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _isAboutExpanded = !_isAboutExpanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isAboutExpanded ? "Show Less" : "Read More", 
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _isAboutExpanded ? 0.5 : 0.0,
                    duration: AppAnimations.normal,
                    child: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.r.hPad, 24, context.r.hPad, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.subtle,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4, height: 20, 
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Professional Details", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _showEditProfileSheet,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(Icons.school_rounded, "Degree", _user!.qualification ?? "MBBS"),
            _buildDetailRow(Icons.medical_services_rounded, "Department", _user!.specialization ?? "General Medicine"),
            _buildDetailRow(Icons.badge_rounded, "Clinical ID", _user!.id),
            _buildDetailRow(Icons.phone_rounded, "Phone", _user!.phoneNumber ?? "N/A"),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: TextButton.icon(
                onPressed: _handleSignOut,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                label: const Text(
                  "Sign Out", 
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet() {
    final nameC = TextEditingController(text: _user!.fullName);
    final specialC = TextEditingController(text: _user!.specialization);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.white.withValues(alpha: 0.95),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Edit Profile", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                const SizedBox(height: 24),
                _buildProfileModalField("Full Name", nameC, Icons.person_rounded),
                _buildProfileModalField("Specialization", specialC, Icons.medical_services_rounded),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileModalField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _handleSignOut() async {
    await SessionManager.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => const LoginScreen()), 
        (route) => false
      );
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08), 
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Header Shapes ──────────────────────────────────────────────────────

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 4, size.height, size.width / 2, size.height - 20);
    path.quadraticBezierTo(3 * size.width / 4, size.height - 40, size.width, size.height - 10);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    
    // Draw subtle medical cross watermark
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.3), 60, paint);
    
    final paintLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width * 0.1, size.height * 0.5), radius: 100), 
      0, 3.14, false, paintLine
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
