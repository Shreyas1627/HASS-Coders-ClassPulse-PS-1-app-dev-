import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../data/mock_data.dart';
import 'tabs/home_tab.dart';
import 'tabs/history_tab.dart';
import 'live_session_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeTab(),
    HistoryTab(),
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

  // ── App Bar (no + button, just logo + avatar) ──────────────────────────

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Logo
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

          // Teacher avatar
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showProfileSheet(context);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.avatarDefault.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppColors.avatarDefault.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text(
                  'RK',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.avatarDefault,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Center FAB (Create Session) ────────────────────────────────────────

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
          _showCreateSessionSheet(context);
        },
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  // ── Notched Bottom Navigation ──────────────────────────────────────────

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
          // Home tab
          _buildNavItem(
              0, Icons.home_rounded, Icons.home_outlined, 'Home'),
          // Spacer for FAB notch
          const SizedBox(width: 48),
          // History tab
          _buildNavItem(1, Icons.history_rounded,
              Icons.history_outlined, 'History'),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              size: 24,
              color:
                  isActive ? AppColors.navBarActive : AppColors.navBarInactive,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? AppColors.navBarActive
                    : AppColors.navBarInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Create Session Sheet (fully functional form) ────────────────────────

  void _showCreateSessionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return const _CreateSessionSheet();
      },
    );
  }

  // ── Profile Sheet ───────────────────────────────────────────────────────

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
              // Handle bar
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
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.avatarDefault.withValues(alpha: 0.15),
                ),
                child: const Center(
                  child: Text(
                    'RK',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.avatarDefault,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Prof. Rajesh Kumar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'rajesh.kumar@classpulse.edu',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Teacher · Mathematics & Science',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Logout
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to login
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.warning, width: 1.5),
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
              SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }
}

// ── Create Session Sheet (Stateful with real text fields + date picker) ──────

class _CreateSessionSheet extends StatefulWidget {
  const _CreateSessionSheet();

  @override
  State<_CreateSessionSheet> createState() => _CreateSessionSheetState();
}

class _CreateSessionSheetState extends State<_CreateSessionSheet> {
  final _classController = TextEditingController();
  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();
  DateTime? _selectedDateTime;

  @override
  void dispose() {
    _classController.dispose();
    _subjectController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _classController.text.trim().isNotEmpty &&
      _subjectController.text.trim().isNotEmpty &&
      _topicController.text.trim().isNotEmpty;

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: AppColors.surface,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  String get _formattedDateTime {
    if (_selectedDateTime == null) return '';
    final d = _selectedDateTime!;
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final amPm = d.hour >= 12 ? 'PM' : 'AM';
    final min = d.minute.toString().padLeft(2, '0');
    return '${months[d.month]} ${d.day}, ${d.year} at $hour:$min $amPm';
  }

  void _onCreateSession() {
    if (!_isFormValid) return;
    HapticFeedback.mediumImpact();

    // Create a mock session and navigate to it
    final newSession = LectureSlot(
      time: _formattedDateTime.isNotEmpty ? _formattedDateTime : 'Now',
      className: _classController.text.trim(),
      subject: _subjectController.text.trim(),
      topic: _topicController.text.trim(),
      isCurrentOrPast: true,
      joinCode: '${(1000 + (DateTime.now().millisecondsSinceEpoch % 9000))}',
    );

    Navigator.pop(context); // Close sheet
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveSessionScreen(session: newSession),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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
                'Create New Session',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manually create a session for your class. '
                'Students can join using the generated code.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Class field
              _buildTextField(
                controller: _classController,
                label: 'Class',
                hint: 'e.g. Class 10A, Div B',
                icon: Icons.class_outlined,
              ),
              const SizedBox(height: 14),

              // Subject field
              _buildTextField(
                controller: _subjectController,
                label: 'Subject',
                hint: 'e.g. Mathematics, Science',
                icon: Icons.menu_book_outlined,
              ),
              const SizedBox(height: 14),

              // Topic field
              _buildTextField(
                controller: _topicController,
                label: 'Topic',
                hint: 'e.g. Algebraic Expressions',
                icon: Icons.topic_outlined,
              ),
              const SizedBox(height: 14),

              // Date & Time picker
              _buildDateTimeField(),
              const SizedBox(height: 24),

              // Create button
              GestureDetector(
                onTap: _isFormValid ? _onCreateSession : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _isFormValid
                        ? AppColors.primary
                        : AppColors.buttonDisabled,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.rocket_launch_rounded,
                          size: 18,
                          color: _isFormValid
                              ? Colors.white
                              : AppColors.buttonDisabledText,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Create & Start Session',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _isFormValid
                                ? Colors.white
                                : AppColors.buttonDisabledText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider, width: 1.5),
          ),
          child: TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date & Time (optional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickDateTime,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedDateTime != null
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.divider,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 20,
                  color: _selectedDateTime != null
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedDateTime != null
                        ? _formattedDateTime
                        : 'Tap to schedule (defaults to now)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _selectedDateTime != null
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: _selectedDateTime != null
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                if (_selectedDateTime != null)
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedDateTime = null);
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
