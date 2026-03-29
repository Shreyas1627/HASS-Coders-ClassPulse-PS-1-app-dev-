import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import 'teacher_dashboard.dart';
import 'student_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String _role = 'student'; // 'student' or 'teacher'

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  void _onLogin() {
    if (!_isFormValid) return;
    HapticFeedback.mediumImpact();

    // Store identity for API calls
    final email = _emailController.text.trim();
    ApiService.setTeacherId(email);
    if (_role == 'student') {
      ApiService.setClassName('10A'); // Default class for student
      ApiService.setRollNumber(email);
    }

    final destination = _role == 'teacher'
        ? const TeacherDashboard()
        : const StudentDashboard();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.jpeg',
                    height: 36,
                    width: 36,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ClassPulse',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sign in to continue to your classes',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Email / Username
                    _buildLabel('Email or Username'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Enter your email or username',
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 20),

                    // Password
                    _buildLabel('Password'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Enter your password',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePassword,
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Role selector
                    _buildLabel('I am a'),
                    const SizedBox(height: 10),
                    _buildRoleSelector(),

                    const SizedBox(height: 24),

                    // Remember me
                    _buildRememberMe(),

                    const SizedBox(height: 28),

                    // Login button
                    _buildLoginButton(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            SizedBox(height: bottomPadding > 0 ? 8 : 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pinBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.pinBorder, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 15,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: suffixIcon,
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minHeight: 20, minWidth: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: [
        Expanded(child: _buildRoleOption('student', 'Student', Icons.school_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _buildRoleOption('teacher', 'Teacher', Icons.menu_book_outlined)),
      ],
    );
  }

  Widget _buildRoleOption(String value, String label, IconData icon) {
    final isSelected = _role == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _role = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.pinBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.pinBorder,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRememberMe() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _rememberMe = !_rememberMe);
      },
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _rememberMe ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _rememberMe ? AppColors.primary : AppColors.pinBorder,
                width: 1.5,
              ),
            ),
            child: _rememberMe
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          const Text(
            'Remember me',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    final isActive = _isFormValid;

    return GestureDetector(
      onTap: isActive ? _onLogin : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: isActive ? AppColors.buttonEnabled : AppColors.buttonDisabled,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            'Login',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : AppColors.buttonDisabledText,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
