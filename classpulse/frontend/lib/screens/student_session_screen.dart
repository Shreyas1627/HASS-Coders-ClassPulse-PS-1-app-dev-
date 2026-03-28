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

  // Mock questions from other students
  final List<Map<String, dynamic>> _questions = [
    {'text': 'Can you explain the difference between abstract classes and interfaces?', 'upvotes': 12, 'upvoted': false},
    {'text': 'How does this concept apply in real-world scenarios?', 'upvotes': 8, 'upvoted': false},
    {'text': 'Could you repeat the formula one more time?', 'upvotes': 5, 'upvoted': false},
    {'text': 'What happens if we use a different approach here?', 'upvotes': 3, 'upvoted': false},
    {'text': 'Is this going to be covered in the exam?', 'upvotes': 15, 'upvoted': false},
    {'text': 'Can you provide a numerical example?', 'upvotes': 7, 'upvoted': false},
    {'text': 'What are the edge cases we should consider?', 'upvotes': 4, 'upvoted': false},
    {'text': 'How is this different from what we learned last week?', 'upvotes': 6, 'upvoted': false},
  ];

  void _toggleUpvote(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      final q = _questions[index];
      if (q['upvoted'] == true) {
        q['upvotes'] = (q['upvotes'] as int) - 1;
        q['upvoted'] = false;
      } else {
        q['upvotes'] = (q['upvotes'] as int) + 1;
        q['upvoted'] = true;
      }
    });
  }

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
        final accentColor = isLost ? AppColors.warning : AppColors.amber;

        return _DoubtSheet(
          session: widget.session,
          doubtController: _doubtController,
          onCancel: () => Navigator.pop(ctx),
          onSend: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(ctx);
            setState(() {
              _selectedSignal = signal;
              _signalSent = true;
            });
            final hasDoubt = _doubtController.text.trim().isNotEmpty;
            _showConfirmation(
              hasDoubt ? 'Doubt sent! 📝' : 'Response sent!',
              accentColor,
            );
          },
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
        child: Stack(
          children: [
            // ── Main content ──────────────────────────────────────
            Positioned.fill(
              bottom: 56, // Reserve space for draggable sheet handle
              child: Column(
                children: [
                  _buildHeader(),
                  _buildSessionInfo(),
                  _buildTopicTracker(),
                  const Spacer(),
                  _buildSignalButtons(),
                  if (_signalSent) _buildSignalConfirmation(),
                  const Spacer(),
                ],
              ),
            ),

            // ── Pull-up questions sheet ───────────────────────────
            _buildDraggableQuestions(),
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

  // ── 3 Signal Buttons (big vertical) ─────────────────────────────────

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
          _buildSignalButton(
            signal: 'understood',
            label: 'Understood',
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          _buildSignalButton(
            signal: 'maybe',
            label: 'Maybe',
            icon: Icons.help_rounded,
            color: AppColors.amber,
          ),
          const SizedBox(height: 12),
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
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
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
            Icon(icon, size: 22, color: isSelected ? Colors.white : color),
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
                  decorationColor: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Draggable Questions Sheet ────────────────────────────────────────

  Widget _buildDraggableQuestions() {
    final sorted = List<int>.generate(_questions.length, (i) => i);
    sorted.sort(
        (a, b) => (_questions[b]['upvotes'] as int)
            .compareTo(_questions[a]['upvotes'] as int));

    return DraggableScrollableSheet(
      initialChildSize: 0.07,
      minChildSize: 0.07,
      maxChildSize: 0.6,
      snap: true,
      snapSizes: const [0.07, 0.35, 0.6],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // ── Handle + Header ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Column(
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.forum_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Student Questions',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_questions.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_up_rounded,
                            size: 20, color: AppColors.textMuted),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.divider),

              // ── Question items ──────────────────────────────────
              ...sorted.map((qi) {
                final q = _questions[qi];
                final upvoted = q['upvoted'] as bool;
                final upvotes = q['upvotes'] as int;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              q['text'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => _toggleUpvote(qi),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: upvoted
                                    ? AppColors.primary
                                        .withValues(alpha: 0.1)
                                    : AppColors.surfaceAlt,
                                borderRadius:
                                    BorderRadius.circular(8),
                                border: Border.all(
                                  color: upvoted
                                      ? AppColors.primary
                                          .withValues(alpha: 0.3)
                                      : AppColors.divider,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 14,
                                    color: upvoted
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$upvotes',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: upvoted
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                        color: AppColors.divider),
                  ],
                );
              }),

              // Bottom safe area padding
              SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 12),
            ],
          ),
        );
      },
    );
  }
}

// ── Doubt topics for dropdowns ───────────────────────────────────────────────

