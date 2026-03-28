import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../data/mock_data.dart';

/// Session summary shown after a session ends or from history.
class SessionSummaryScreen extends StatelessWidget {
  final String className;
  final String subject;
  final String topic;
  final String duration;
  final int totalStudents;
  final int gotItCount;
  final int sortOfCount;
  final int lostCount;
  final int questionsAsked;
  final int questionsAddressed;

  const SessionSummaryScreen({
    super.key,
    required this.className,
    required this.subject,
    required this.topic,
    required this.duration,
    required this.totalStudents,
    required this.gotItCount,
    required this.sortOfCount,
    required this.lostCount,
    required this.questionsAsked,
    required this.questionsAddressed,
  });

  /// Convenience constructor from a PastSession (for history tab)
  factory SessionSummaryScreen.fromPastSession({
    Key? key,
    required PastSession session,
    required String className,
    required String subject,
  }) {
    // Generate mock comprehension data from attendance
    final total = session.attended;
    final gotIt = (total * 0.55).round();
    final sortOf = (total * 0.30).round();
    final lost = total - gotIt - sortOf;

    return SessionSummaryScreen(
      key: key,
      className: className,
      subject: subject,
      topic: session.topic,
      duration: '45 min',
      totalStudents: session.total,
      gotItCount: gotIt,
      sortOfCount: sortOf,
      lostCount: lost,
      questionsAsked: (total * 0.4).round(),
      questionsAddressed: (total * 0.3).round(),
    );
  }

  /// Convenience constructor from a StudentPastSession (for student sessions tab)
  factory SessionSummaryScreen.fromStudentSession({
    Key? key,
    required StudentPastSession session,
  }) {
    const total = 30;
    final gotIt = (total * 0.55).round();
    final sortOf = (total * 0.30).round();
    final lost = total - gotIt - sortOf;

    return SessionSummaryScreen(
      key: key,
      className: 'Class 10A',
      subject: session.subject,
      topic: session.topic,
      duration: '45 min',
      totalStudents: total,
      gotItCount: gotIt,
      sortOfCount: sortOf,
      lostCount: lost,
      questionsAsked: 12,
      questionsAddressed: 9,
    );
  }

  double get _understandingScore {
    final voted = gotItCount + sortOfCount + lostCount;
    if (voted == 0) return 50;
    return (gotItCount * 100 + sortOfCount * 50) / voted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSessionCard(),
                    const SizedBox(height: 16),
                    _buildScoreCard(),
                    const SizedBox(height: 16),
                    _buildComprehensionBreakdown(),
                    const SizedBox(height: 16),
                    _buildQuestionsCard(),
                    const SizedBox(height: 16),
                    _buildInsightsCard(),
                    const SizedBox(height: 24),
                    _buildDoneButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.assessment_rounded,
                size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Text(
            'Session Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 14, color: AppColors.success),
                SizedBox(width: 4),
                Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 11,
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

  // ── Session info card ─────────────────────────────────────────────────

  Widget _buildSessionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded,
                    size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      className,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildInfoChip(Icons.topic_outlined, topic),
              const Spacer(),
              _buildInfoChip(Icons.timer_outlined, duration),
              const Spacer(),
              _buildInfoChip(Icons.people_outline_rounded,
                  '$totalStudents students'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── Understanding Score ─────────────────────────────────────────────────

  Widget _buildScoreCard() {
    final score = _understandingScore.round();
    final scoreColor = score >= 70
        ? AppColors.success
        : score >= 40
            ? AppColors.amber
            : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withValues(alpha: 0.08),
            scoreColor.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: scoreColor.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(
                  color: scoreColor.withValues(alpha: 0.3), width: 3),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: scoreColor,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/100',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: scoreColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Understanding Score',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  score >= 70
                      ? 'Great session! Most students followed well.'
                      : score >= 40
                          ? 'Some students needed more clarity.'
                          : 'Consider revisiting this topic.',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Comprehension Breakdown ─────────────────────────────────────────────

  Widget _buildComprehensionBreakdown() {
    final total = gotItCount + sortOfCount + lostCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comprehension Breakdown',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _buildBreakdownRow(
            'Got it',
            Icons.check_circle_rounded,
            gotItCount,
            total,
            AppColors.success,
          ),
          const SizedBox(height: 10),
          _buildBreakdownRow(
            'Sort of',
            Icons.help_rounded,
            sortOfCount,
            total,
            AppColors.amber,
          ),
          const SizedBox(height: 10),
          _buildBreakdownRow(
            'Lost',
            Icons.cancel_rounded,
            lostCount,
            total,
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
      String label, IconData icon, int count, int total, Color color) {
    final pct = total > 0 ? (count / total * 100).round() : 0;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? count / total : 0,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 55,
          child: Text(
            '$count ($pct%)',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ── Questions card ─────────────────────────────────────────────────────

  Widget _buildQuestionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              Icons.forum_rounded,
              AppColors.primary,
              '$questionsAsked',
              'Questions Asked',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.divider,
          ),
          Expanded(
            child: _buildStatItem(
              Icons.check_circle_outline_rounded,
              AppColors.success,
              '$questionsAddressed',
              'Addressed',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.divider,
          ),
          Expanded(
            child: _buildStatItem(
              Icons.pending_rounded,
              AppColors.amber,
              '${questionsAsked - questionsAddressed}',
              'Pending',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  // ── Insights ──────────────────────────────────────────────────────────

  Widget _buildInsightsCard() {
    final score = _understandingScore.round();
    final insights = <Map<String, dynamic>>[];

    if (score >= 70) {
      insights.add({
        'icon': Icons.thumb_up_rounded,
        'color': AppColors.success,
        'text': 'Students showed strong comprehension this session.',
      });
    } else {
      insights.add({
        'icon': Icons.replay_rounded,
        'color': AppColors.amber,
        'text': 'Consider a quick recap at the start of next class.',
      });
    }

    if (lostCount > gotItCount) {
      insights.add({
        'icon': Icons.warning_rounded,
        'color': AppColors.warning,
        'text':
            'More students were lost than understood — revisit "$topic".',
      });
    }

    if (questionsAsked > questionsAddressed) {
      insights.add({
        'icon': Icons.help_outline_rounded,
        'color': AppColors.primary,
        'text':
            '${questionsAsked - questionsAddressed} question(s) left unanswered.',
      });
    }

    insights.add({
      'icon': Icons.timelapse_rounded,
      'color': AppColors.textMuted,
      'text': 'Session lasted $duration with $totalStudents students.',
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_rounded, size: 16, color: AppColors.amber),
              SizedBox(width: 6),
              Text(
                'Insights',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(insight['icon'] as IconData, size: 16,
                        color: insight['color'] as Color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight['text'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Done button ──────────────────────────────────────────────────────

  Widget _buildDoneButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home_rounded, size: 18, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Back to Dashboard',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
