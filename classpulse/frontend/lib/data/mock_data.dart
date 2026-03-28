import 'package:flutter/material.dart';

// ─── Timetable ───────────────────────────────────────────────────────────────

class LectureSlot {
  final String time;
  final String className;
  final String subject;
  final String topic;
  final bool isCurrentOrPast; // for "Start Session" button state
  final String joinCode; // 4-digit code for live session

  const LectureSlot({
    required this.time,
    required this.className,
    required this.subject,
    required this.topic,
    this.isCurrentOrPast = false,
    this.joinCode = '0000',
  });
}

/// Mon = 0, Tue = 1, ... Sat = 5
final Map<int, List<LectureSlot>> weeklyTimetable = {
  0: [
    // Monday
    const LectureSlot(
      time: '08:30 – 09:20',
      className: 'Class 10A',
      subject: 'Mathematics',
      topic: 'Algebraic Expressions',
      isCurrentOrPast: true,
      joinCode: '4721',
    ),
    const LectureSlot(
      time: '09:30 – 10:20',
      className: 'Class 10B',
      subject: 'Mathematics',
      topic: 'Linear Equations',
      isCurrentOrPast: true,
      joinCode: '3856',
    ),
    const LectureSlot(
      time: '11:00 – 11:50',
      className: 'Class 9A',
      subject: 'Science',
      topic: 'Newton\'s Laws of Motion',
      joinCode: '9134',
    ),
    const LectureSlot(
      time: '12:00 – 12:50',
      className: 'Class 9B',
      subject: 'Science',
      topic: 'Force and Friction',
      joinCode: '6502',
    ),
  ],
  1: [
    // Tuesday
    const LectureSlot(
      time: '08:30 – 09:20',
      className: 'Class 10A',
      subject: 'Mathematics',
      topic: 'Quadratic Equations',
      isCurrentOrPast: true,
      joinCode: '7293',
    ),
    const LectureSlot(
      time: '10:00 – 10:50',
      className: 'Class 9A',
      subject: 'Science',
      topic: 'Work, Energy & Power',
      joinCode: '5148',
    ),
    const LectureSlot(
      time: '11:00 – 11:50',
      className: 'Class 10B',
      subject: 'Mathematics',
      topic: 'Polynomials',
      joinCode: '8367',
    ),
  ],
  2: [
    // Wednesday
    const LectureSlot(
      time: '09:00 – 09:50',
      className: 'Class 9B',
      subject: 'Science',
      topic: 'Gravitation',
      isCurrentOrPast: true,
      joinCode: '2941',
    ),
    const LectureSlot(
      time: '10:00 – 10:50',
      className: 'Class 10A',
      subject: 'Mathematics',
      topic: 'Coordinate Geometry',
      isCurrentOrPast: true,
      joinCode: '6073',
    ),
    const LectureSlot(
      time: '11:30 – 12:20',
      className: 'Class 10B',
      subject: 'Mathematics',
      topic: 'Triangles & Congruence',
      joinCode: '1584',
    ),
    const LectureSlot(
      time: '01:00 – 01:50',
      className: 'Class 9A',
      subject: 'Science',
      topic: 'Sound Waves',
      joinCode: '4826',
    ),
  ],
  3: [
    // Thursday
    const LectureSlot(
      time: '08:30 – 09:20',
      className: 'Class 10B',
      subject: 'Mathematics',
      topic: 'Statistics & Probability',
      isCurrentOrPast: true,
      joinCode: '3719',
    ),
    const LectureSlot(
      time: '10:00 – 10:50',
      className: 'Class 9B',
      subject: 'Science',
      topic: 'Light – Reflection',
      joinCode: '8462',
    ),
    const LectureSlot(
      time: '12:00 – 12:50',
      className: 'Class 10A',
      subject: 'Mathematics',
      topic: 'Circles & Tangents',
      joinCode: '5937',
    ),
  ],
  4: [
    // Friday
    const LectureSlot(
      time: '09:00 – 09:50',
      className: 'Class 9A',
      subject: 'Science',
      topic: 'Electricity & Circuits',
      isCurrentOrPast: true,
      joinCode: '7251',
    ),
    const LectureSlot(
      time: '10:00 – 10:50',
      className: 'Class 10A',
      subject: 'Mathematics',
      topic: 'Surface Areas & Volumes',
      isCurrentOrPast: true,
      joinCode: '4693',
    ),
    const LectureSlot(
      time: '11:30 – 12:20',
      className: 'Class 9B',
      subject: 'Science',
      topic: 'Magnetic Effects',
      joinCode: '2158',
    ),
  ],
  5: [], // Saturday — no classes
};

