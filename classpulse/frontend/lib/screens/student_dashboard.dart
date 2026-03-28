import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../data/mock_data.dart';
import '../services/api_service.dart';
import 'tabs/student_home_tab.dart';
import 'tabs/student_sessions_tab.dart';
import 'student_session_screen.dart';
import '../widgets/scanner_overlay.dart';
import 'login_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    StudentHomeTab(),
    StudentSessionsTab(),
  ];

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      HapticFeedback.lightImpact();
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _tabs,
              ),
            ),
          ],
        ),
      ),
      extendBody: true,
      floatingActionButton: _buildCenterFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildNotchedBottomNav(),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Text(
            'ClassPulse',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          // Student avatar
          GestureDetector(
            onTap: () => _showProfileSheet(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text(
                  'AS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Center FAB (Join Session) ──────────────────────────────────────────

  Widget _buildCenterFAB() {
    return SizedBox(
      height: 52,
      width: 52,
      child: FloatingActionButton(
        elevation: 8,
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showJoinSheet(context);
        },
        child: const Icon(
          Icons.login_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  // ── Notched Bottom Nav ─────────────────────────────────────────────────

  Widget _buildNotchedBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      color: AppColors.navBarBackground,
      elevation: 16,
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
          const SizedBox(width: 48),
          _buildNavItem(
              1, Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'My Sessions'),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              size: 24,
              color: isActive ? AppColors.navBarActive : AppColors.navBarInactive,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.navBarActive : AppColors.navBarInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Join Session Sheet ─────────────────────────────────────────────────

  void _showJoinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _JoinSessionSheet(
        onJoinByCode: (code) {
          Navigator.pop(ctx);
          _joinWithCode(code);
        },
        onScanQR: () {
          Navigator.pop(ctx);
          _showScanner();
        },
      ),
    );
  }

  void _joinWithCode(String code) async {
    final result = await ApiService.joinSession(
      sessionCode: code,
      rollNumber: ApiService.teacherId ?? 'student_app',
    );

    if (!mounted) return;

    if (result != null && result['status'] == 'success') {
      final session = LectureSlot(
        time: 'Live',
        className: result['class_name'] ?? 'Class',
        subject: result['subject'] ?? 'Subject',
        topic: result['topic'] ?? 'Topic',
        isCurrentOrPast: true,
        joinCode: code,
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StudentSessionScreen(session: session),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Invalid code. No active session found.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: ScannerOverlay(
            onClose: () => Navigator.pop(context),
            onCodeScanned: (code) {
              Navigator.pop(context);
              // Extract session code from QR URL or plain code
              String joinCode = code;
              try {
                final uri = Uri.parse(code);
                final codeParam = uri.queryParameters['code'];
                if (codeParam != null && codeParam.length == 4) {
                  joinCode = codeParam;
                }
              } catch (_) {}
              // Fallback: take last 4 chars if it looks like a number
              if (joinCode.length > 4) {
                final digits = joinCode.replaceAll(RegExp(r'\D'), '');
                if (digits.length >= 4) {
                  joinCode = digits.substring(digits.length - 4);
                }
              }
              _joinWithCode(joinCode);
            },
            onEnterCodeManually: () {
              Navigator.pop(context); // Close scanner
              // Show join sheet with code input already open
              _showJoinSheetWithCodeInput();
            },
          ),
        ),
      ),
    );
  }

  void _showJoinSheetWithCodeInput() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _JoinSessionSheet(
        onJoinByCode: (code) {
          Navigator.pop(ctx);
          _joinWithCode(code);
        },
        onScanQR: () {
          Navigator.pop(ctx);
          _showScanner();
        },
        startWithCodeInput: true,
      ),
    );
  }

  // ── Profile Sheet ─────────────────────────────────────────────────────

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                ),
                child: const Center(
                  child: Text(
                    'AS',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                ApiService.teacherId ?? 'Student',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Student',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Close profile sheet
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning, width: 1.5),
                  ),
                  child: const Center(
                    child: Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }
}

// ── Join Session Bottom Sheet ────────────────────────────────────────────────

class _JoinSessionSheet extends StatefulWidget {
  final Function(String code) onJoinByCode;
  final VoidCallback onScanQR;
  final bool startWithCodeInput;

  const _JoinSessionSheet({
    required this.onJoinByCode,
    required this.onScanQR,
    this.startWithCodeInput = false,
  });

  @override
  State<_JoinSessionSheet> createState() => _JoinSessionSheetState();
}

class _JoinSessionSheetState extends State<_JoinSessionSheet> {
  late bool _showCodeInput;
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _showCodeInput = widget.startWithCodeInput;

    // Auto-focus if starting with code input
    if (_showCodeInput) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _codeFocusNode.requestFocus();
      });
    }

    // Listen for changes to rebuild the UI
    _codeController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  bool get _isCodeComplete => _codeController.text.length == 4;

  void _onJoin() {
    if (_isCodeComplete) {
      HapticFeedback.mediumImpact();
      widget.onJoinByCode(_codeController.text);
    }
  }

  void _switchToCodeInput() {
    HapticFeedback.lightImpact();
    setState(() => _showCodeInput = true);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _codeFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Join Session',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enter the code shared by your teacher or scan the QR',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            if (!_showCodeInput) ...[
              // Two options
              _buildOptionTile(
                icon: Icons.dialpad_rounded,
                title: 'Join by Code',
                subtitle: 'Enter 4-digit session code',
                color: AppColors.primary,
                onTap: _switchToCodeInput,
              ),
              const SizedBox(height: 12),
              _buildOptionTile(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scan QR Code',
                subtitle: 'Point camera at the session QR',
                color: AppColors.success,
                onTap: widget.onScanQR,
              ),
            ] else ...[
              // ── Code input using single hidden TextField ──────────
              GestureDetector(
                onTap: () => _codeFocusNode.requestFocus(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Hidden text field that handles all input
                    Opacity(
                      opacity: 0,
                      child: SizedBox(
                        height: 0,
                        child: TextField(
                          controller: _codeController,
                          focusNode: _codeFocusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          autofocus: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            if (value.length == 4) {
                              _codeFocusNode.unfocus();
                            }
                          },
                        ),
                      ),
                    ),
                    // Visual digit boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        final text = _codeController.text;
                        final hasDigit = i < text.length;
                        final isActive = i == text.length && _codeFocusNode.hasFocus;
                        final isFilled = hasDigit;

                        return Container(
                          width: 56,
                          height: 64,
                          margin: EdgeInsets.only(right: i < 3 ? 12 : 0),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primary
                                  : isFilled
                                      ? AppColors.primary.withValues(alpha: 0.3)
                                      : AppColors.divider,
                              width: isActive ? 2 : 1.5,
                            ),
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 100),
                              child: hasDigit
                                  ? Text(
                                      text[i],
                                      key: ValueKey('digit_${i}_${text[i]}'),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    )
                                  : isActive
                                      ? Container(
                                          key: const ValueKey('cursor'),
                                          width: 2,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius:
                                                BorderRadius.circular(1),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Join button
              GestureDetector(
                onTap: _isCodeComplete ? _onJoin : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _isCodeComplete
                        ? AppColors.primary
                        : AppColors.buttonDisabled,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Join Session',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _isCodeComplete
                            ? Colors.white
                            : AppColors.buttonDisabledText,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Back to options
              GestureDetector(
                onTap: () {
                  setState(() => _showCodeInput = false);
                  _codeController.clear();
                },
                child: const Text(
                  'Back to options',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],

            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 1),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.5), size: 22),
          ],
        ),
      ),
    );
  }
}

