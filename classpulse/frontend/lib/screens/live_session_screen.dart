import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../data/mock_data.dart';

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

  @override
  void initState() {
    super.initState();
    _liveSignals = liveSessionStudents.map((s) => s.signal).toList();

    _signalTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _simulateSignalChange();
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _signalTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _simulateSignalChange() {
    if (!mounted) return;
    final rng = math.Random();
    final changeCount = rng.nextInt(3) + 1;
    setState(() {
      _reminderDismissed = false;
      for (int i = 0; i < changeCount; i++) {
        final idx = rng.nextInt(_liveSignals.length);
        _liveSignals[idx] = ComprehensionSignal
            .values[rng.nextInt(ComprehensionSignal.values.length)];
      }
    });
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
  /// Got it = 100, Sort of = 50, Lost = 0. No‑votes excluded.
  double get _understandingScore {
    final voted = _gotItCount + _sortOfCount + _lostCount;
    if (voted == 0) return 50;
    return (_gotItCount * 100 + _sortOfCount * 50) / voted;
  }

  bool get _isLowUnderstanding => _understandingScore <= 40;

  // ── Actions ────────────────────────────────────────────────────────────
  void _endSession() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.surface,
        title: const Text('End Session?',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: const Text(
          'This will end the current live session.\nStudents will be disconnected.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.warning.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('End Session',
                style: TextStyle(
                    color: AppColors.warning, fontWeight: FontWeight.w600)),
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
              // Large code display
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 2),
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
              // QR placeholder
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider, width: 1),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2_rounded,
                        size: 90, color: AppColors.textPrimary),
                    SizedBox(height: 4),
                    Text(
                      'Scan to Join',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
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
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: Column(
                  children: [
                    _buildCategoryGrid(),
                    const SizedBox(height: 16),
                    _buildGaugeCard(),
                    if (_isLowUnderstanding && !_reminderDismissed) ...[
                      const SizedBox(height: 12),
                      _buildGentleReminder(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header (clean, same style as dashboard) ────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border:
            Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
        boxShadow: [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Back
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
              child: const Icon(Icons.arrow_back_rounded,
                  size: 20, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),

          // Title
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

          // Live badge
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

          // End session
          GestureDetector(
            onTap: _endSession,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
        border:
            Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
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
          // Tappable join code chip
          GestureDetector(
            onTap: _showCodeSheet,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1),
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
                  const Icon(Icons.qr_code_rounded,
                      size: 16, color: AppColors.primary),
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
                subtitle: 'Maybe',
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
        height: 110,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
            const BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 4,
                offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 15, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: color)),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                // Tap hint
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: color.withValues(alpha: 0.4)),
              ],
            ),
            const Spacer(),
            // Count + percentage
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${(pct * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                Text(
                  'student${count == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 10,
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

  // ── Bottom sheet showing anonymous students for a category ─────────────
  void _showStudentsSheet(
      String title, Color color, IconData icon, ComprehensionSignal signal) {
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
              const SizedBox(height: 16),
              // Title
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
              // Student list
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
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, color: AppColors.divider),
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
                              child: Icon(Icons.person_rounded,
                                  size: 20,
                                  color: color.withValues(alpha: 0.5)),
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
                                  horizontal: 8, vertical: 3),
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

  // ── Pie chart card ─────────────────────────────────────────────────────
  Widget _buildGaugeCard() {
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Class Understanding',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              scoreLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scoreColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Pie chart with center label
          SizedBox(
            height: 160,
            width: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _PieChartPainter(
                    gotItPct: _gotItPct,
                    sortOfPct: _sortOfPct,
                    lostPct: _lostPct,
                    noVotePct: _total > 0 ? _noVoteCount / _total : 0,
                  ),
                ),
                // Center text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${score.round()}%',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: scoreColor,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'understanding',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Legend row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _pieLegend(AppColors.success, 'Got it', _gotItCount),
              _pieLegend(AppColors.amber, 'Sort of', _sortOfCount),
              _pieLegend(AppColors.warning, 'Lost', _lostCount),
              _pieLegend(AppColors.textMuted, 'No vote', _noVoteCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pieLegend(Color c, String label, int count) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: c,
          ),
        ),
      ],
    );
  }

  // ── Gentle reminder ────────────────────────────────────────────────────
  Widget _buildGentleReminder() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warningLight
                .withValues(alpha: 0.6 + (_pulseAnimation.value * 0.4)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.warningBorder
                  .withValues(alpha: _pulseAnimation.value),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb_rounded,
                    size: 20, color: AppColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Understanding is at ${_understandingScore.round()}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Consider slowing down or trying a quick example',
                      style: TextStyle(
                        fontSize: 11,
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
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.warning),
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
    const strokeWidth = 22.0;
    const gapAngle = 0.04; // small gap between segments

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Segments: Got it, Sort of, Lost, No vote
    final segments = <_PieSegment>[
      _PieSegment(gotItPct, const Color(0xFF10B981)),
      _PieSegment(sortOfPct, const Color(0xFFF59E0B)),
      _PieSegment(lostPct, const Color(0xFFEF4444)),
      _PieSegment(noVotePct, const Color(0xFFCBD5E1)),
    ];

    // Count non-zero segments for gap calculation
    final nonZeroSegments = segments.where((s) => s.fraction > 0).length;
    final totalGap = nonZeroSegments > 1 ? gapAngle * nonZeroSegments : 0.0;
    final availableSweep = 2 * math.pi - totalGap;

    // Draw background circle
    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Draw segments
    double startAngle = -math.pi / 2; // Start from top

    for (final seg in segments) {
      if (seg.fraction <= 0) continue;

      final sweep = seg.fraction * availableSweep;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweep, false, paint);
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
  const _PieSegment(this.fraction, this.color);
}
