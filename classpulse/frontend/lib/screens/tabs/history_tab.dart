import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../data/mock_data.dart';

/// Three-level drill-down: Classes → Subjects → Session History
class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

enum _HistoryLevel { classes, subjects, sessions }

class _HistoryTabState extends State<HistoryTab> {
  _HistoryLevel _level = _HistoryLevel.classes;
  String? _selectedClass;
  String? _selectedSubject;

  void _goToSubjects(String className) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedClass = className;
      _level = _HistoryLevel.subjects;
    });
  }

  void _goToSessions(String subject) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedSubject = subject;
      _level = _HistoryLevel.sessions;
    });
  }

  void _goBack() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_level == _HistoryLevel.sessions) {
        _level = _HistoryLevel.subjects;
        _selectedSubject = null;
      } else if (_level == _HistoryLevel.subjects) {
        _level = _HistoryLevel.classes;
        _selectedClass = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildBreadcrumb(),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildCurrentLevel(),
          ),
        ),
      ],
    );
  }

  // ── Breadcrumb / navigation ─────────────────────────────────────────────

  Widget _buildBreadcrumb() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          if (_level != _HistoryLevel.classes)
            GestureDetector(
              onTap: _goBack,
              child: Container(
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    size: 18, color: AppColors.primary),
              ),
            ),
          Icon(
            _level == _HistoryLevel.classes
                ? Icons.history_rounded
                : _level == _HistoryLevel.subjects
                    ? Icons.class_outlined
                    : Icons.list_alt_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _breadcrumbText(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _breadcrumbText() {
    switch (_level) {
      case _HistoryLevel.classes:
        return 'Session History';
      case _HistoryLevel.subjects:
        return _selectedClass ?? 'Subjects';
      case _HistoryLevel.sessions:
        return '$_selectedSubject — $_selectedClass';
    }
  }

  // ── Level router ────────────────────────────────────────────────────────

  Widget _buildCurrentLevel() {
    switch (_level) {
      case _HistoryLevel.classes:
        return _buildClassesGrid(key: const ValueKey('classes'));
      case _HistoryLevel.subjects:
        return _buildSubjectsList(key: const ValueKey('subjects'));
      case _HistoryLevel.sessions:
        return _buildSessionsList(key: const ValueKey('sessions'));
    }
  }

  // ── Level 1: Classes grid ───────────────────────────────────────────────

  Widget _buildClassesGrid({Key? key}) {
    final classes = sessionHistory.keys.toList();

    return ListView.separated(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: classes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final className = classes[index];
        final subjectCount = sessionHistory[className]?.length ?? 0;
        final allSessions = sessionHistory[className]
                ?.values
                .expand((list) => list)
                .toList() ??
            [];
        final totalSessions = allSessions.length;

        // Calculate average attendance
        int avgAttendance = 0;
        if (allSessions.isNotEmpty) {
          final totalPct = allSessions.fold<double>(
              0, (sum, s) => sum + (s.attended / s.total * 100));
          avgAttendance = (totalPct / allSessions.length).round();
        }

        return GestureDetector(
          onTap: () => _goToSubjects(className),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 8,
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.school_rounded,
                        size: 22, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        className,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$subjectCount subject${subjectCount == 1 ? '' : 's'} · $totalSessions sessions',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Avg attendance chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: avgAttendance >= 90
                              ? AppColors.successLight
                              : avgAttendance >= 75
                                  ? AppColors.amberLight
                                  : AppColors.warningLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Avg Attendance: $avgAttendance%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: avgAttendance >= 90
                                ? AppColors.success
                                : avgAttendance >= 75
                                    ? AppColors.amber
                                    : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Level 2: Subjects list ──────────────────────────────────────────────

  Widget _buildSubjectsList({Key? key}) {
    final subjects =
        sessionHistory[_selectedClass]?.keys.toList() ?? [];

    return ListView.separated(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: subjects.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final count =
            sessionHistory[_selectedClass]?[subject]?.length ?? 0;

        return GestureDetector(
          onTap: () => _goToSessions(subject),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 8,
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
                    color: _subjectColor(subject).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(_subjectIcon(subject),
                        size: 22, color: _subjectColor(subject)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$count past sessions',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Level 3: Session history list ───────────────────────────────────────

  Widget _buildSessionsList({Key? key}) {
    final sessions =
        sessionHistory[_selectedClass]?[_selectedSubject] ?? [];

    return ListView.separated(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: sessions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final session = sessions[index];
        final attendancePercent =
            ((session.attended / session.total) * 100).toInt();

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider, width: 1),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: ID + date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        session.sessionId,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Text(
                      session.date,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Topic
                Text(
                  session.topic,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                // Attendance + download button
                Row(
                  children: [
                    // Attendance chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: attendancePercent >= 90
                            ? AppColors.successLight
                            : attendancePercent >= 75
                                ? AppColors.amberLight
                                : AppColors.warningLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 14,
                            color: attendancePercent >= 90
                                ? AppColors.success
                                : attendancePercent >= 75
                                    ? AppColors.amber
                                    : AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${session.attended}/${session.total} Students',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: attendancePercent >= 90
                                  ? AppColors.success
                                  : attendancePercent >= 75
                                      ? AppColors.amber
                                      : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Download Report button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Downloading report ${session.sessionId}...',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.primary, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.download_rounded,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Download Report',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  IconData _subjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return Icons.calculate_outlined;
      case 'science':
        return Icons.science_outlined;
      case 'history':
        return Icons.auto_stories_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }

  Color _subjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return AppColors.primary;
      case 'science':
        return AppColors.success;
      case 'history':
        return AppColors.amber;
      default:
        return AppColors.avatarDefault;
    }
  }
}
