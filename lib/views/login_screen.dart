import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../utils/session_manager.dart';
import 'main_navigation_container.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  // ── Original state variables (UNCHANGED) ─────────────────────────────────
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = false;
  final ApiService _apiService = ApiService();
  bool _obscurePassword = true;
  bool _isRememberMe = false;
  String? _selectedBranch;

  // ── Premium Color Palette ─────────────────────────────────────────────────
  static const Color _primaryGreen = Color(0xFF1F6B4A);
  static const Color _bgCream = Color(0xFFF3EFE6);
  static const Color _textSlate = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  // ── Animation Controllers ─────────────────────────────────────────────────
  late AnimationController _bgAnimCtrl;
  bool _accessBtnPressed = false;

  @override
  void initState() {
    super.initState();
    _bgAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _loadSavedCredentials();
  }

  // ── Original Methods (UNCHANGED) ─────────────────────────────────────────

  Future<void> _loadSavedCredentials() async {
    final creds = await SessionManager.getCredentials();
    if (creds['username'] != null && creds['password'] != null) {
      setState(() {
        _usernameController.text = creds['username']!;
        _passwordController.text = creds['password']!;
        _isRememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _bgAnimCtrl.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.login(
        _usernameController.text.trim(),
        _passwordController.text,
        _selectedBranch ?? 'GM Hospital - Nagarabhavi',
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      final user = result['user'] as User?;
      final String? error = result['error'] as String?;
      if (user != null) {
        await SessionManager.saveUser(user);
        if (_isRememberMe) {
          await SessionManager.saveCredentials(
            _usernameController.text.trim(),
            _passwordController.text,
          );
        } else {
          await SessionManager.clearCredentials();
        }
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainNavigationContainer()),
              );
            }
          });
        }
      } else {
        _showErrorDialog(error ?? "Login failed. Please check your credentials.");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog("A critical error occurred: $e");
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text("Connection Error", style: TextStyle(color: _textSlate)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: _textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: _primaryGreen)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      body: Stack(
        children: [
          // 1. Animated soft background
          Positioned.fill(
            child: CustomPaint(
              painter: _MedicalBackgroundPainter(_bgAnimCtrl),
            ),
          ),

          // 2. Main scrollable content with animated switcher
          SafeArea(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 480),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _isLoginMode ? _buildLoginForm() : _buildWelcomeView(),
              ),
            ),
          ),

          // 3. Footer
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                "© 2026 GM Hospital Group  ·  Secure Clinical Portal",
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 10,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Welcome View ──────────────────────────────────────────────────────────

  Widget _buildWelcomeView() {
    final r = context.r;
    final isDesktop = r.isTablet || r.isDesktop;

    return SingleChildScrollView(
      key: const ValueKey('WelcomeView'),
      padding: EdgeInsets.fromLTRB(r.hPad, 20, r.hPad, 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated logo with pulse rings
          _AnimatedLogoWidget(primaryColor: _primaryGreen, bgCream: _bgCream),
          const SizedBox(height: 22),

          // Hospital name
          const Text(
            "GM HOSPITAL",
            style: TextStyle(
              color: _primaryGreen,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 5,
            ),
          ),
          const SizedBox(height: 10),

          // Divider with heartbeat icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 1, width: 48,
                color: _primaryGreen.withValues(alpha: 0.22),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.monitor_heart_rounded, color: _primaryGreen, size: 18),
              ),
              Container(
                height: 1, width: 48,
                color: _primaryGreen.withValues(alpha: 0.22),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tagline pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(
              color: _primaryGreen.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: _primaryGreen.withValues(alpha: 0.12)),
            ),
            child: const Text(
              "Healing Hands · Caring Hearts · Innovation in Every Pulse",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Branch section header
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.domain_add_rounded, color: _primaryGreen, size: 17),
              ),
              const SizedBox(width: 10),
              const Text(
                "Select Hospital Branch",
                style: TextStyle(
                  color: _textSlate,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Choose your facility to continue",
            style: TextStyle(color: _textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Branch cards — responsive layout
          isDesktop
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBranchCard(
                      title: "GM Hospital\nNagarabhavi",
                      badge: "MAIN BRANCH",
                      desc: "Main Hospital Campus",
                      loc: "Nagarabhavi, Bengaluru",
                    ),
                    const SizedBox(width: 20),
                    _buildBranchCard(
                      title: "GM Hospital\nBasaveshwaranagar",
                      badge: "SUB BRANCH",
                      desc: "Branch Hospital",
                      loc: "Basaveshwaranagar, Bengaluru",
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildBranchCard(
                      title: "GM Hospital\nNagarabhavi",
                      badge: "MAIN BRANCH",
                      desc: "Main Hospital Campus",
                      loc: "Nagarabhavi, Bengaluru",
                    ),
                    const SizedBox(height: 16),
                    _buildBranchCard(
                      title: "GM Hospital\nBasaveshwaranagar",
                      badge: "SUB BRANCH",
                      desc: "Branch Hospital",
                      loc: "Basaveshwaranagar, Bengaluru",
                    ),
                  ],
                ),

          const SizedBox(height: 28),

          // Security trust banner
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _primaryGreen.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryGreen.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_rounded, color: _primaryGreen, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Secure & Trusted Healthcare",
                        style: TextStyle(
                          color: _textSlate,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "HIPAA compliant · End-to-end encrypted · Zero-trust architecture",
                        style: TextStyle(color: _textSecondary, fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.verified_rounded, color: _primaryGreen.withValues(alpha: 0.35), size: 30),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ACCESS PORTAL button with press animation
          Container(
            constraints: const BoxConstraints(maxWidth: 500),
            width: double.infinity,
            child: AnimatedOpacity(
              opacity: _selectedBranch != null ? 1.0 : 0.45,
              duration: AppAnimations.normal,
              child: GestureDetector(
                onTapDown: _selectedBranch != null
                    ? (_) => setState(() => _accessBtnPressed = true)
                    : null,
                onTapUp: _selectedBranch != null
                    ? (_) {
                        setState(() => _accessBtnPressed = false);
                        setState(() => _isLoginMode = true);
                      }
                    : null,
                onTapCancel: () => setState(() => _accessBtnPressed = false),
                child: AnimatedScale(
                  scale: _accessBtnPressed ? 0.97 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryGreen, Color(0xFF2A8A5E)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: _selectedBranch != null
                          ? [
                              BoxShadow(
                                color: _primaryGreen.withValues(alpha: 0.38),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_open_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          "ACCESS PORTAL",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Branch Card ───────────────────────────────────────────────────────────

  Widget _buildBranchCard({
    required String title,
    required String badge,
    required String desc,
    required String loc,
  }) {
    final rawTitle = title.replaceAll('\n', ' - ');   // LOGIC UNCHANGED
    final isSelected = _selectedBranch == rawTitle;

    return GestureDetector(
      onTap: () => setState(() => _selectedBranch = rawTitle),
      child: AnimatedContainer(
        duration: AppAnimations.normal,
        curve: Curves.easeOutCubic,
        width: 288,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isSelected ? _primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected ? Colors.transparent : _primaryGreen.withValues(alpha: 0.14),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryGreen.withValues(alpha: 0.32),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge + check row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.18)
                        : _primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: isSelected ? Colors.white : _primaryGreen,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: AppAnimations.normal,
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : _primaryGreen.withValues(alpha: 0.07),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: AppAnimations.fast,
                      child: Icon(
                        isSelected ? Icons.check_rounded : Icons.circle_outlined,
                        key: ValueKey(isSelected),
                        color: isSelected ? _primaryGreen : _primaryGreen.withValues(alpha: 0.28),
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Hospital icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.12) : _bgCream,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_hospital_rounded,
                  color: isSelected ? Colors.white : _primaryGreen,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : _textSlate,
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  height: 1.3,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(height: 14),

            Divider(
              color: isSelected ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFF3EFE6),
              height: 1,
            ),
            const SizedBox(height: 14),

            Center(
              child: Text(
                desc,
                style: TextStyle(
                  color: isSelected ? Colors.white70 : _textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: isSelected ? Colors.white60 : _textSecondary,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  loc,
                  style: TextStyle(
                    color: isSelected ? Colors.white60 : _textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Login Form ────────────────────────────────────────────────────────────

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      key: const ValueKey('LoginForm'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 440),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: _primaryGreen.withValues(alpha: 0.1),
                  blurRadius: 56,
                  offset: const Offset(0, 26),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Column(
                children: [
                  // Green header strip
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryGreen, Color(0xFF2A8A5E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () => setState(() => _isLoginMode = false),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Column(
                            children: [
                              Text(
                                "CLINICIAN LOGIN",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Welcome Back",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Medical icon decoration
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form body
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildInputField(
                            label: "Username / Doctor ID",
                            icon: Icons.person_outline_rounded,
                            controller: _usernameController,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? "Username required" : null,
                          ),
                          const SizedBox(height: 18),
                          _buildInputField(
                            label: "Password",
                            icon: Icons.lock_outline_rounded,
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? "Password required" : null,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _textSecondary,
                                size: 18,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Remember me + forgot
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Checkbox(
                                      value: _isRememberMe,
                                      onChanged: (v) =>
                                          setState(() => _isRememberMe = v ?? false),
                                      side: const BorderSide(color: _textSecondary),
                                      activeColor: _primaryGreen,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Remember me",
                                    style: TextStyle(
                                      color: _textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: _primaryGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Sign In button
                          GestureDetector(
                            onTap: _isLoading ? null : _handleLogin,
                            child: AnimatedContainer(
                              duration: AppAnimations.fast,
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _primaryGreen,
                                    _isLoading
                                        ? _primaryGreen
                                        : const Color(0xFF2A8A5E),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryGreen.withValues(
                                      alpha: _isLoading ? 0.1 : 0.3,
                                    ),
                                    blurRadius: 22,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.login_rounded,
                                              color: Colors.white, size: 19),
                                          SizedBox(width: 10),
                                          Text(
                                            "Sign In to Portal",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
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
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Field Helper ────────────────────────────────────────────────────

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(
        color: _textSlate,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: _textSecondary.withValues(alpha: 0.85),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: _primaryGreen,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: Icon(icon, color: _primaryGreen, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _bgCream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}

// ── Animated Logo Widget ──────────────────────────────────────────────────────

class _AnimatedLogoWidget extends StatefulWidget {
  final Color primaryColor;
  final Color bgCream;

  const _AnimatedLogoWidget({required this.primaryColor, required this.bgCream});

  @override
  State<_AnimatedLogoWidget> createState() => _AnimatedLogoWidgetState();
}

class _AnimatedLogoWidgetState extends State<_AnimatedLogoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        return SizedBox(
          width: 134,
          height: 134,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer fading ring
              Container(
                width: 124 + (_pulseCtrl.value * 10),
                height: 124 + (_pulseCtrl.value * 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.primaryColor.withValues(
                      alpha: 0.07 + (_pulseCtrl.value * 0.06),
                    ),
                    width: 1.5,
                  ),
                ),
              ),
              // Inner ring
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.primaryColor.withValues(alpha: 0.14),
                    width: 1,
                  ),
                ),
              ),
              // Logo circle
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withValues(alpha: 0.22),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/gm_logoo.png',
                    height: 50,
                    width: 50,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.health_and_safety_rounded,
                      size: 44,
                      color: widget.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Background Painter (UNCHANGED logic, slightly refined) ────────────────────

class _MedicalBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  _MedicalBackgroundPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    // Top-left radial glow
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF1F6B4A).withValues(alpha: 0.07),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(
        size.width * 0.15 + (animation.value * 40),
        size.height * 0.25,
      ),
      radius: 360,
    ));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Bottom-right radial glow
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF1F6B4A).withValues(alpha: 0.04),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(
        size.width * 0.9 - (animation.value * 30),
        size.height * 0.82,
      ),
      radius: 280,
    ));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Elegant wave at bottom
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.88);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.78,
      size.width * 0.5,
      size.height * 0.86,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.94,
      size.width,
      size.height * 0.82,
    );
    path.lineTo(size.width, size.height);
    path.close();

    paint.shader = LinearGradient(
      colors: [
        const Color(0xFF1F6B4A).withValues(alpha: 0.08),
        const Color(0xFF1F6B4A).withValues(alpha: 0.02),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(
      Rect.fromLTWH(0, size.height * 0.75, size.width, size.height * 0.25),
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
