import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../data/mock_data.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../widgets/pin_display.dart';
import '../widgets/numpad.dart';
import '../widgets/scanner_overlay.dart';
import 'login_screen.dart';
import 'student_session_screen.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> with TickerProviderStateMixin {
  String _pin = '';
  bool _showScanner = false;

  late AnimationController _joinButtonController;
  late Animation<double> _joinButtonScale;

  @override
  void initState() {
    super.initState();
    _joinButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _joinButtonScale = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _joinButtonController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _joinButtonController.dispose();
    super.dispose();
  }

  void _onNumberPressed(int number) {
    if (_pin.length < 4) {
      HapticFeedback.lightImpact();
      setState(() {
        _pin += number.toString();
      });
      if (_pin.length == 4) {
        _joinButtonController.forward();
      }
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty) {
      HapticFeedback.lightImpact();
      final wasFull = _pin.length == 4;
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
      if (wasFull) {
        _joinButtonController.reverse();
      }
    }
  }

  void _onJoinPressed() async {
    if (_pin.length == 4) {
      HapticFeedback.mediumImpact();
      final pos = await LocationService.getCurrentLocation();
      final result = await ApiService.joinSession(
        sessionCode: _pin,
        rollNumber: 'student_app',
        latitude: pos?.latitude,
        longitude: pos?.longitude,
      );

      if (!mounted) return;

      if (result != null && result['status'] == 'success') {
        final subtopicRaw = result['subtopic'] as String? ?? '';
        final parsedSubtopics = subtopicRaw.isNotEmpty
            ? subtopicRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
            : <String>[];

        final session = LectureSlot(
          time: 'Live',
          className: result['class_name'] ?? 'Class',
          subject: result['subject'] ?? 'Subject',
          topic: result['topic'] ?? 'Topic',
          isCurrentOrPast: true,
          joinCode: _pin,
          subtopics: parsedSubtopics,
          currentSubtopicIndex: result['current_subtopic_index'] as int? ?? 0,
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudentSessionScreen(session: session),
          ),
        );
      } else {
        final msg = (result != null && result['error'] != null)
            ? result['error']
            : 'Invalid code. No active session found.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _toggleScanner() {
    HapticFeedback.mediumImpact();
    setState(() {
      _showScanner = !_showScanner;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main content — no gradient, flat background
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),

                Expanded(
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      const Text(
                        'Enter Session Code',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 24),

                      PinDisplay(pin: _pin),

                      const Spacer(flex: 2),

                      Numpad(
                        onNumberPressed: _onNumberPressed,
                        onDeletePressed: _onDeletePressed,
                      ),

                      const SizedBox(height: 24),

                      _buildJoinButton(),

                      const Spacer(flex: 1),

                      _buildFooter(),
                      SizedBox(height: bottomPadding > 0 ? 8 : 16),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_showScanner)
            ScannerOverlay(onClose: _toggleScanner),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App name — solid blue, no gradient
          const Text(
            'ClassPulse',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),

          // Scanner button — flat, no shadow
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleScanner,
              borderRadius: BorderRadius.circular(12),
              splashColor: AppColors.primary.withValues(alpha: 0.08),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton() {
    final isActive = _pin.length == 4;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36), // ~80% width
      child: AnimatedBuilder(
        animation: _joinButtonScale,
        builder: (context, child) {
          return Transform.scale(
            scale: isActive ? _joinButtonScale.value : 1.0,
            child: child,
          );
        },
        child: GestureDetector(
          onTap: isActive ? _onJoinPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: isActive ? AppColors.buttonEnabled : AppColors.buttonDisabled,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'Join Session',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppColors.buttonDisabledText,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Want to login? ',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          child: const Text(
            'Login',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
