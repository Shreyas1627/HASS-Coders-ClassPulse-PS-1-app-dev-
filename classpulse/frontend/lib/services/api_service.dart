import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use LAN IP for physical device testing, e.g. 192.168.x.x
  // Change this if your laptop's IP address changes!
  static const String _baseUrl = 'http://10.60.25.70:8000';

  static String get baseUrl => _baseUrl;

  static String? _studentUuid;
  static String? _sessionCode;
  static String? _teacherId;
  static String? _rollNumber;

  static String? get studentUuid => _studentUuid;
  static String? get sessionCode => _sessionCode;
  static String? get teacherId => _teacherId;
  static String? get rollNumber => _rollNumber;

  static void setTeacherId(String id) => _teacherId = id;
  static void setStudentUuid(String uuid) => _studentUuid = uuid;
  static void setSessionCode(String code) => _sessionCode = code;
  static void setRollNumber(String rn) => _rollNumber = rn;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  // ═══════════ TEACHER ENDPOINTS ═══════════

  /// Create a new live session
  static Future<Map<String, dynamic>?> createSession({
    required String className,
    required String subject,
    required String topic,
    String? subtopic,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/teacher/session/create'),
        headers: _headers,
        body: jsonEncode({
          'teacher_id': _teacherId ?? 'default_teacher',
          'class_name': className,
          'subject': subject,
          'topic': topic,
          'subtopic': subtopic,
          'latitude': latitude,
          'longitude': longitude,
        }),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  /// Get active sessions for a teacher
  static Future<List<Map<String, dynamic>>> getActiveSessions() async {
    try {
      final id = _teacherId ?? 'default_teacher';
      final res = await http.get(
        Uri.parse('$_baseUrl/api/teacher/sessions/active/$id'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['sessions'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  /// Get all active sessions (for students)
  static Future<List<Map<String, dynamic>>> getAllActiveSessions() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/student/sessions/active'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['sessions'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  /// Get session history grouped by class/subject
  static Future<Map<String, dynamic>?> getSessionHistory() async {
    try {
      final id = _teacherId ?? 'default_teacher';
      final res = await http.get(
        Uri.parse('$_baseUrl/api/teacher/sessions/history/$id'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  /// Get students aggregated from attendance data
  static Future<Map<String, dynamic>?> getStudents() async {
    try {
      final id = _teacherId ?? 'default_teacher';
      final res = await http.get(
        Uri.parse('$_baseUrl/api/teacher/students/$id'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  /// Poll live dashboard data
  static Future<Map<String, dynamic>?> pollDashboard(String sessionCode) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/teacher/dashboard/poll/$sessionCode'),
        headers: _headers,
      ).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  /// End a session
  static Future<Map<String, dynamic>?> endSession(String sessionCode) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/teacher/session/end/$sessionCode'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  /// Mark question addressed
  static Future<bool> markQuestionAddressed(String questionId, {bool addressed = true}) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/teacher/question/addressed'),
        headers: _headers,
        body: jsonEncode({'question_id': questionId, 'is_addressed': addressed}),
      ).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  /// Permanently dismiss a question
  static Future<bool> dismissQuestion(String questionId) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/teacher/question/dismiss'),
        headers: _headers,
        body: jsonEncode({'question_id': questionId}),
      ).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  /// Check session code validity
  static Future<Map<String, dynamic>?> checkSession(String sessionCode) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/teacher/session/check/$sessionCode'),
        headers: _headers,
      ).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  // ═══════════ STUDENT ENDPOINTS ═══════════

  /// Join session
  static Future<Map<String, dynamic>?> joinSession({
    required String sessionCode,
    required String rollNumber,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/student/join'),
        headers: _headers,
        body: jsonEncode({
          'session_code': sessionCode,
          'roll_number': rollNumber,
          'latitude': latitude,
          'longitude': longitude,
        }),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _studentUuid = data['student_uuid'];
        _sessionCode = sessionCode;
        _rollNumber = rollNumber;
        return data;
      } else {
        return {'error': jsonDecode(res.body)['detail'] ?? 'Join failed'};
      }
    } catch (_) {}
    return null;
  }

  /// Send comprehension signal
  static Future<bool> sendSignal({
    required String sessionCode,
    required String studentUuid,
    required String signal,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/student/signal'),
        headers: _headers,
        body: jsonEncode({
          'session_code': sessionCode,
          'student_uuid': studentUuid,
          'signal': signal,
        }),
      ).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  /// Submit doubt
  static Future<Map<String, dynamic>?> submitDoubt({
    required String sessionCode,
    required String studentUuid,
    required String text,
    String? parentId,
    String? subtopic,
  }) async {
    try {
      final body = {
        'session_code': sessionCode,
        'student_uuid': studentUuid,
        'text': text,
      };
      if (parentId != null) body['parent_id'] = parentId;
      if (subtopic != null) body['subtopic'] = subtopic;
      final res = await http.post(
        Uri.parse('$_baseUrl/api/student/doubt'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  /// Get questions for a session
  static Future<List<Map<String, dynamic>>> getQuestions(String sessionCode) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/student/questions/$sessionCode'),
        headers: _headers,
      ).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['questions'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  /// Upvote question
  static Future<bool> upvoteQuestion(String questionId) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/student/question/upvote'),
        headers: _headers,
        body: jsonEncode({'question_id': questionId}),
      ).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  /// Get session status (poll)
  static Future<Map<String, dynamic>?> pollSessionStatus(String sessionCode) async {
    try {
      String url = '$_baseUrl/api/student/poll/status/$sessionCode';
      if (_studentUuid != null) {
        url += '?student_uuid=$_studentUuid';
      }
      final res = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  /// Register app background (tab switch)
  static Future<Map<String, dynamic>?> registerTabSwitch() async {
    if (_sessionCode == null || _studentUuid == null) return null;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/student/tab-switch'),
        headers: _headers,
        body: jsonEncode({
          'session_code': _sessionCode,
          'student_uuid': _studentUuid,
        }),
      ).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  /// Unblock student (teacher)
  static Future<bool> unblockStudent({
    required String sessionCode,
    required String studentUuid,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/teacher/student/unblock'),
        headers: _headers,
        body: jsonEncode({
          'session_code': sessionCode,
          'student_uuid': studentUuid,
        }),
      ).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  /// Get student's past session history
  static Future<List<Map<String, dynamic>>> getStudentHistory(String rollNumber) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/student/history/$rollNumber'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['sessions'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  /// Get QR code image URL for a session
  static String getQrUrl(String sessionCode) {
    return '$_baseUrl/api/teacher/session/qr/$sessionCode';
  }

  /// Answer a doubt (AI or teacher)
  static Future<Map<String, dynamic>?> answerDoubt({
    required String questionId,
    String? answerText,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/teacher/doubt/answer'),
        headers: _headers,
        body: jsonEncode({
          'question_id': questionId,
          'answer_text': answerText,
        }),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  /// Preview AI answer without saving
  static Future<Map<String, dynamic>?> generateAiAnswer(String questionId) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/teacher/doubt/generate'),
        headers: _headers,
        body: jsonEncode({'question_id': questionId}),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  /// Advance to next subtopic in session
  static Future<Map<String, dynamic>?> advanceSubtopic(String sessionCode) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/teacher/session/advance-subtopic/$sessionCode'),
        headers: _headers,
      ).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }
}