const List<String> dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

// ─── Today's Sessions (always populated for demo) ────────────────────────────

/// These sessions are always shown regardless of the day, so the demo always
/// has content. They use realistic college-level data per the user's request.
final List<LectureSlot> todaysSessions = const [
  LectureSlot(
    time: '09:00 – 09:50',
    className: 'Div A',
    subject: 'Database Management',
    topic: 'Normalization (1NF, 2NF, 3NF)',
    isCurrentOrPast: true,
    joinCode: '8241',
  ),
  LectureSlot(
    time: '10:00 – 10:50',
    className: 'Div B',
    subject: 'Computer Networks',
    topic: 'TCP/IP Protocol Stack',
    isCurrentOrPast: true,
    joinCode: '5739',
  ),
  LectureSlot(
    time: '11:30 – 12:20',
    className: 'Div A',
    subject: 'Operating Systems',
    topic: 'Process Scheduling Algorithms',
    isCurrentOrPast: false,
    joinCode: '3162',
  ),
  LectureSlot(
    time: '02:00 – 02:50',
    className: 'Div C',
    subject: 'Data Structures',
    topic: 'AVL Trees & Rotations',
    isCurrentOrPast: false,
    joinCode: '6847',
  ),
];

// ─── Missed Sessions ─────────────────────────────────────────────────────────

class MissedSession {
  final String date;
  final String subject;
  final String className;
  final String topic;

  const MissedSession({
    required this.date,
    required this.subject,
    required this.className,
    required this.topic,
  });
}

final List<MissedSession> missedSessions = const [
  MissedSession(
    date: 'Mar 5, 2026',
    subject: 'Mathematics',
    className: 'Class 10B',
    topic: 'Profit & Loss',
  ),
  MissedSession(
    date: 'Mar 12, 2026',
    subject: 'Science',
    className: 'Class 9A',
    topic: 'Acids, Bases & Salts',
  ),
  MissedSession(
    date: 'Mar 18, 2026',
    subject: 'Mathematics',
    className: 'Class 10A',
    topic: 'Arithmetic Progressions',
  ),
  MissedSession(
    date: 'Mar 24, 2026',
    subject: 'Science',
    className: 'Class 9B',
    topic: 'Carbon Compounds',
  ),
];

// ─── Student Data ────────────────────────────────────────────────────────────

class StudentInfo {
  final String name;
  final String initials;
  final Color avatarColor;
  final String insight;
  final bool isFlagged;

  const StudentInfo({
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.insight,
    this.isFlagged = false,
  });
}