/// Maps subject → list of lecture concepts
/// Each concept maps to a list of specific details
final Map<String, Map<String, List<String>>> _doubtTopics = {
  'Mathematics': {
    'Algebraic Expressions': [
      'Variables & Constants',
      'Like & Unlike Terms',
      'Operations on Expressions',
      'Factorization',
    ],
    'Quadratic Equations': [
      'Standard Form',
      'Discriminant',
      'Quadratic Formula',
      'Nature of Roots',
    ],
    'Coordinate Geometry': [
      'Distance Formula',
      'Section Formula',
      'Midpoint Formula',
      'Slope of a Line',
    ],
    'Trigonometry': [
      'Trig Ratios',
      'Trig Identities',
      'Heights & Distances',
      'Complementary Angles',
    ],
    'Surface Areas & Volumes': [
      'Cylinder',
      'Cone',
      'Sphere',
      'Combination of Solids',
    ],
  },
  'Science': {
    'Chemical Reactions': [
      'Types of Reactions',
      'Balancing Equations',
      'Oxidation & Reduction',
      'Endothermic vs Exothermic',
    ],
    'Electricity & Circuits': [
      'Ohm\'s Law',
      'Series & Parallel',
      'Resistance',
      'Power & Energy',
    ],
    'Light & Reflection': [
      'Mirror Formula',
      'Sign Convention',
      'Image Formation',
      'Magnification',
    ],
    'Acids, Bases & Salts': [
      'pH Scale',
      'Neutralization',
      'Chemical Properties',
      'Indicators',
    ],
  },
  'English': {
    'Shakespearean Sonnets': [
      'Iambic Pentameter',
      'Rhyme Scheme',
      'Themes & Imagery',
      'Literary Devices',
    ],
    'Letter Writing': [
      'Formal Format',
      'Informal Format',
      'Content & Tone',
      'Salutation & Closing',
    ],
  },
  'Database Management': {
    'Normalization': [
      '1NF - Atomicity',
      '2NF - Partial Dep',
      '3NF - Transitive Dep',
      'BCNF',
    ],
    'SQL Queries': [
      'SELECT & WHERE',
      'JOINs',
      'GROUP BY',
      'Subqueries',
    ],
  },
  'Computer Networks': {
    'TCP/IP Protocol Stack': [
      'Application Layer',
      'Transport Layer',
      'Network Layer',
      'Data Link Layer',
    ],
    'OSI Model': [
      'Layer Functions',
      'Encapsulation',
      'Protocols',
      'Comparison with TCP/IP',
    ],
  },
  'Operating Systems': {
    'Process Scheduling': [
      'FCFS',
      'SJF',
      'Round Robin',
      'Priority Scheduling',
    ],
    'Memory Management': [
      'Paging',
      'Segmentation',
      'Virtual Memory',
      'Page Replacement',
    ],
  },
  'Data Structures': {
    'AVL Trees & Rotations': [
      'Balance Factor',
      'Left Rotation',
      'Right Rotation',
      'Double Rotation',
    ],
    'Linked Lists': [
      'Singly Linked',
      'Doubly Linked',
      'Insertion & Deletion',
      'Circular List',
    ],
  },
};

// ── Doubt Sheet Widget ───────────────────────────────────────────────────────

class _DoubtSheet extends StatefulWidget {
  final LectureSlot session;
  final TextEditingController doubtController;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const _DoubtSheet({
    required this.session,
    required this.doubtController,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<_DoubtSheet> createState() => _DoubtSheetState();
}

class _DoubtSheetState extends State<_DoubtSheet> {
  String? _selectedConcept;
  String? _selectedDetail;

  List<String> get _concepts {
    final subjectTopics = _doubtTopics[widget.session.subject];
    if (subjectTopics != null) return subjectTopics.keys.toList();
    // Fallback: use the session topic itself
    return [widget.session.topic];
  }

  List<String> get _details {
    if (_selectedConcept == null) return [];
    final subjectTopics = _doubtTopics[widget.session.subject];
    if (subjectTopics != null && subjectTopics.containsKey(_selectedConcept)) {
      return subjectTopics[_selectedConcept]!;
    }
    return ['General'];
  }

  @override
  void initState() {
    super.initState();
    // Pre-select the first concept if the session topic matches
    final concepts = _concepts;
    if (concepts.contains(widget.session.topic)) {
      _selectedConcept = widget.session.topic;
    } else if (concepts.isNotEmpty) {
      _selectedConcept = concepts.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
        child: SingleChildScrollView(
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
              const SizedBox(height: 24),

              // Title
              const Text(
                'What\'s confusing?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select the topic and describe your doubt.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),

              // ── LECTURE CONCEPT dropdown ─────────────────────────
              _buildDropdownLabel('LECTURE CONCEPT'),
              const SizedBox(height: 6),
              _buildDropdown(
                value: _selectedConcept,
                items: _concepts,
                hint: 'Select a concept',
                onChanged: (val) {
                  setState(() {
                    _selectedConcept = val;
                    _selectedDetail = null; // Reset detail
                  });
                },
              ),
              const SizedBox(height: 16),

              // ── SPECIFIC DETAIL dropdown ────────────────────────
              _buildDropdownLabel('SPECIFIC DETAIL'),
              const SizedBox(height: 6),
              _buildDropdown(
                value: _selectedDetail,
                items: _details,
                hint: 'Select a detail',
                onChanged: (val) {
                  setState(() => _selectedDetail = val);
                },
              ),
              const SizedBox(height: 16),

              // ── YOUR QUESTION label ─────────────────────────────
              _buildDropdownLabel('YOUR QUESTION'),
              const SizedBox(height: 6),

              // Text area
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.divider,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: widget.doubtController,
                  maxLines: 3,
                  minLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Type your doubt here...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Cancel + Send Doubt row
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onCancel,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Send Doubt button
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: widget.onSend,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Send Doubt',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
            size: 22,
          ),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(vertical: 4),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
