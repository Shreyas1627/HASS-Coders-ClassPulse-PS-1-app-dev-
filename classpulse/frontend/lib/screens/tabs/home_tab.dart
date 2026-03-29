import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../data/mock_data.dart';
import '../../services/api_service.dart';
import '../live_session_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // Timetable
  int _selectedDay = 0;
  Map<int, List<TimetableEntry>> _timetable = {};
  bool _timetableLoading = true;

  // Today's sessions
  List<TimetableEntry> _todaysSessions = [];
  bool _todaysLoading = true;

  // Active (live) sessions
  List<LectureSlot> _activeSessions = [];
  bool _activeLoading = true;

  // Missed sessions
  List<MissedSessionEntry> _missedSessions = [];
  bool _missedLoading = true;

  @override
  void initState() {
    super.initState();
    // Set selected day to today
    final today = DateTime.now().weekday - 1; // 0=Mon
    _selectedDay = today.clamp(0, 6);
    _loadAll();
  }

  Future<void> _loadAll() async {
    _loadTimetable();
    _loadTodaysSessions();
    _loadActiveSessions();
    _loadMissedSessions();
  }

  Future<void> _loadTimetable() async {
    setState(() => _timetableLoading = true);
    final teacherId = ApiService.teacherId ?? 'teacher.demo@classpulse.edu';
    final result = await ApiService.getTimetable(teacherId);
    if (mounted && result != null) {
      final raw = result['timetable'] as Map<String, dynamic>? ?? {};
      final parsed = <int, List<TimetableEntry>>{};
      raw.forEach((key, value) {
        final day = int.tryParse(key) ?? 0;
        parsed[day] = (value as List).map((e) => TimetableEntry.fromJson(Map<String, dynamic>.from(e))).toList();
      });
      setState(() {
        _timetable = parsed;
        _timetableLoading = false;
      });
    } else if (mounted) {
      setState(() => _timetableLoading = false);
    }
  }

  Future<void> _loadTodaysSessions() async {
    setState(() => _todaysLoading = true);
    final teacherId = ApiService.teacherId ?? 'teacher.demo@classpulse.edu';
    // First check for missed sessions
    await ApiService.checkMissedSessions(teacherId);
    final result = await ApiService.getTodaysSessions(teacherId);
    if (mounted && result != null) {
      final sessions = (result['sessions'] as List?)?.map((e) => TimetableEntry.fromJson(Map<String, dynamic>.from(e))).toList() ?? [];
      setState(() {
        _todaysSessions = sessions;
        _todaysLoading = false;
      });
    } else if (mounted) {
      setState(() => _todaysLoading = false);
    }
  }

  Future<void> _loadActiveSessions() async {
    setState(() => _activeLoading = true);
    final sessions = await ApiService.getActiveSessions();
    if (mounted) {
      setState(() {
        _activeSessions = sessions.map((s) => LectureSlot.fromJson(s)).toList();
        _activeLoading = false;
      });
    }
  }

  Future<void> _loadMissedSessions() async {
    setState(() => _missedLoading = true);
    final teacherId = ApiService.teacherId ?? 'teacher.demo@classpulse.edu';
    final sessions = await ApiService.getMissedSessions(teacherId);
    if (mounted) {
      setState(() {
        _missedSessions = sessions.map((s) => MissedSessionEntry.fromJson(s)).toList();
        _missedLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── Weekly Timetable ──────────────────────────────────
          _buildTimetableSection(),
          const SizedBox(height: 24),

          // ── Today's Sessions (from timetable) ────────────────
          _buildTodaysSessionsSection(),
          const SizedBox(height: 24),

          // ── Active Live Sessions ─────────────────────────────
          _buildActiveSessionsSection(),
          const SizedBox(height: 24),

          // ── Missed Sessions ──────────────────────────────────
          _buildMissedSessionsSection(),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── Weekly Timetable ────────────────────────────────────────────────────────

  Widget _buildTimetableSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Weekly Timetable',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Day selector tabs
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dayLabels.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedDay == index;
              final isToday = index == (DateTime.now().weekday - 1).clamp(0, 6);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedDay = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : (isToday ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : (isToday ? AppColors.primary.withValues(alpha: 0.3) : AppColors.divider),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      dayLabels[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : (isToday ? AppColors.primary : AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Timetable entries for selected day
        if (_timetableLoading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
          )
        else if (_timetable[_selectedDay] == null || _timetable[_selectedDay]!.isEmpty)
          _buildNoEntriesCard()
        else
          ...(_timetable[_selectedDay]!.map((entry) => _buildTimetableCard(entry))),
      ],
    );
  }

  Widget _buildNoEntriesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Center(
        child: Column(
          children: [
            Text('—', style: TextStyle(fontSize: 28, color: AppColors.textMuted, fontWeight: FontWeight.w300)),
            SizedBox(height: 4),
            Text('No lectures scheduled', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableCard(TimetableEntry entry) {
    if (entry.isHoliday) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Center(
            child: Text('— Holiday —', style: TextStyle(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Time column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      entry.formattedTime,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  entry.subject,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                if (entry.topic != null && entry.topic!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.topic_outlined, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        entry.topic!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const Spacer(),
            // Class badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Class ${entry.className}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Today's Sessions ────────────────────────────────────────────────────────

  Widget _buildTodaysSessionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.today_rounded, size: 20, color: AppColors.amber),
            const SizedBox(width: 8),
            const Text(
              "Today's Sessions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                _loadTodaysSessions();
                _loadActiveSessions();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text('Refresh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap "Start" when it\'s time for your lecture',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        if (_todaysLoading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
          )
        else if (_todaysSessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(
              child: Text('No sessions scheduled for today', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ),
          )
        else
          ..._todaysSessions.map((entry) => _buildTodaysSessionCard(entry)),
      ],
    );
  }

  Widget _buildTodaysSessionCard(TimetableEntry entry) {
    final isPassed = entry.status == 'passed';
    final isNow = entry.status == 'now';

    Color statusColor;
    if (entry.alreadyStarted) {
      statusColor = AppColors.success;
    } else if (isPassed) {
      statusColor = AppColors.warning;
    } else if (isNow) {
      statusColor = AppColors.amber;
    } else {
      statusColor = AppColors.textMuted;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isNow && !entry.alreadyStarted ? AppColors.amber.withValues(alpha: 0.4) : AppColors.divider,
            width: isNow && !entry.alreadyStarted ? 1.5 : 1,
          ),
          boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Time badge
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    entry.startTimeFormatted,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: statusColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.subject,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  if (entry.topic != null && entry.topic!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.topic!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Status / Start button
            if (entry.alreadyStarted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                    SizedBox(width: 4),
                    Text('Live', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
                  ],
                ),
              )
            else if (isPassed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Missed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning)),
              )
            else
              GestureDetector(
                onTap: () => _startSessionFromTimetable(entry),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isNow ? AppColors.primary : AppColors.primary.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isNow
                        ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
                        : null,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Start', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startSessionFromTimetable(TimetableEntry entry) async {
    HapticFeedback.mediumImpact();
    final teacherId = ApiService.teacherId ?? 'teacher.demo@classpulse.edu';

    final result = await ApiService.startFromTimetable(
      timetableId: entry.id,
      teacherId: teacherId,
    );

    if (!mounted) return;

    if (result != null && result['session_code'] != null) {
      final joinCode = result['session_code'];
      final newSession = LectureSlot(
        time: 'Now',
        className: entry.className,
        subject: entry.subject,
        topic: entry.topic ?? '',
        isCurrentOrPast: true,
        joinCode: joinCode,
      );

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LiveSessionScreen(session: newSession)),
      );

      // Refresh lists
      _loadTodaysSessions();
      _loadActiveSessions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to start session. Check connection.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ── Active Sessions ─────────────────────────────────────────────────────────

  Widget _buildActiveSessionsSection() {
    if (_activeLoading) return const SizedBox.shrink();
    if (_activeSessions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.success, boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.4), blurRadius: 6)]),
            ),
            const SizedBox(width: 8),
            const Text(
              'Live Sessions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._activeSessions.map((s) => _buildActiveSessionCard(s)),
      ],
    );
  }

  Widget _buildActiveSessionCard(LectureSlot session) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => LiveSessionScreen(session: session)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sensors_rounded, color: AppColors.success, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.topic.isNotEmpty ? session.topic : session.subject,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${session.className} · ${session.subject}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              // Open button instead of code
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.success),
                    SizedBox(width: 4),
                    Text('Open', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Missed Sessions ─────────────────────────────────────────────────────────

  Widget _buildMissedSessionsSection() {
    if (_missedLoading) return const SizedBox.shrink();
    if (_missedSessions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text(
              'Missed Sessions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_missedSessions.length}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._missedSessions.map((m) => _buildMissedCard(m)),
      ],
    );
  }

  Widget _buildMissedCard(MissedSessionEntry missed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warningLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warningBorder.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.event_busy_rounded, size: 20, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    missed.subject,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${missed.topic ?? ''} · Class ${missed.className}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  missed.formattedDate,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning),
                ),
                const SizedBox(height: 2),
                Text(
                  missed.formattedTime,
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