final Map<String, List<StudentInfo>> studentsByClass = {
  'Class 10A': [
    StudentInfo(
      name: 'Aarav Sharma',
      initials: 'AS',
      avatarColor: const Color(0xFF6366F1),
      insight: 'Avg Comprehension: 91%',
    ),
    StudentInfo(
      name: 'Meera Patel',
      initials: 'MP',
      avatarColor: const Color(0xFF8B5CF6),
      insight: 'Avg Comprehension: 87%',
    ),
    StudentInfo(
      name: 'Rohan Gupta',
      initials: 'RG',
      avatarColor: const Color(0xFF06B6D4),
      insight: 'Avg Comprehension: 74%',
      isFlagged: true,
    ),
    StudentInfo(
      name: 'Priya Nair',
      initials: 'PN',
      avatarColor: const Color(0xFFF59E0B),
      insight: 'Avg Comprehension: 82%',
    ),
    StudentInfo(
      name: 'Kabir Mehta',
      initials: 'KM',
      avatarColor: const Color(0xFF10B981),
      insight: 'Avg Comprehension: 68%',
      isFlagged: true,
    ),
    StudentInfo(
      name: 'Ananya Reddy',
      initials: 'AR',
      avatarColor: const Color(0xFFEC4899),
      insight: 'Avg Comprehension: 95%',
    ),
  ],
  'Class 10B': [
    StudentInfo(
      name: 'Vivaan Joshi',
      initials: 'VJ',
      avatarColor: const Color(0xFF3B82F6),
      insight: 'Avg Comprehension: 79%',
    ),
    StudentInfo(
      name: 'Ishita Das',
      initials: 'ID',
      avatarColor: const Color(0xFFF97316),
      insight: 'Avg Comprehension: 88%',
    ),
    StudentInfo(
      name: 'Arjun Kulkarni',
      initials: 'AK',
      avatarColor: const Color(0xFF14B8A6),
      insight: 'Avg Comprehension: 62%',
      isFlagged: true,
    ),
    StudentInfo(
      name: 'Diya Kapoor',
      initials: 'DK',
      avatarColor: const Color(0xFFA855F7),
      insight: 'Avg Comprehension: 84%',
    ),
    StudentInfo(
      name: 'Sai Iyer',
      initials: 'SI',
      avatarColor: const Color(0xFF0EA5E9),
      insight: 'Avg Comprehension: 71%',
      isFlagged: true,
    ),
  ],
  'Class 9A': [
    StudentInfo(
      name: 'Advika Singh',
      initials: 'AS',
      avatarColor: const Color(0xFFE11D48),
      insight: 'Avg Comprehension: 90%',
    ),
    StudentInfo(
      name: 'Reyansh Tiwari',
      initials: 'RT',
      avatarColor: const Color(0xFF7C3AED),
      insight: 'Avg Comprehension: 76%',
    ),
    StudentInfo(
      name: 'Saanvi Verma',
      initials: 'SV',
      avatarColor: const Color(0xFF059669),
      insight: 'Avg Comprehension: 85%',
    ),
    StudentInfo(
      name: 'Vihaan Choudhary',
      initials: 'VC',
      avatarColor: const Color(0xFFD97706),
      insight: 'Avg Comprehension: 58%',
      isFlagged: true,
    ),
    StudentInfo(
      name: 'Kiara Banerjee',
      initials: 'KB',
      avatarColor: const Color(0xFF2563EB),
      insight: 'Avg Comprehension: 93%',
    ),
  ],
  'Class 9B': [
    StudentInfo(
      name: 'Arnav Saxena',
      initials: 'AS',
      avatarColor: const Color(0xFF0891B2),
      insight: 'Avg Comprehension: 81%',
    ),
    StudentInfo(
      name: 'Tara Bhatt',
      initials: 'TB',
      avatarColor: const Color(0xFFDB2777),
      insight: 'Avg Comprehension: 77%',
    ),
    StudentInfo(
      name: 'Dhruv Pandey',
      initials: 'DP',
      avatarColor: const Color(0xFF4F46E5),
      insight: 'Avg Comprehension: 65%',
      isFlagged: true,
    ),
    StudentInfo(
      name: 'Navya Agarwal',
      initials: 'NA',
      avatarColor: const Color(0xFF16A34A),
      insight: 'Avg Comprehension: 89%',
    ),
  ],
};

// ─── Session History ─────────────────────────────────────────────────────────

class PastSession {
  final String sessionId;
  final String date;
  final String topic;
  final int attended;
  final int total;

  const PastSession({
    required this.sessionId,
    required this.date,
    required this.topic,
    required this.attended,
    required this.total,
  });
}

