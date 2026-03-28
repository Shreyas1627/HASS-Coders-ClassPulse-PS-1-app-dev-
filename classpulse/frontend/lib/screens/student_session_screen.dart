import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../data/mock_data.dart';

class StudentSessionScreen extends StatefulWidget {
  final LectureSlot session;

  const StudentSessionScreen({super.key, required this.session});

  @override
  State<StudentSessionScreen> createState() => _StudentSessionScreenState();
}

class _StudentSessionScreenState extends State<StudentSessionScreen> {
  String? _selectedSignal; // 'understood', 'maybe', 'not_understood'
  bool _signalSent = false;
  final _doubtController = TextEditingController();

  @override
  void dispose() {
    _doubtController.dispose();
    super.dispose();
  }

  void _sendSignal(String signal) {
    HapticFeedback.mediumImpact();

    if (signal == 'understood') {
      setState(() {
        _selectedSignal = signal;
        _signalSent = true;
      });
      _showConfirmation('✅ Response sent!', AppColors.success);
    } else {
      // Open doubt input sheet for "maybe" and "not_understood"
      _showDoubtSheet(signal);
    }
  }

  void _showConfirmation(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDoubtSheet(String signal) {
    _doubtController.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isLost = signal == 'not_understood';
        final color = isLost ? AppColors.warning : AppColors.amber;
        final title =
            isLost ? 'What are you struggling with?' : 'What\'s unclear?';

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isLost ? Icons.cancel_rounded : Icons.help_rounded,
                        size: 18,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your response is anonymous. The teacher only sees aggregated feedback.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                // Text input
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider, width: 1.5),
                  ),
                  child: TextField(
                    controller: _doubtController,
                    autofocus: true,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: isLost
                          ? 'e.g. I don\'t understand the formula...'
                          : 'e.g. The second step was confusing...',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Send buttons row
                Row(
                  children: [
                    // Skip (send without doubt)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(ctx);
                          setState(() {
                            _selectedSignal = signal;
                            _signalSent = true;
                          });
                          _showConfirmation('Response sent!', color);
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: color, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Send with doubt
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(ctx);
                          setState(() {
                            _selectedSignal = signal;
                            _signalSent = true;
                          });
                          final hasDoubt =
                              _doubtController.text.trim().isNotEmpty;
                          _showConfirmation(
                            hasDoubt
                                ? 'Response & doubt sent! 📝'
                                : 'Response sent!',
                            color,
                          );
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.send_rounded,
                                    size: 16, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Send',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                    height: MediaQuery.of(ctx).padding.bottom + 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _leaveSession() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Leave Session?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('You can rejoin using the same code.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Leave',
                style: TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSessionInfo(),
            _buildTopicTracker(),
            const Spacer(),
            _buildSignalButtons(),
            if (_signalSent) _buildSignalConfirmation(),
            const Spacer(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: _leaveSession,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.primary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Live Session',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Connected',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Session Info ───────────────────────────────────────────────────────

  Widget _buildSessionInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.session.subject,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.session.className} · ${widget.session.time}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Topic Tracker (Done → Active → Next) ──────────────────────────────

  Widget _buildTopicTracker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTopicBlock(
                label: 'Done',
                topic: 'Introduction',
                color: AppColors.success,
                icon: Icons.check_circle_rounded,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.divider,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            Expanded(
              child: _buildTopicBlock(
                label: 'Active',
                topic: widget.session.topic,
                color: AppColors.primary,
                icon: Icons.play_circle_rounded,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.divider,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            Expanded(
              child: _buildTopicBlock(
                label: 'Next',
                topic: 'Practice Problems',
                color: AppColors.textMuted,
                icon: Icons.skip_next_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicBlock({
    required String label,
    required String topic,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          topic,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── 3 Signal Buttons ──────────────────────────────────────────────────

  Widget _buildSignalButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            'How are you following?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your response is anonymous',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          // Understood
          _buildSignalButton(
            signal: 'understood',
            label: 'Understood',
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          // Maybe
          _buildSignalButton(
            signal: 'maybe',
            label: 'Maybe',
            icon: Icons.help_rounded,
            color: AppColors.amber,
          ),
          const SizedBox(height: 12),
          // Not Understood
          _buildSignalButton(
            signal: 'not_understood',
            label: 'Not Understood',
            icon: Icons.cancel_rounded,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildSignalButton({
    required String signal,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedSignal == signal;

    return GestureDetector(
      onTap: () => _sendSignal(signal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : color,
              ),
            ),
            if (signal != 'understood') ...[
              const SizedBox(width: 6),
              Icon(
                Icons.edit_note_rounded,
                size: 16,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.7)
                    : color.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Signal confirmation ────────────────────────────────────────────────

  Widget _buildSignalConfirmation() {
    Color color;
    String label;
    IconData icon;

    switch (_selectedSignal) {
      case 'understood':
        color = AppColors.success;
        label = 'You responded: Understood';
        icon = Icons.check_circle_rounded;
        break;
      case 'maybe':
        color = AppColors.amber;
        label = 'You responded: Maybe';
        icon = Icons.help_rounded;
        break;
      default:
        color = AppColors.warning;
        label = 'You responded: Not Understood';
        icon = Icons.cancel_rounded;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedSignal = null;
                  _signalSent = false;
                });
              },
              child: Text(
                'Change',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 13, color: AppColors.textMuted),
          const SizedBox(width: 4),
          const Text(
            'Your identity is anonymous to the teacher',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
