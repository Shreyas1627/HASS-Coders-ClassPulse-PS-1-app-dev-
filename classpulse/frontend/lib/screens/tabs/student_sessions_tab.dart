import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';

class StudentSessionsTab extends StatefulWidget {
  const StudentSessionsTab({super.key});

  @override
  State<StudentSessionsTab> createState() => _StudentSessionsTabState();
}

class _StudentSessionsTabState extends State<StudentSessionsTab> {
  List<Map<String, dynamic>> _pastSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final rn = ApiService.rollNumber ?? 'student_app';
    final sessions = await ApiService.getStudentHistory(rn);
    if (mounted) {
      setState(() {
        _pastSessions = sessions;
        _isLoading = false;
      });
    }
  }

  Color _signalColor(String signal) {
    switch (signal) {
      case 'understood': return AppColors.success;
      case 'maybe': return AppColors.amber;
      case 'not_understood': return AppColors.warning;
      default: return AppColors.textMuted;
    }
  }

  IconData _signalIcon(String signal) {
    switch (signal) {
      case 'understood': return Icons.check_circle_rounded;
      case 'maybe': return Icons.help_rounded;
      case 'not_understood': return Icons.cancel_rounded;
      default: return Icons.radio_button_unchecked;
    }
  }

  String _signalLabel(String signal) {
    switch (signal) {
      case 'understood': return 'Got It';
      case 'maybe': return 'Sort Of';
      case 'not_understood': return 'Lost';
      default: return 'No Signal';
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadHistory,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : _pastSessions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: _pastSessions.length + 1,
                  itemBuilder: (ctx, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'My Sessions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      );
                    }
                    final s = _pastSessions[index - 1];
                    return _buildSessionCard(s);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 16),
              const Text('No Past Sessions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text(
                'Your session history will appear\nhere after you attend classes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final subject = session['subject'] ?? '';
    final topic = session['topic'] ?? '';
    final date = session['date'] ?? '';
    final signal = session['signal'] ?? 'none';
    final doubt = session['doubt'] as String?;
    final color = _signalColor(signal);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_signalIcon(signal), color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(topic.isNotEmpty ? topic : subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('$subject · $date', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_signalLabel(signal), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                ),
              ],
            ),
            if (doubt != null && doubt.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        doubt,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
