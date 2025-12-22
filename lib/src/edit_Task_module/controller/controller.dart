import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../services/api_service.dart';
import '../../services/constants/api_constants.dart';
import '../../utils/shared_pref_constants.dart';
import '../../utils/shared_preference.dart';

class EditTaskController extends ChangeNotifier {
  bool isLoading = false;
  Map<String, dynamic>? _task;
  String? error;
  String? token;
  Map<String, dynamic>? user;
  String? userId;


  Future<void> loadUserDataAndFetchDelayedTasks() async {
    final prefs = SharedPref();
    token = await prefs.read(SharedPrefConstant().kAuthToken);
    user = await prefs.read(SharedPrefConstant().kUserData);
    userId = user?['id']?.toString();

    debugPrint("👤 [DELAYED] Loaded User ID: $userId");
    debugPrint("🔐 [DELAYED] Loaded Token: $token");


  }

  Map<String, dynamic>? get task => _task;

  Future<void> fetchTaskDetailById(String taskId) async {
    isLoading = true;
    notifyListeners();
    debugPrint("📌 Fetching Task Detail - User ID: $userId | Task ID: $taskId");
    try {
      final response = await ApiService.get('${ApiConstants.addTask}$taskId/');
      if (response != null && response.isNotEmpty) {
        _task = response;
        print('✅ Task details fetched successfully');
      } else {
        error = 'Task not found';
        print('❌ Task not found');
      }
    } catch (e) {
      error = e.toString();
      print('❌ Error fetching task details: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateTask({
    required String taskId,
    required Map<String, dynamic> taskData,
    File? file,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final apiUrl = '${ApiConstants.baseUrl}${ApiConstants.addTask}';
      debugPrint('🌐 API URL: $apiUrl');

      final Map<String, dynamic> body = Map.from(taskData);
      body['task_id'] = taskId;

      // File handling
      if (file != null) {
        try {
          final fileBytes = await file.readAsBytes();
          final base64File = base64Encode(fileBytes);
          final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

          body['task_docs'] = base64File;
          body['task_docs_mime'] = mimeType;
          debugPrint("📁 File attached as base64 ($mimeType)");
        } catch (e) {
          debugPrint("❌ Error processing file: $e");
          throw Exception('Failed to process file: $e');
        }
      }

      debugPrint('📦 Request Body: $body');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('📡 Response Code: ${response.statusCode}');
      debugPrint('📨 Response Body: ${response.body}');

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status']?.toString().toLowerCase() == 'success') {
        debugPrint('✅ Update successful: $jsonResponse');
        return jsonResponse;
      } else {
        debugPrint('❌ API returned failure: $jsonResponse');
        throw Exception(jsonResponse['message'] ?? 'Failed to update task');
      }
    } catch (e) {
      debugPrint('❌ Error updating task: $e');
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }



  Future<List<Map<String, dynamic>>> fetchUserList() async {
    try {
      final response = await ApiService.get(
        ApiConstants.user_list,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response != null && response['user_list'] != null) {
        final userList = (response['user_list'] as List)
            .cast<Map<String, dynamic>>();
        debugPrint('✅ User List--->: $userList');
        return userList;
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching user list: $e');
      rethrow;
    }
  }
}