import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../data/mock_data.dart';

class StudentsTab extends StatefulWidget {
  const StudentsTab({super.key});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  // Track which class panels are expanded
  final Map<String, bool> _expanded = {};

  @override
  void initState() {
    super.initState();
    // Auto-expand the first class
    final firstKey = studentsByClass.keys.first;
    _expanded[firstKey] = true;
  }

  @override
  Widget build(BuildContext context) {
    final classes = studentsByClass.keys.toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header
          Row(
            children: [
              const Icon(Icons.people_outline_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Student Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Insights by class',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          ...classes.map((className) => _buildClassAccordion(className)),
        ],
      ),
    );
  }

  Widget _buildClassAccordion(String className) {
    final isExpanded = _expanded[className] ?? false;
    final students = studentsByClass[className] ?? [];
    final studentCount = students.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded ? AppColors.primary.withValues(alpha: 0.3) : AppColors.divider,
          width: 1.5,
        ),
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
          // Header
          GestureDetector(
            onTap: () {
              setState(() {
                _expanded[className] = !isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isExpanded
                    ? AppColors.primary.withValues(alpha: 0.04)
                    : Colors.transparent,
                borderRadius: isExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14))
                    : BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.class_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        const SizedBox(height: 2),
                        Text(
                          '$studentCount students',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Student list
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              children: [
                Divider(height: 1, color: AppColors.divider),
                ...students.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final student = entry.value;
                  return Column(
                    children: [
                      _buildStudentRow(student),
                      if (idx < students.length - 1)
                        Divider(
                          height: 1,
                          indent: 68,
                          color: AppColors.divider.withValues(alpha: 0.6),
                        ),
                    ],
                  );
                }),
              ],
            ),
            crossFadeState:
                isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(StudentInfo student) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: student.avatarColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                student.initials,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: student.avatarColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  student.insight,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: student.isFlagged
                        ? AppColors.warning
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Flagged badge
          if (student.isFlagged)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_rounded, size: 12, color: AppColors.warning),
                  const SizedBox(width: 3),
                  Text(
                    'At Risk',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