/// Classes → Subjects → Past sessions
final Map<String, Map<String, List<PastSession>>> sessionHistory = {
  'Class 10A': {
    'Mathematics': const [
      PastSession(
        sessionId: '#CP-8492',
        date: 'Mar 26, 2026',
        topic: 'Coordinate Geometry',
        attended: 28,
        total: 30,
      ),
      PastSession(
        sessionId: '#CP-8401',
        date: 'Mar 24, 2026',
        topic: 'Algebraic Expressions',
        attended: 27,
        total: 30,
      ),
      PastSession(
        sessionId: '#CP-8356',
        date: 'Mar 21, 2026',
        topic: 'Quadratic Equations',
        attended: 30,
        total: 30,
      ),
      PastSession(
        sessionId: '#CP-8290',
        date: 'Mar 19, 2026',
        topic: 'Linear Equations',
        attended: 25,
        total: 30,
      ),
    ],
  },
  'Class 10B': {
    'Mathematics': const [
      PastSession(
        sessionId: '#CP-8488',
        date: 'Mar 25, 2026',
        topic: 'Polynomials',
        attended: 32,
        total: 34,
      ),
      PastSession(
        sessionId: '#CP-8410',
        date: 'Mar 22, 2026',
        topic: 'Statistics & Probability',
        attended: 30,
        total: 34,
      ),
      PastSession(
        sessionId: '#CP-8335',
        date: 'Mar 20, 2026',
        topic: 'Triangles & Congruence',
        attended: 33,
        total: 34,
      ),
    ],
  },
  'Class 9A': {
    'Science': const [
      PastSession(
        sessionId: '#CP-8475',
        date: 'Mar 27, 2026',
        topic: 'Electricity & Circuits',
        attended: 26,
        total: 28,
      ),
      PastSession(
        sessionId: '#CP-8420',
        date: 'Mar 23, 2026',
        topic: 'Newton\'s Laws of Motion',
        attended: 28,
        total: 28,
      ),
      PastSession(
        sessionId: '#CP-8380',
        date: 'Mar 20, 2026',
        topic: 'Work, Energy & Power',
        attended: 24,
        total: 28,
      ),
      PastSession(
        sessionId: '#CP-8312',
        date: 'Mar 17, 2026',
        topic: 'Sound Waves',
        attended: 27,
        total: 28,
      ),
    ],
  },
  'Class 9B': {
    'Science': const [
      PastSession(
        sessionId: '#CP-8460',
        date: 'Mar 26, 2026',
        topic: 'Gravitation',
        attended: 24,
        total: 26,
      ),
      PastSession(
        sessionId: '#CP-8395',
        date: 'Mar 22, 2026',
        topic: 'Force and Friction',
        attended: 25,
        total: 26,
      ),
      PastSession(
        sessionId: '#CP-8340',
        date: 'Mar 19, 2026',
        topic: 'Light – Reflection',
        attended: 22,
        total: 26,
      ),
    ],
  },
};

// ─── Live Session Mock Students ──────────────────────────────────────────────

enum ComprehensionSignal { gotIt, sortOf, lost, noVote }

class LiveStudent {
  final String alias;
  final String initials;
  final Color avatarColor;
  final ComprehensionSignal signal;

  const LiveStudent({
    required this.alias,
    required this.initials,
    required this.avatarColor,
    required this.signal,
  });
}

