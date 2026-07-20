import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../utils/session_manager.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  User? _user;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  
  late AnimationController _listController;
  bool _isAboutExpanded = false;

  final GlobalKey _avatarKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _loadData();
  }

  @override
  void dispose() {
    _listController.dispose();
    _hideOverlay();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = await SessionManager.getUser();
    if (mounted) setState(() => _user = user);
    if (user != null && mounted) _listController.forward();
  }

  void _togglePickerMenu() {
    if (_isUploading) return;
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
    final renderBox = _avatarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
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
              top: offset.dy + size.height + 15,
              left: offset.dx + (size.width / 2) - 100, // centered below avatar
              child: Material(
                color: Colors.transparent,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, val, child) {
                    return Transform.scale(
                      scale: val,
                      alignment: Alignment.topCenter,
                      child: Opacity(opacity: val, child: child),
                    );
                  },
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: AppColors.vibrantTealStart.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 15))
                      ],
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
      splashColor: AppColors.vibrantTealStart.withValues(alpha: 0.1),
      highlightColor: AppColors.vibrantTealStart.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.vibrantTealStart.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.vibrantTealStart, size: 18),
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

  Widget _buildStandardCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: AppDecorations.standardCard.copyWith(
        color: Colors.white,
      ),
      child: child,
    );
  }

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
                        _buildAnimatedSection(0, _buildHeader()),
                        _buildAnimatedSection(1, _buildStatsGrid()),
                        _buildAnimatedSection(2, _buildAboutSection()),
                        _buildAnimatedSection(3, _buildDetailsSection()),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildAnimatedSection(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 700 + (index * 150)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutExpo,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildHeader() {
    final r = context.r;
    final double avatarSize = r.avatarLg + 20;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(r.hPad, r.safePadding.top + 30, r.hPad, 30),
      child: Column(
        children: [
          // Profile Image with Magic Glow
          Stack(
            alignment: Alignment.center,
            key: _avatarKey,
            clipBehavior: Clip.none,
            children: [
              // Circular Image Container
              Container(
                width: avatarSize, height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: AppShadows.medium,
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
              // Glass Context Trigger (Top Right)
              Positioned(
                top: 5, right: -5,
                child: GestureDetector(
                  onTap: _togglePickerMenu,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: const Icon(Icons.edit_rounded, color: AppColors.vibrantTealStart, size: 16),
                      ),
                    ),
                  ),
                ),
              ),
              // Qualification Badge (Bottom Right)
              Positioned(
                bottom: 0, right: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [const Color(0xFF1F6B4A).withValues(alpha: 0.9), const Color(0xFF1F6B4A).withValues(alpha: 0.9)]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Text(
                        _user!.qualification?.toUpperCase() ?? "MBBS",
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _user!.fullName ?? "Dr. ${_user!.username}",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text(
            _user!.specialization ?? "General Physician",
            style: TextStyle(fontSize: 15, color: Colors.blueGrey.shade600, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
           _buildStandardCard(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSmallBadge(Icons.star_rounded, "4.8", Colors.orange),
                  _buildDot(),
                  _buildSmallBadge(Icons.people_alt_rounded, "19+ Patients", const Color(0xFF1F6B4A)),
                  _buildDot(),
                  _buildSmallBadge(Icons.workspace_premium_rounded, "${_user!.experienceYears ?? '5'} Years", Colors.blueAccent),
                ],
              ),
           ),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.blueGrey.shade800)),
      ],
    );
  }

  Widget _buildDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.blueGrey.withValues(alpha: 0.3), shape: BoxShape.circle)),
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
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildVibrantStatCard("19+", "Patients", Icons.people_outline_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildVibrantStatCard("${_user?.experienceYears ?? '5'}+", "Years", Icons.military_tech_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildVibrantStatCard("98%", "Success", Icons.trending_up_rounded)),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildVibrantStatCard(String value, String label, IconData icon) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.standardCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: AppDecorations.tealChip,
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900)),
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: _buildStandardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFF1F6B4A), borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                const Text("About Doctor", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: Text(
                "Experienced ${_user!.specialization ?? 'General Physician'} specializing in primary healthcare and patient wellness. Dedicated to providing high-quality medical services with cutting edge precision instrumentation and a patient-first approach. Proven track record of high success rates across diverse cases." +
                (_isAboutExpanded ? "\n\nAdditional background includes years of specialized clinic practice and numerous positive outcomes in complex diagnosis scenarios." : ""),
                style: TextStyle(color: Colors.blueGrey.shade700, height: 1.6, fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: _isAboutExpanded ? 10 : 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _isAboutExpanded = !_isAboutExpanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_isAboutExpanded ? "Show Less" : "Read More", style: const TextStyle(color: Color(0xFF1F6B4A), fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _isAboutExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF1F6B4A)),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _buildStandardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFF1F6B4A), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 12),
                    const Text("Professional Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  ],
                ),
                GestureDetector(
                  onTap: _showEditProfileSheet,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF1F6B4A).withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.edit_rounded, color: Color(0xFF1F6B4A), size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(Icons.school_rounded, "Degree", _user!.qualification ?? "MBBS"),
            _buildDetailRow(Icons.medical_services_rounded, "Department", _user!.specialization ?? "General Medicine"),
            _buildDetailRow(Icons.badge_rounded, "Clinical ID", _user!.id),
            _buildDetailRow(Icons.phone_rounded, "Phone", _user!.phoneNumber ?? "N/A"),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton.icon(
                onPressed: _handleSignOut,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                label: const Text("Sign Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800, fontSize: 14)),
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
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1)),
            ),
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
                      backgroundColor: const Color(0xFF1F6B4A),
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
        Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF1F6B4A).withValues(alpha: 0.5), size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.black12, width: 1)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.black12, width: 1)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1F6B4A), width: 1.5)),
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
              color: const Color(0xFF1F6B4A).withValues(alpha: 0.1), 
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1F6B4A).withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: const Color(0xFF1F6B4A), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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

