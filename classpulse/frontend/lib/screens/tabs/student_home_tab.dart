import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../data/mock_data.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../student_session_screen.dart';

class StudentHomeTab extends StatefulWidget {
  const StudentHomeTab({super.key});

  @override
  State<StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends State<StudentHomeTab> {
  // Timetable
  int _selectedDay = 0;
  Map<int, List<TimetableEntry>> _timetable = {};
  bool _timetableLoading = true;

  // Live sessions
  List<LectureSlot> _activeSessions = [];
  bool _activeLoading = true;

  // Missed sessions
  List<MissedSessionEntry> _missedSessions = [];
  bool _missedLoading = true;

  // The class name for this student — from login or default
  String get _className => ApiService.className ?? '10A';

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().weekday - 1;
    _selectedDay = today.clamp(0, 6); // Mon-Sun
    _loadAll();
  }

  Future<void> _loadAll() async {
    _loadTimetable();
    _loadActiveSessions();
    _loadMissedSessions();
  }

  Future<void> _loadTimetable() async {
    setState(() => _timetableLoading = true);
    final result = await ApiService.getStudentTimetable(_className);
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

  Future<void> _loadActiveSessions() async {
    setState(() => _activeLoading = true);
    final sessions = await ApiService.getAllActiveSessions();
    if (mounted) {
      setState(() {
        _activeSessions = sessions.map((s) => LectureSlot.fromJson(s)).toList();
        _activeLoading = false;
      });
    }
  }

  Future<void> _loadMissedSessions() async {
    setState(() => _missedLoading = true);
    final sessions = await ApiService.getStudentMissedSessions(_className);
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
          // Greeting
          _buildGreeting(),
          const SizedBox(height: 16),

          // My Timetable
          _buildTimetableSection(),
          const SizedBox(height: 24),

          // Live Sessions
          _buildLiveSessionsSection(),
          const SizedBox(height: 24),

          // Missed Sessions
          _buildMissedSessionsSection(),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── Greeting ────────────────────────────────────────────────────────────────

  Widget _buildGreeting() {
    final name = ApiService.teacherId ?? 'Student';
    final firstName = name.contains(' ') ? name.split(' ').first : name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hi, $firstName 👋',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          'Class $_className · ${_getDayName()}',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _getDayName() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[DateTime.now().weekday - 1];
  }

  // ── My Timetable ────────────────────────────────────────────────────────────

  Widget _buildTimetableSection() {
    // Students see Mon-Fri only
    final studentDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.schedule_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'My Timetable',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Day selector
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: studentDays.length,
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
                      studentDays[index],
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

        if (_timetableLoading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
          )
        else if (_timetable[_selectedDay] == null || _timetable[_selectedDay]!.isEmpty)
          _buildNoEntriesCard()
        else
          ...(_timetable[_selectedDay]!.map((entry) => _buildStudentTimetableCard(entry))),
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

  Widget _buildStudentTimetableCard(TimetableEntry entry) {
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

    // Determine status color for time badge
    final isToday = _selectedDay == (DateTime.now().weekday - 1).clamp(0, 6);
    Color timeBadgeColor = AppColors.primary;
    String? statusLabel;

    if (isToday && entry.status != null) {
      switch (entry.status) {
        case 'now':
          timeBadgeColor = AppColors.success;
          statusLabel = 'Now';
          break;
        case 'passed':
          timeBadgeColor = AppColors.textMuted;
          statusLabel = 'Done';
          break;
        case 'upcoming':
          timeBadgeColor = AppColors.primary;
          statusLabel = 'Upcoming';
          break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Time badge (colored dot + time)
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: timeBadgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  entry.startTimeFormatted,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: timeBadgeColor),
                ),
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
            if (statusLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: timeBadgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: timeBadgeColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Live Sessions ───────────────────────────────────────────────────────────

  Widget _buildLiveSessionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.warning,
                boxShadow: [BoxShadow(color: AppColors.warning.withValues(alpha: 0.4), blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Live Sessions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _loadActiveSessions,
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
          'Tap "Join" to enter an active session',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        if (_activeLoading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
          )
        else if (_activeSessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(
              child: Text('No live sessions right now', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ),
          )
        else
          ..._activeSessions.map((s) => _buildLiveSessionCard(s)),
      ],
    );
  }

  Widget _buildLiveSessionCard(LectureSlot session) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.mediumImpact();
          final pos = await LocationService.getCurrentLocation();
          final result = await ApiService.joinSession(
            sessionCode: session.joinCode,
            rollNumber: ApiService.rollNumber ?? 'student_app',
            latitude: pos?.latitude,
            longitude: pos?.longitude,
          );
          if (!mounted) return;
          if (result != null && result['status'] == 'success') {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => StudentSessionScreen(session: session)),
            );
          } else {
            final msg = (result != null && result['error'] != null)
                ? result['error']
                : 'Failed to join session.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                backgroundColor: AppColors.warning,
              ),
            );
          }
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Join', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
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
                    missed.topic ?? '',
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