/// Mock students for the live session grid (Google Meet style)
final List<LiveStudent> liveSessionStudents = const [
  LiveStudent(alias: 'Student 01', initials: 'S1', avatarColor: Color(0xFF6366F1), signal: ComprehensionSignal.gotIt),
  LiveStudent(alias: 'Student 02', initials: 'S2', avatarColor: Color(0xFF8B5CF6), signal: ComprehensionSignal.gotIt),
  LiveStudent(alias: 'Student 03', initials: 'S3', avatarColor: Color(0xFF06B6D4), signal: ComprehensionSignal.sortOf),
  LiveStudent(alias: 'Student 04', initials: 'S4', avatarColor: Color(0xFFF59E0B), signal: ComprehensionSignal.lost),
  LiveStudent(alias: 'Student 05', initials: 'S5', avatarColor: Color(0xFF10B981), signal: ComprehensionSignal.gotIt),
  LiveStudent(alias: 'Student 06', initials: 'S6', avatarColor: Color(0xFFEC4899), signal: ComprehensionSignal.noVote),
  LiveStudent(alias: 'Student 07', initials: 'S7', avatarColor: Color(0xFF3B82F6), signal: ComprehensionSignal.gotIt),
  LiveStudent(alias: 'Student 08', initials: 'S8', avatarColor: Color(0xFFF97316), signal: ComprehensionSignal.sortOf),
  LiveStudent(alias: 'Student 09', initials: 'S9', avatarColor: Color(0xFF14B8A6), signal: ComprehensionSignal.gotIt),
  LiveStudent(alias: 'Student 10', initials: 'S0', avatarColor: Color(0xFFA855F7), signal: ComprehensionSignal.noVote),
  LiveStudent(alias: 'Student 11', initials: '11', avatarColor: Color(0xFF0EA5E9), signal: ComprehensionSignal.lost),
  LiveStudent(alias: 'Student 12', initials: '12', avatarColor: Color(0xFFE11D48), signal: ComprehensionSignal.gotIt),
  LiveStudent(alias: 'Student 13', initials: '13', avatarColor: Color(0xFF7C3AED), signal: ComprehensionSignal.sortOf),
  LiveStudent(alias: 'Student 14', initials: '14', avatarColor: Color(0xFF059669), signal: ComprehensionSignal.gotIt),
  LiveStudent(alias: 'Student 15', initials: '15', avatarColor: Color(0xFFD97706), signal: ComprehensionSignal.noVote),
  LiveStudent(alias: 'Student 16', initials: '16', avatarColor: Color(0xFF2563EB), signal: ComprehensionSignal.gotIt),
  LiveStudent(alias: 'Student 17', initials: '17', avatarColor: Color(0xFF0891B2), signal: ComprehensionSignal.sortOf),
  LiveStudent(alias: 'Student 18', initials: '18', avatarColor: Color(0xFFDB2777), signal: ComprehensionSignal.gotIt),
  LiveStudent(alias: 'Student 19', initials: '19', avatarColor: Color(0xFF4F46E5), signal: ComprehensionSignal.lost),
  LiveStudent(alias: 'Student 20', initials: '20', avatarColor: Color(0xFF16A34A), signal: ComprehensionSignal.gotIt),
  LiveStudent(alias: 'Student 21', initials: '21', avatarColor: Color(0xFF9333EA), signal: ComprehensionSignal.noVote),
  LiveStudent(alias: 'Student 22', initials: '22', avatarColor: Color(0xFFEA580C), signal: ComprehensionSignal.gotIt),
  LiveStudent(alias: 'Student 23', initials: '23', avatarColor: Color(0xFF0D9488), signal: ComprehensionSignal.sortOf),
  LiveStudent(alias: 'Student 24', initials: '24', avatarColor: Color(0xFFC026D3), signal: ComprehensionSignal.gotIt),
];

/// Milestone topics for the live session tracker
class SessionMilestones {
  final String previousTopic;
  final String currentTopic;
  final String nextTopic;

  const SessionMilestones({
    required this.previousTopic,
    required this.currentTopic,
    required this.nextTopic,
  });
}

// ─── Student-specific Data ────────────────────────────────────────────────────

/// Student's class (he/she is in Class 10A)
const String studentClassName = 'Class 10A';
const String studentName = 'Aarav Sharma';

/// Student's weekly timetable — from a Class 10A student perspective
final Map<int, List<LectureSlot>> studentWeeklyTimetable = {
  0: [
    // Monday
    const LectureSlot(time: '08:30 – 09:20', className: 'Class 10A', subject: 'Mathematics', topic: 'Algebraic Expressions', isCurrentOrPast: true, joinCode: '4721'),
    const LectureSlot(time: '09:30 – 10:20', className: 'Class 10A', subject: 'English', topic: 'Shakespearean Sonnets', isCurrentOrPast: true, joinCode: '1234'),
    const LectureSlot(time: '11:00 – 11:50', className: 'Class 10A', subject: 'Science', topic: 'Chemical Reactions', joinCode: '5678'),
    const LectureSlot(time: '12:00 – 12:50', className: 'Class 10A', subject: 'Hindi', topic: 'Kabir ke Dohe', joinCode: '9012'),
  ],
  1: [
    // Tuesday
    const LectureSlot(time: '08:30 – 09:20', className: 'Class 10A', subject: 'Mathematics', topic: 'Quadratic Equations', isCurrentOrPast: true, joinCode: '7293'),
    const LectureSlot(time: '10:00 – 10:50', className: 'Class 10A', subject: 'Science', topic: 'Acids, Bases & Salts', joinCode: '3456'),
    const LectureSlot(time: '11:00 – 11:50', className: 'Class 10A', subject: 'Social Studies', topic: 'French Revolution', joinCode: '7890'),
  ],
  2: [
    // Wednesday
    const LectureSlot(time: '09:00 – 09:50', className: 'Class 10A', subject: 'English', topic: 'Letter Writing', isCurrentOrPast: true, joinCode: '2345'),
    const LectureSlot(time: '10:00 – 10:50', className: 'Class 10A', subject: 'Mathematics', topic: 'Coordinate Geometry', isCurrentOrPast: true, joinCode: '6073'),
    const LectureSlot(time: '11:30 – 12:20', className: 'Class 10A', subject: 'Science', topic: 'Periodic Classification', joinCode: '6789'),
  ],
  3: [
    // Thursday
    const LectureSlot(time: '08:30 – 09:20', className: 'Class 10A', subject: 'Science', topic: 'Light & Reflection', isCurrentOrPast: true, joinCode: '0123'),
    const LectureSlot(time: '10:00 – 10:50', className: 'Class 10A', subject: 'Mathematics', topic: 'Trigonometry', isCurrentOrPast: true, joinCode: '4567'),
    const LectureSlot(time: '11:30 – 12:20', className: 'Class 10A', subject: 'Hindi', topic: 'Surdas ke Pad', joinCode: '8901'),
  ],
  4: [
    // Friday
    const LectureSlot(time: '09:00 – 09:50', className: 'Class 10A', subject: 'Science', topic: 'Electricity & Circuits', isCurrentOrPast: true, joinCode: '7251'),
    const LectureSlot(time: '10:00 – 10:50', className: 'Class 10A', subject: 'Mathematics', topic: 'Surface Areas & Volumes', isCurrentOrPast: true, joinCode: '4693'),
    const LectureSlot(time: '11:30 – 12:20', className: 'Class 10A', subject: 'Social Studies', topic: 'Nationalism in India', joinCode: '2158'),
  ],
  5: [], // Saturday — no classes
};

