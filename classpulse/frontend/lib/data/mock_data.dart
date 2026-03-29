import 'package:flutter/material.dart';

// ─── Timetable / Session Model ───────────────────────────────────────────────

class LectureSlot {
  final String time;
  final String className;
  final String subject;
  final String topic;
  final bool isCurrentOrPast;
  final String joinCode;
  final String? sessionId;
  final bool isActive;
  final List<String> subtopics;
  final int currentSubtopicIndex;

  const LectureSlot({
    required this.time,
    required this.className,
    required this.subject,
    required this.topic,
    this.isCurrentOrPast = false,
    this.joinCode = '0000',
    this.sessionId,
    this.isActive = true,
    this.subtopics = const [],
    this.currentSubtopicIndex = 0,
  });

  factory LectureSlot.fromJson(Map<String, dynamic> json) {
    final subtopicRaw = json['subtopic'] as String? ?? '';
    final parsedSubtopics = subtopicRaw.isNotEmpty
        ? subtopicRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    return LectureSlot(
      time: json['created_at'] != null
          ? _formatTime(json['created_at'] as String)
          : 'Live',
      className: json['class_name'] ?? '',
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      isCurrentOrPast: json['is_active'] == true,
      joinCode: json['session_code'] ?? '0000',
      sessionId: json['id'],
      isActive: json['is_active'] == true,
      subtopics: parsedSubtopics,
      currentSubtopicIndex: json['current_subtopic_index'] as int? ?? 0,
    );
  }

  static String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hour:$min $amPm';
    } catch (_) {
      return 'Live';
    }
  }
}

const List<String> dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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

  factory PastSession.fromJson(Map<String, dynamic> json, {int attended = 0, int total = 0}) {
    final createdAt = json['created_at'] as String? ?? '';
    String formattedDate = '';
    try {
      final dt = DateTime.parse(createdAt);
      final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      formattedDate = '${months[dt.month]} ${dt.day}, ${dt.year}';
    } catch (_) {}

    return PastSession(
      sessionId: '#${(json['session_code'] ?? '').toString()}',
      date: formattedDate,
      topic: json['topic'] ?? json['subject'] ?? '',
      attended: attended,
      total: total,
    );
  }
}

// ─── Live Session ────────────────────────────────────────────────────────────

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

// ─── Live Question Queue ──────────────────────────────────────────────────────

class StudentQuestion {
  final String text;
  final String timeAgo;
  final int upvotes;
  final bool isAddressed;
  final String? questionId;
  final String? studentUuid;
  final String? subtopic;

  const StudentQuestion({
    required this.text,
    required this.timeAgo,
    this.upvotes = 1,
    this.isAddressed = false,
    this.questionId,
    this.studentUuid,
    this.subtopic,
  });
}

// ─── Student Past Session ────────────────────────────────────────────────────

class StudentPastSession {
  final String subject;
  final String topic;
  final String date;
  final String signal;
  final String? doubt;

  const StudentPastSession({
    required this.subject,
    required this.topic,
    required this.date,
    required this.signal,
    this.doubt,
  });
}

// ─── Timetable Entry ─────────────────────────────────────────────────────────

class TimetableEntry {
  final String id;
  final String teacherId;
  final String className;
  final String subject;
  final String? topic;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isHoliday;
  final String? status; // 'upcoming', 'now', 'passed'
  final bool alreadyStarted;
  final Map<String, dynamic>? existingSession;
  // Student-specific
  final bool isLive;
  final Map<String, dynamic>? liveSession;

  const TimetableEntry({
    required this.id,
    required this.teacherId,
    required this.className,
    required this.subject,
    this.topic,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isHoliday = false,
    this.status,
    this.alreadyStarted = false,
    this.existingSession,
    this.isLive = false,
    this.liveSession,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      id: json['id'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      className: json['class_name'] ?? '',
      subject: json['subject'] ?? '',
      topic: json['topic'],
      dayOfWeek: json['day_of_week'] ?? 0,
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      isHoliday: json['is_holiday'] ?? false,
      status: json['status'],
      alreadyStarted: json['already_started'] ?? false,
      existingSession: json['existing_session'],
      isLive: json['is_live'] ?? false,
      liveSession: json['live_session'],
    );
  }

  String get formattedTime {
    String fmt(String t) {
      final parts = t.split(':');
      if (parts.length < 2) return t;
      int h = int.tryParse(parts[0]) ?? 0;
      final m = parts[1];
      final amPm = h >= 12 ? 'PM' : 'AM';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      return '$h:$m $amPm';
    }
    return '${fmt(startTime)} – ${fmt(endTime)}';
  }

  String get startTimeFormatted {
    final parts = startTime.split(':');
    if (parts.length < 2) return startTime;
    int h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    return '$h:$m';
  }
}

// ─── Missed Session Entry ────────────────────────────────────────────────────

class MissedSessionEntry {
  final String id;
  final String? timetableId;
  final String teacherId;
  final String className;
  final String subject;
  final String? topic;
  final String scheduledDate;
  final String startTime;
  final String endTime;

  const MissedSessionEntry({
    required this.id,
    this.timetableId,
    required this.teacherId,
    required this.className,
    required this.subject,
    this.topic,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
  });

  factory MissedSessionEntry.fromJson(Map<String, dynamic> json) {
    return MissedSessionEntry(
      id: json['id'] ?? '',
      timetableId: json['timetable_id'],
      teacherId: json['teacher_id'] ?? '',
      className: json['class_name'] ?? '',
      subject: json['subject'] ?? '',
      topic: json['topic'],
      scheduledDate: json['scheduled_date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
    );
  }

  String get formattedDate {
    try {
      final dt = DateTime.parse(scheduledDate);
      final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month]} ${dt.day}';
    } catch (_) {
      return scheduledDate;
    }
  }

  String get formattedTime {
    String fmt(String t) {
      final parts = t.split(':');
      if (parts.length < 2) return t;
      int h = int.tryParse(parts[0]) ?? 0;
      final m = parts[1];
      final amPm = h >= 12 ? 'PM' : 'AM';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      return '$h:$m $amPm';
    }
    return '${fmt(startTime)} – ${fmt(endTime)}';
  }
}
