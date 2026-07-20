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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = false;
  final ApiService _apiService = ApiService();
  bool _obscurePassword = true;
  bool _isRememberMe = false;
  String? _selectedBranch;

  // Premium Colors
  static const Color _primaryGreen = Color(0xFF1F6B4A);
  static const Color _bgCream = Color(0xFFF3EFE6);
  static const Color _textSlate = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  late AnimationController _bgAnimCtrl;

  @override
  void initState() {
    super.initState();
    _bgAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
    _loadSavedCredentials();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      body: Stack(
        children: [
          // 1. Premium Medical Background
          Positioned.fill(
            child: CustomPaint(
              painter: _MedicalBackgroundPainter(_bgAnimCtrl),
            ),
          ),
          
          // 2. Main Content
          SafeArea(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  );
                },
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
                "© 2026 GM Hospital Group | Secure Clinical Portal",
                style: TextStyle(color: _textSecondary, fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView() {
    final r = context.r;
    final isDesktop = r.isTablet || r.isDesktop;
    
    return SingleChildScrollView(
      key: const ValueKey('WelcomeView'),
      padding: EdgeInsets.symmetric(horizontal: r.hPad, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _primaryGreen.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Image.asset(
              'assets/gm_logoo.png',
              height: 70,
              width: 70,
              errorBuilder: (_, __, ___) => const Icon(Icons.health_and_safety_rounded, size: 70, color: _primaryGreen),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          const Text(
            "GM HOSPITAL",
            style: TextStyle(
              color: _primaryGreen,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 12),
          
          // Decorative Divider
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 1, width: 40, color: _primaryGreen.withValues(alpha: 0.3)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.monitor_heart_rounded, color: _primaryGreen, size: 18),
              ),
              Container(height: 1, width: 40, color: _primaryGreen.withValues(alpha: 0.3)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Subtitle
          const Text(
            "Healing Hands. Caring Hearts.\nInnovation in Every Pulse.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          
          // Branch Selection Title
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.domain_add_rounded, color: _primaryGreen, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Select Hospital Branch",
                style: TextStyle(color: _textSlate, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Cards
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
                    const SizedBox(width: 24),
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
                    const SizedBox(height: 20),
                    _buildBranchCard(
                      title: "GM Hospital\nBasaveshwaranagar",
                      badge: "SUB BRANCH",
                      desc: "Branch Hospital",
                      loc: "Basaveshwaranagar, Bengaluru",
                    ),
                  ],
                ),
          
          const SizedBox(height: 40),
          
          // Security Banner
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: _primaryGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _primaryGreen.withValues(alpha: 0.1), blurRadius: 10)]),
                  child: const Icon(Icons.shield_rounded, color: _primaryGreen, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Secure & Trusted Healthcare", style: TextStyle(color: _textSlate, fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(height: 4),
                      Text("Your health data is safe with us. We ensure confidentiality, security & quality care.", style: TextStyle(color: _textSecondary, fontSize: 11, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.admin_panel_settings_rounded, color: _primaryGreen.withValues(alpha: 0.2), size: 40),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Access Portal Button
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryGreen, Color(0xFF26885E)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _selectedBranch != null ? () => setState(() => _isLoginMode = true) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded, color: _selectedBranch != null ? Colors.white : Colors.white38, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    "ACCESS PORTAL",
                    style: TextStyle(color: _selectedBranch != null ? Colors.white : Colors.white38, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 15),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded, color: _selectedBranch != null ? Colors.white : Colors.white38, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBranchCard({required String title, required String badge, required String desc, required String loc}) {
    final rawTitle = title.replaceAll('\n', ' - ');
    final isSelected = _selectedBranch == rawTitle;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedBranch = rawTitle),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? const LinearGradient(colors: [_primaryGreen, Color(0xFF154C34)], begin: Alignment.topLeft, end: Alignment.bottomRight) 
              : const LinearGradient(colors: [Colors.white, Colors.white]),
          border: Border.all(
            color: isSelected ? Colors.transparent : _primaryGreen.withValues(alpha: 0.3),
            width: isSelected ? 0 : 1,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (isSelected) BoxShadow(color: _primaryGreen.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
            if (!isSelected) BoxShadow(color: _textSlate.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.2) : _bgCream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(badge, style: TextStyle(color: isSelected ? Colors.white : _primaryGreen, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
                Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined, color: isSelected ? Colors.white : _primaryGreen.withValues(alpha: 0.3), size: 24),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.1) : _bgCream,
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? Colors.white.withValues(alpha: 0.2) : _primaryGreen.withValues(alpha: 0.1), width: 2),
                ),
                child: Icon(Icons.local_hospital_rounded, color: isSelected ? Colors.white : _primaryGreen, size: 32),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(color: isSelected ? Colors.white : _textSlate, fontWeight: FontWeight.bold, fontSize: 16, height: 1.3),
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: isSelected ? Colors.white.withValues(alpha: 0.2) : _bgCream),
            const SizedBox(height: 16),
            Center(child: Text(desc, style: TextStyle(color: isSelected ? Colors.white70 : _textSecondary, fontSize: 11))),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_rounded, color: isSelected ? Colors.white70 : _textSecondary, size: 12),
                const SizedBox(width: 4),
                Text(loc, style: TextStyle(color: isSelected ? Colors.white70 : _textSecondary, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      key: const ValueKey('LoginForm'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: _primaryGreen.withValues(alpha: 0.08), blurRadius: 40, offset: const Offset(0, 20)),
              ],
            ),
            child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(() => _isLoginMode = false),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textSecondary, size: 20),
                            style: IconButton.styleFrom(backgroundColor: _bgCream),
                          ),
                          const Expanded(
                            child: Text(
                              "Clinician Login",
                              style: TextStyle(color: _textSlate, fontSize: 20, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 40), 
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Inputs
                      _buildInputField(
                        label: "Username / Doctor ID",
                        icon: Icons.person_outline_rounded,
                        controller: _usernameController,
                        validator: (v) => (v == null || v.isEmpty) ? "Username required" : null,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        label: "Password",
                        icon: Icons.lock_outline_rounded,
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        validator: (v) => (v == null || v.isEmpty) ? "Password required" : null,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: _textSecondary,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
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
                                  onChanged: (v) => setState(() => _isRememberMe = v ?? false),
                                  side: const BorderSide(color: _textSecondary),
                                  activeColor: _primaryGreen,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text("Remember me", style: TextStyle(color: _textSecondary, fontSize: 12)),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text("Forgot Password?", style: TextStyle(color: _primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Teal Gradient Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primaryGreen, Color(0xFF26885E)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: _primaryGreen.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Sign In to Portal", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white, fontSize: 15)),
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
      style: const TextStyle(color: _textSlate, fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: _primaryGreen, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _bgCream,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _primaryGreen, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.red.shade300, width: 1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}

class _MedicalBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  _MedicalBackgroundPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    // Soft animated radial glows
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF1F6B4A).withValues(alpha: 0.05),
        Colors.transparent,
      ],
      stops: const [0.0, 1.0],
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.2 + (animation.value * 50), size.height * 0.3), radius: 400));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Bottom elegant waves
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.85);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.75, size.width * 0.5, size.height * 0.85);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.95, size.width, size.height * 0.8);
    path.lineTo(size.width, size.height);
    path.close();

    paint.shader = LinearGradient(
      colors: [
        const Color(0xFF1F6B4A).withValues(alpha: 0.08),
        const Color(0xFF1F6B4A).withValues(alpha: 0.02),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}




