import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// API Service for web platform
/// Communicates with the backend REST API instead of Firebase
class ApiService {
  static const String baseUrl = kDebugMode 
      ? 'http://localhost:3000/api' 
      : 'https://your-production-api.com/api';
  
  String? _token;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  void setToken(String token) {
    _token = token;
  }

  String? get token => _token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ========== GENERIC HTTP METHODS ==========

  /// Generic GET request
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Request failed');
      }
    } catch (e) {
      throw Exception('GET request error: $e');
    }
  }

  /// Generic POST request
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Request failed');
      }
    } catch (e) {
      throw Exception('POST request error: $e');
    }
  }

  /// Generic PUT request
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Request failed');
      }
    } catch (e) {
      throw Exception('PUT request error: $e');
    }
  }

  /// Generic DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.body.isEmpty) {
          return {'success': true};
        }
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Request failed');
      }
    } catch (e) {
      throw Exception('DELETE request error: $e');
    }
  }

  // ========== AUTHENTICATION ==========

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'role': role,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        return data;
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Attempting login for: $email');
      debugPrint('📡 API URL: $baseUrl/auth/login');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        debugPrint('✅ Login successful! Token received');
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error'] ?? 'Login failed';
        debugPrint('❌ Login failed: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('🔥 Login error: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        throw Exception('Не удалось подключиться к серверу. Убедитесь, что backend запущен на $baseUrl');
      }
      throw Exception('Ошибка входа: $e');
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get user data');
      }
    } catch (e) {
      throw Exception('Get user error: $e');
    }
  }

  void logout() {
    _token = null;
  }

  // ========== GROUPS ==========

  Future<List<Map<String, dynamic>>> getMyGroups() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/groups/my-groups'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get groups');
      }
    } catch (e) {
      throw Exception('Get groups error: $e');
    }
  }

  Future<Map<String, dynamic>> createGroup({
    required String name,
    String? description,
    String? courseCode,
    String? semester,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/groups'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'description': description,
          'courseCode': courseCode,
          'semester': semester,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create group');
      }
    } catch (e) {
      throw Exception('Create group error: $e');
    }
  }

  Future<Map<String, dynamic>> getGroup(String groupId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/groups/$groupId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get group');
      }
    } catch (e) {
      throw Exception('Get group error: $e');
    }
  }

  Future<void> updateGroup(String groupId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/groups/$groupId'),
        headers: _headers,
        body: jsonEncode(data),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update group');
      }
    } catch (e) {
      throw Exception('Update group error: $e');
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/groups/$groupId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete group');
      }
    } catch (e) {
      throw Exception('Delete group error: $e');
    }
  }

  // ========== STUDENTS ==========

  Future<List<Map<String, dynamic>>> getAllStudents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/students'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get all students');
      }
    } catch (e) {
      throw Exception('Get all students error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsByGroup(String groupId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/students/group/$groupId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get students');
      }
    } catch (e) {
      throw Exception('Get students error: $e');
    }
  }

  Future<Map<String, dynamic>> createStudent({
    required String name,
    String? email,
    String? phone,
    String? groupId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/students'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'groupId': groupId,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create student');
      }
    } catch (e) {
      throw Exception('Create student error: $e');
    }
  }

  // ========== LESSONS ==========

  Future<List<Map<String, dynamic>>> getLessonsByGroup(String groupId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lessons/group/$groupId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get lessons');
      }
    } catch (e) {
      throw Exception('Get lessons error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getActiveLessons() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lessons/active'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get active lessons');
      }
    } catch (e) {
      throw Exception('Get active lessons error: $e');
    }
  }

  Future<void> refreshLessonQR(String lessonId, String qrCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lessons/$lessonId/refresh-qr'),
        headers: _headers,
        body: jsonEncode({'qrCode': qrCode}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to refresh QR');
      }
    } catch (e) {
      throw Exception('Refresh QR error: $e');
    }
  }

  Future<void> endLesson(String lessonId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lessons/$lessonId/end'),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to end lesson');
      }
    } catch (e) {
      throw Exception('End lesson error: $e');
    }
  }

  Future<Map<String, dynamic>> createLesson({
    required String groupId,
    required String title,
    String? description,
    required DateTime date,
    int? duration,
    String? qrCode,
    String? type,
    String? startTime,
    String? endTime,
    String? classroom,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lessons'),
        headers: _headers,
        body: jsonEncode({
          'groupId': groupId,
          'title': title,
          'description': description,
          'date': date.toIso8601String(),
          'duration': duration ?? 90,
          'qrCode': qrCode,
          'type': type,
          'startTime': startTime,
          'endTime': endTime,
          'classroom': classroom,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create lesson');
      }
    } catch (e) {
      throw Exception('Create lesson error: $e');
    }
  }

  // ========== ATTENDANCE ==========

  Future<Map<String, dynamic>> markAttendance({
    required String lessonId,
    required String studentId,
    String status = 'present',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance'),
        headers: _headers,
        body: jsonEncode({
          'lessonId': lessonId,
          'studentId': studentId,
          'status': status,
          'scannedAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to mark attendance');
      }
    } catch (e) {
      throw Exception('Mark attendance error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceByLesson(String lessonId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/lesson/$lessonId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get attendance');
      }
    } catch (e) {
      throw Exception('Get attendance error: $e');
    }
  }

  // ========== STUDENT-SPECIFIC ==========

  /// Get current student profile
  Future<Map<String, dynamic>> getStudentProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/students/me'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Student profile not found');
      }
    } catch (e) {
      throw Exception('Get student profile error: $e');
    }
  }

  /// Get current student's groups with lessons
  Future<List<Map<String, dynamic>>> getStudentGroups() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/students/me/groups'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get student groups');
      }
    } catch (e) {
      throw Exception('Get student groups error: $e');
    }
  }

  /// Mark attendance by QR code
  Future<Map<String, dynamic>> markAttendanceByQR(String qrCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/qr'),
        headers: _headers,
        body: jsonEncode({'qrCode': qrCode}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to mark attendance');
      }
    } catch (e) {
      throw Exception('Mark attendance error: $e');
    }
  }

  /// Get current student's attendance history and stats
  Future<Map<String, dynamic>> getMyAttendance() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/me'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get attendance');
      }
    } catch (e) {
      throw Exception('Get my attendance error: $e');
    }
  }
}