/// Student past sessions with their signal
class StudentPastSession {
  final String subject;
  final String topic;
  final String date;
  final String signal; // 'understood', 'maybe', 'not_understood'
  final String? doubt;

  const StudentPastSession({
    required this.subject,
    required this.topic,
    required this.date,
    required this.signal,
    this.doubt,
  });
}

final List<StudentPastSession> studentPastSessions = const [
  StudentPastSession(subject: 'Mathematics', topic: 'Algebraic Expressions', date: '27 Mar', signal: 'understood'),
  StudentPastSession(subject: 'Science', topic: 'Chemical Reactions', date: '27 Mar', signal: 'maybe', doubt: 'How does a catalyst speed up the reaction?'),
  StudentPastSession(subject: 'Mathematics', topic: 'Quadratic Equations', date: '26 Mar', signal: 'understood'),
  StudentPastSession(subject: 'English', topic: 'Shakespearean Sonnets', date: '26 Mar', signal: 'not_understood', doubt: 'What is iambic pentameter exactly?'),
  StudentPastSession(subject: 'Science', topic: 'Periodic Classification', date: '25 Mar', signal: 'understood'),
  StudentPastSession(subject: 'Mathematics', topic: 'Coordinate Geometry', date: '25 Mar', signal: 'maybe', doubt: 'Confused between section and midpoint formulas'),
  StudentPastSession(subject: 'Hindi', topic: 'Kabir ke Dohe', date: '24 Mar', signal: 'understood'),
  StudentPastSession(subject: 'Science', topic: 'Light & Reflection', date: '24 Mar', signal: 'not_understood', doubt: 'Mirror formula sign convention is confusing'),
];

/// Valid join codes that map to active sessions (for demo)
final Map<String, LectureSlot> activeJoinCodes = {
  '4721': const LectureSlot(time: '08:30 – 09:20', className: 'Class 10A', subject: 'Mathematics', topic: 'Algebraic Expressions', isCurrentOrPast: true, joinCode: '4721'),
  '7293': const LectureSlot(time: '08:30 – 09:20', className: 'Class 10A', subject: 'Mathematics', topic: 'Quadratic Equations', isCurrentOrPast: true, joinCode: '7293'),
  '7251': const LectureSlot(time: '09:00 – 09:50', className: 'Class 10A', subject: 'Science', topic: 'Electricity & Circuits', isCurrentOrPast: true, joinCode: '7251'),
  '1234': const LectureSlot(time: 'Live', className: 'Class 10A', subject: 'English', topic: 'Shakespearean Sonnets', isCurrentOrPast: true, joinCode: '1234'),
};
