import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../data/mock_data.dart';
import '../../services/api_service.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  // Navigation: class list → subject list → session list
  String? _selectedClass;
  String? _selectedSubject;

  Map<String, Map<String, List<PastSession>>> _history = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getSessionHistory();
    if (data != null && mounted) {
      final rawHistory = data['history'] as Map<String, dynamic>? ?? {};
      final parsed = <String, Map<String, List<PastSession>>>{};

      rawHistory.forEach((className, subjects) {
        parsed[className] = {};
        (subjects as Map<String, dynamic>).forEach((subject, sessions) {
          parsed[className]![subject] = (sessions as List).map((s) {
            return PastSession(
              sessionId: '#${s['session_code'] ?? ''}',
              date: _formatDate(s['created_at'] as String?),
              topic: s['topic'] ?? s['subject'] ?? '',
              attended: s['attended'] ?? 0,
              total: 0,
            );
          }).toList();
        });
      });

      setState(() {
        _history = parsed;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  void _goBack() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedSubject != null) {
        _selectedSubject = null;
      } else if (_selectedClass != null) {
        _selectedClass = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
              : _history.isEmpty
                  ? _buildEmptyState()
                  : _selectedClass == null
                      ? _buildClassList()
                      : _selectedSubject == null
                          ? _buildSubjectList()
                          : _buildSessionList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final title = _selectedClass == null
        ? 'Session History'
        : _selectedSubject == null
            ? _selectedClass!
            : '$_selectedClass · $_selectedSubject';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          if (_selectedClass != null)
            GestureDetector(
              onTap: _goBack,
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.textSecondary),
              ),
            ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('No Past Sessions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text(
            'Completed sessions will appear here.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildClassList() {
    final classes = _history.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final cn = classes[index];
        final subjectCount = _history[cn]!.keys.length;
        return _buildListTile(
          icon: Icons.class_outlined,
          title: cn,
          subtitle: '$subjectCount subject${subjectCount != 1 ? 's' : ''}',
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedClass = cn);
          },
        );
      },
    );
  }

  Widget _buildSubjectList() {
    final subjects = _history[_selectedClass]!.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subj = subjects[index];
        final sessionCount = _history[_selectedClass]![subj]!.length;
        return _buildListTile(
          icon: Icons.menu_book_outlined,
          title: subj,
          subtitle: '$sessionCount session${sessionCount != 1 ? 's' : ''}',
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedSubject = subj);
          },
        );
      },
    );
  }

  Widget _buildSessionList() {
    final sessions = _history[_selectedClass]![_selectedSubject]!;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final s = sessions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bar_chart_rounded, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.topic, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text(
                        '${s.date} · ${s.sessionId} · ${s.attended} attended',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
