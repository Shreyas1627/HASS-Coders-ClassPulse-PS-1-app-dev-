import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../theme/app_colors.dart';
import '../data/mock_data.dart';
import '../services/api_service.dart';
import 'session_summary_screen.dart';

/// Redesigned live session — teacher cockpit view
class LiveSessionScreen extends StatefulWidget {
  final LectureSlot session;
  const LiveSessionScreen({super.key, required this.session});

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen>
    with TickerProviderStateMixin {
  // ── Live signal state ────────────────────────────────────────────────────
  late List<ComprehensionSignal> _liveSignals;
  Timer? _signalTimer;
  bool _reminderDismissed = false;

  // Pulse animation for alert
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Pie chart animation controller
  late AnimationController _pieAnimController;
  double _animGotIt = 0;
  double _animSortOf = 0;
  double _animLost = 0;
  double _animNoVote = 0;

  // Question queue state
  late List<StudentQuestion> _questions;

  // Session duration tracking
  final DateTime _sessionStartTime = DateTime.now();

  // Text-to-speech
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _liveSignals = [];
    _questions = [];

    // Initialize animated pie values
    _animGotIt = _gotItPct;
    _animSortOf = _sortOfPct;
    _animLost = _lostPct;
    _animNoVote = _total > 0 ? _noVoteCount / _total : 0;

    _signalTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollDashboard();
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pieAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Initialize TTS
    _flutterTts.setLanguage('en-US');
    _flutterTts.setSpeechRate(0.45);
    _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    _signalTimer?.cancel();
    _pulseController.dispose();
    _pieAnimController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  /// Poll real data from API — no simulation fallback
  void _pollDashboard() async {
    if (!mounted) return;

    final data = await ApiService.pollDashboard(widget.session.joinCode);
    if (data != null && mounted) {
      final gotIt = data['got_it'] as int? ?? 0;
      final sortOf = data['sort_of'] as int? ?? 0;
      final lost = data['lost'] as int? ?? 0;
      final total = data['total'] as int? ?? (gotIt + sortOf + lost);
      final noVote = total > 0 ? total - gotIt - sortOf - lost : 0;

      // Capture previous values for animation
      final prevGotIt = _gotItPct;
      final prevSortOf = _sortOfPct;
      final prevLost = _lostPct;
      final prevNoVote = _total > 0 ? _noVoteCount / _total : 0.0;

      // Build signal list from API counts
      final newSignals = <ComprehensionSignal>[
        ...List.filled(gotIt, ComprehensionSignal.gotIt),
        ...List.filled(sortOf, ComprehensionSignal.sortOf),
        ...List.filled(lost, ComprehensionSignal.lost),
        ...List.filled(noVote > 0 ? noVote : 0, ComprehensionSignal.noVote),
      ];

      // Update questions from API (including questionId)
      final apiQuestions = data['questions'] as List<dynamic>? ?? [];
      final newQuestions = apiQuestions.map((q) => StudentQuestion(
        text: (q['translated_text'] ?? q['original_text'] ?? '') as String,
        timeAgo: _formatTimeAgo(q['created_at'] as String?),
        upvotes: (q['upvotes'] ?? 0) as int,
        isAddressed: (q['is_addressed'] ?? false) as bool,
        questionId: q['id']?.toString(),
      )).toList();

      setState(() {
        _liveSignals = newSignals;
        _questions = newQuestions;
      });

      // Animate from previous to new values
      final newGotIt = _gotItPct;
      final newSortOf = _sortOfPct;
      final newLost = _lostPct;
      final newNoVote2 = _total > 0 ? _noVoteCount / _total : 0.0;

      _pieAnimController.reset();
      final animation = CurvedAnimation(
        parent: _pieAnimController,
        curve: Curves.easeInOutCubic,
      );
      animation.addListener(() {
        if (!mounted) return;
        setState(() {
          _animGotIt = prevGotIt + (newGotIt - prevGotIt) * animation.value;
          _animSortOf = prevSortOf + (newSortOf - prevSortOf) * animation.value;
          _animLost = prevLost + (newLost - prevLost) * animation.value;
          _animNoVote = prevNoVote + (newNoVote2 - prevNoVote) * animation.value;
        });
      });
      _pieAnimController.forward();
    }
    // If API returns null, we simply keep current state (no fake simulation)
  }

  String _formatTimeAgo(String? isoString) {
    if (isoString == null) return 'just now';
    try {
      final dt = DateTime.parse(isoString);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    } catch (_) {
      return 'just now';
    }
  }



  // ── Computed stats ─────────────────────────────────────────────────────
  int get _total => _liveSignals.length;
  int get _gotItCount =>
      _liveSignals.where((s) => s == ComprehensionSignal.gotIt).length;
  int get _sortOfCount =>
      _liveSignals.where((s) => s == ComprehensionSignal.sortOf).length;
  int get _lostCount =>
      _liveSignals.where((s) => s == ComprehensionSignal.lost).length;
  int get _noVoteCount =>
      _liveSignals.where((s) => s == ComprehensionSignal.noVote).length;

  double get _gotItPct => _total > 0 ? _gotItCount / _total : 0;
  double get _sortOfPct => _total > 0 ? _sortOfCount / _total : 0;
  double get _lostPct => _total > 0 ? _lostCount / _total : 0;

  /// Weighted understanding score 0–100.
  double get _understandingScore {
    final voted = _gotItCount + _sortOfCount + _lostCount;
    if (voted == 0) return 50;
    return (_gotItCount * 100 + _sortOfCount * 50) / voted;
  }

  bool get _isLowUnderstanding => _understandingScore <= 40;

  String get _sessionDuration {
    final elapsed = DateTime.now().difference(_sessionStartTime);
    if (elapsed.inHours > 0) {
      return '${elapsed.inHours}h ${elapsed.inMinutes % 60}m';
    }
    return '${elapsed.inMinutes} min';
  }

  // ── Actions ────────────────────────────────────────────────────────────
  void _endSession() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.surface,
        title: const Text(
          'End Session?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'This will end the current live session.\nStudents will be disconnected.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog

              // Call API to end session
              final summary = await ApiService.endSession(widget.session.joinCode);

              if (!mounted) return;

              // Use API summary data if available, else use local state
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionSummaryScreen(
                    className: widget.session.className,
                    subject: widget.session.subject,
                    topic: widget.session.topic,
                    duration: _sessionDuration,
                    totalStudents: summary?['total_students'] ?? _total,
                    gotItCount: summary?['got_it'] ?? _gotItCount,
                    sortOfCount: summary?['sort_of'] ?? _sortOfCount,
                    lostCount: summary?['lost'] ?? _lostCount,
                    questionsAsked: summary?['total_questions'] ?? _questions.length,
                    questionsAddressed: summary?['questions_addressed'] ??
                        _questions.where((q) => q.isAddressed).length,
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.warning.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'End Session',
              style: TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCodeSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
              const SizedBox(height: 20),
              const Text(
                'Share with Students',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'No app download needed — just enter the code',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Text(
                  widget.session.joinCode,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.network(
                    ApiService.getQrUrl(widget.session.joinCode),
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) {
                      return const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2_rounded, size: 60, color: AppColors.textMuted),
                          SizedBox(height: 4),
                          Text('QR unavailable', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Scan to Join',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  void _markQuestionAddressed(int index) async {
    HapticFeedback.lightImpact();
    final q = _questions[index];
    final newAddressed = !q.isAddressed;

    // Optimistic UI update
    setState(() {
      _questions[index] = StudentQuestion(
        text: q.text,
        timeAgo: q.timeAgo,
        upvotes: q.upvotes,
        isAddressed: newAddressed,
        questionId: q.questionId,
      );
    });

    // Call API if we have a real question ID
    if (q.questionId != null) {
      await ApiService.markQuestionAddressed(q.questionId!, addressed: newAddressed);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSessionInfoBar(),
            // Category grid — fixed height
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _buildCategoryGrid(),
            ),
            // Low understanding reminder
            if (_isLowUnderstanding && !_reminderDismissed)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _buildGentleReminder(),
              ),
            const SizedBox(height: 10),
            // Main content: Pie chart (left) + Question Queue (right)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Left: Pie Chart (35% width) ──
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.35,
                      child: _buildPieChartSection(),
                    ),
                    const SizedBox(width: 12),
                    // ── Right: Question Queue (remaining width) ──
                    Expanded(
                      child: _buildQuestionQueueSection(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
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
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$_total live',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _endSession,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'End',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Session info + join code ────────────────────────────────────────────
  Widget _buildSessionInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.session.className} · ${widget.session.subject}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.session.topic,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showCodeSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.session.joinCode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 3,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.qr_code_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4 Category boxes (2 × 2 grid) ──────────────────────────────────────
  Widget _buildCategoryGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCategoryBox(
                title: 'Got it',
                subtitle: 'Understanding',
                count: _gotItCount,
                pct: _gotItPct,
                color: AppColors.success,
                icon: Icons.check_circle_rounded,
                signal: ComprehensionSignal.gotIt,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCategoryBox(
                title: 'Sort of',
                subtitle: 'Uncertain',
                count: _sortOfCount,
                pct: _sortOfPct,
                color: AppColors.amber,
                icon: Icons.help_rounded,
                signal: ComprehensionSignal.sortOf,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildCategoryBox(
                title: 'Lost',
                subtitle: 'Not Understanding',
                count: _lostCount,
                pct: _lostPct,
                color: AppColors.warning,
                icon: Icons.cancel_rounded,
                signal: ComprehensionSignal.lost,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCategoryBox(
                title: 'No vote',
                subtitle: 'Not Chosen Yet',
                count: _noVoteCount,
                pct: _total > 0 ? _noVoteCount / _total : 0,
                color: AppColors.textMuted,
                icon: Icons.radio_button_unchecked_rounded,
                signal: ComprehensionSignal.noVote,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryBox({
    required String title,
    required String subtitle,
    required int count,
    required double pct,
    required Color color,
    required IconData icon,
    required ComprehensionSignal signal,
  }) {
    return GestureDetector(
      onTap: () => _showStudentsSheet(title, color, icon, signal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            const BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 8,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: color.withValues(alpha: 0.4),
                ),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${(pct * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                Text(
                  'student${count == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Students bottom sheet ──────────────────────────────────────────────
  void _showStudentsSheet(
    String title,
    Color color,
    IconData icon,
    ComprehensionSignal signal,
  ) {
    HapticFeedback.lightImpact();
    final matchingIndices = <int>[];
    for (int i = 0; i < _liveSignals.length; i++) {
      if (_liveSignals[i] == signal) matchingIndices.add(i);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$title — ${matchingIndices.length} student${matchingIndices.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (matchingIndices.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No students in this category',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: matchingIndices.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                size: 20,
                                color: color.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Student ${index + 1}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Pie Chart Section (left side) ──────────────────────────────────────
  Widget _buildPieChartSection() {
    final score = _understandingScore;
    Color scoreColor;
    String scoreLabel;
    if (score >= 66) {
      scoreColor = AppColors.success;
      scoreLabel = 'Healthy';
    } else if (score >= 40) {
      scoreColor = AppColors.amber;
      scoreLabel = 'Moderate';
    } else {
      scoreColor = AppColors.warning;
      scoreLabel = 'Needs Attention';
    }

    return Container(
      padding: const EdgeInsets.all(12),
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
        children: [
          const Text(
            'Understanding',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              scoreLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: scoreColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Pie chart — compact
          LayoutBuilder(
            builder: (context, constraints) {
              final chartSize = math.min(constraints.maxWidth * 0.85, 120.0);
              return SizedBox(
                height: chartSize,
                width: chartSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(chartSize, chartSize),
                      painter: _PieChartPainter(
                        gotItPct: _animGotIt,
                        sortOfPct: _animSortOf,
                        lostPct: _animLost,
                        noVotePct: _animNoVote,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${score.round()}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: scoreColor,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 1),
                        const Text(
                          'score',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Vertical legend
          _pieLegend(AppColors.success, 'Got it', _gotItCount),
          const SizedBox(height: 6),
          _pieLegend(AppColors.amber, 'Sort of', _sortOfCount),
          const SizedBox(height: 6),
          _pieLegend(AppColors.warning, 'Lost', _lostCount),
          const SizedBox(height: 6),
          _pieLegend(AppColors.textMuted, 'No vote', _noVoteCount),
          const SizedBox(height: 16),
          // Quick Actions legend
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _actionLegendRow(
                  Icons.check_circle_outline_rounded,
                  AppColors.success,
                  'Acknowledge',
                ),
                const SizedBox(height: 6),
                _actionLegendRow(
                  Icons.close_rounded,
                  AppColors.warning,
                  'Dismiss',
                ),
                const SizedBox(height: 6),
                _actionLegendRow(
                  Icons.record_voice_over_rounded,
                  AppColors.primary,
                  'Read Aloud',
                ),
                const SizedBox(height: 6),
                _actionLegendRow(
                  Icons.auto_awesome_rounded,
                  AppColors.amber,
                  'AI Answer',
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _pieLegend(Color c, String label, int count) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: c,
          ),
        ),
      ],
    );
  }

  Widget _actionLegendRow(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ── Question Queue Section (right side) ────────────────────────────────
  Widget _buildQuestionQueueSection() {
    final pendingCount = _questions.where((q) => !q.isAddressed).length;

    return Container(
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
          // Header — fixed
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.question_answer_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Question Queue',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: pendingCount > 0
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$pendingCount pending',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: pendingCount > 0
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.divider),
          // Scrollable question list
          Expanded(
            child: _questions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 32,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No questions yet',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _questions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final q = _questions[index];
                      return _buildQuestionCard(q, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(StudentQuestion q, int index) {
    final isAddressed = q.isAddressed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isAddressed
            ? AppColors.success.withValues(alpha: 0.04)
            : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAddressed
              ? AppColors.success.withValues(alpha: 0.2)
              : AppColors.divider,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          Text(
            q.text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isAddressed
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
              height: 1.4,
              decoration: isAddressed ? TextDecoration.lineThrough : null,
              decorationColor: AppColors.textMuted,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          // Info row: upvotes + time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      size: 10,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${q.upvotes}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                q.timeAgo,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Action icons row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionChip(
                icon: isAddressed
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                label: 'Acknowledge',
                color: AppColors.success,
                filled: isAddressed,
                onTap: () => _markQuestionAddressed(index),
              ),
              const SizedBox(width: 4),
              _buildActionChip(
                icon: Icons.close_rounded,
                label: 'Dismiss',
                color: AppColors.warning,
                filled: false,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _questions.removeAt(index);
                  });
                },
              ),
              const SizedBox(width: 4),
              _buildActionChip(
                icon: Icons.record_voice_over_rounded,
                label: 'Read',
                color: AppColors.primary,
                filled: false,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _flutterTts.speak(q.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🔊 "${q.text.length > 40 ? '${q.text.substring(0, 40)}...' : q.text}"',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500)),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              _buildActionChip(
                icon: Icons.auto_awesome_rounded,
                label: 'AI',
                color: AppColors.amber,
                filled: false,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showAIAnswer(q.text, questionId: q.questionId);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: filled
              ? color.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: filled
                ? color.withValues(alpha: 0.3)
                : AppColors.divider,
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(icon, size: 14, color: filled ? color : color.withValues(alpha: 0.7)),
        ),
      ),
    );
  }

  void _showAIAnswer(String questionText, {String? questionId}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _AIAnswerSheet(
          questionText: questionText,
          questionId: questionId,
        );
      },
    );
  }

  // ── Gentle reminder ────────────────────────────────────────────────────
  Widget _buildGentleReminder() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warningLight.withValues(
              alpha: 0.6 + (_pulseAnimation.value * 0.4),
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.warningBorder.withValues(
                alpha: _pulseAnimation.value,
              ),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  size: 16,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Understanding is at ${_understandingScore.round()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Consider slowing down or trying a quick example',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _reminderDismissed = true);
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Donut Pie Chart Painter
// ═══════════════════════════════════════════════════════════════════════════════

class _PieChartPainter extends CustomPainter {
  final double gotItPct;
  final double sortOfPct;
  final double lostPct;
  final double noVotePct;

  _PieChartPainter({
    required this.gotItPct,
    required this.sortOfPct,
    required this.lostPct,
    required this.noVotePct,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 20.0;
    const gapAngle = 0.06;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    final segments = <_PieSegment>[
      _PieSegment(gotItPct, const Color(0xFF10B981), const Color(0xFF34D399)),
      _PieSegment(sortOfPct, const Color(0xFFF59E0B), const Color(0xFFFBBF24)),
      _PieSegment(lostPct, const Color(0xFFEF4444), const Color(0xFFF87171)),
      _PieSegment(noVotePct, const Color(0xFFCBD5E1), const Color(0xFFE2E8F0)),
    ];

    final nonZeroSegments = segments.where((s) => s.fraction > 0).length;
    final totalGap = nonZeroSegments > 1 ? gapAngle * nonZeroSegments : 0.0;
    final availableSweep = 2 * math.pi - totalGap;

    // Background track
    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Inner subtle shadow ring
    final innerShadow = Paint()
      ..color = const Color(0x0A000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2;
    canvas.drawCircle(center, radius - strokeWidth / 2, innerShadow);

    // Draw segments
    double startAngle = -math.pi / 2;

    for (final seg in segments) {
      if (seg.fraction <= 0) continue;

      final sweep = seg.fraction * availableSweep;
      
      // Gradient-like effect: draw two arcs - outer darker, inner lighter
      final paintOuter = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweep, false, paintOuter);

      // Highlight stripe on the inner edge for depth
      final highlightRect = Rect.fromCircle(
        center: center,
        radius: radius - strokeWidth * 0.75,
      );
      final paintHighlight = Paint()
        ..color = seg.lightColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.3
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(highlightRect, startAngle, sweep, false, paintHighlight);

      startAngle += sweep + (nonZeroSegments > 1 ? gapAngle : 0);
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) =>
      gotItPct != oldDelegate.gotItPct ||
      sortOfPct != oldDelegate.sortOfPct ||
      lostPct != oldDelegate.lostPct ||
      noVotePct != oldDelegate.noVotePct;
}

class _PieSegment {
  final double fraction;
  final Color color;
  final Color lightColor;
  const _PieSegment(this.fraction, this.color, this.lightColor);
}

// ═══════════════════════════════════════════════════════════════════════════════
// AI Answer Bottom Sheet — calls real API
// ═══════════════════════════════════════════════════════════════════════════════

class _AIAnswerSheet extends StatefulWidget {
  final String questionText;
  final String? questionId;

  const _AIAnswerSheet({required this.questionText, this.questionId});

  @override
  State<_AIAnswerSheet> createState() => _AIAnswerSheetState();
}

class _AIAnswerSheetState extends State<_AIAnswerSheet> {
  String? _answer;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchAnswer();
  }

  Future<void> _fetchAnswer() async {
    if (widget.questionId == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    final result = await ApiService.generateAiAnswer(widget.questionId!);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result != null && result['answer'] != null) {
          _answer = result['answer'] as String;
        } else {
          _hasError = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    size: 18, color: AppColors.amber),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI-Generated Answer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '"${widget.questionText}"',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(24),
              child: const Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.amber,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Generating answer...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_hasError)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: const Text(
                'Could not generate an AI answer. The AI service may be unavailable or the question has no ID.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Text(
                _answer ?? '',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 14),
          if (!_isLoading && !_hasError && _answer != null)
            GestureDetector(
              onTap: () async {
                HapticFeedback.lightImpact();
                await ApiService.answerDoubt(
                  questionId: widget.questionId!,
                  answerText: _answer,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Answer sent to students! 🚀', style: TextStyle(color: Colors.white)),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Send to Students',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
