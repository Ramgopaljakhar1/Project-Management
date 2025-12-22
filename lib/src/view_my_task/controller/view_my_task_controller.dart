import 'dart:convert';
import 'dart:io';
import 'package:mime/mime.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project_management/src/services/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../utils/shared_pref_constants.dart';
import '../../utils/shared_preference.dart';

class ViewMyTaskController extends ChangeNotifier {
  Map<String, dynamic>? _task;
  bool _isLoading = false;
  int? _userId;

  Map<String, dynamic>? get task => _task;
  bool get isLoading => _isLoading;
  int? get userId => _userId;

  Future<void> initializeAndFetchTask(String taskId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final pref = SharedPref();
      final userData = await pref.read(SharedPrefConstant().kUserData);
      _userId = userData != null ? userData['id'] : null;

      print('user Id : --->>??: $_userId');
      if (_userId == null) {
        throw Exception('User ID not found in SharedPreferences');
      }

      final response = await ApiService.get('api/task_master/$taskId');
      _task = response;
      debugPrint('✅ Task fetched: $_task');
    } catch (e) {
      debugPrint('❌ Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Future<Map<String, dynamic>> updateTask({
  //   required String taskId,
  //   required Map<String, dynamic> existingTaskData,
  //   File? file,
  //   String? actualEstHrs,
  //   String? assignToRemark,
  //   DateTime? actualEstStartDate,
  //   DateTime? actualEstEndDate,
  // }) async {
  //   _isLoading = true;
  //   notifyListeners();
  //
  //   try {
  //     final apiUrl = '${ApiConstants.baseUrl}${ApiConstants.addTask}';
  //     debugPrint('🌐 API URL: $apiUrl');
  //     debugPrint('📦 Request data: $existingTaskData');
  //
  //     // Prepare the base request body
  //     final Map<String, dynamic> body = Map.from(existingTaskData);
  //     body['task_id'] = taskId;
  //
  //     // Handle file upload if present
  //     if (file != null) {
  //       try {
  //         final fileBytes = await file.readAsBytes();
  //         final base64File = base64Encode(fileBytes);
  //         final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
  //
  //         body['task_docs'] = base64File;
  //         debugPrint("📁 File attached as base64 ($mimeType)");
  //       } catch (e) {
  //         debugPrint("❌ Error processing file: $e");
  //         throw Exception('Failed to process file: $e');
  //       }
  //     }
  //
  //     // Make the POST request
  //     final response = await http.post(
  //       Uri.parse(apiUrl),
  //       headers: {
  //         'Accept': 'application/json',
  //         'Content-Type': 'application/json',
  //       },
  //       body: jsonEncode(body),
  //     );
  //
  //     debugPrint('🔁 Response Code: ${response.statusCode}');
  //     debugPrint('📥 Response Body: ${response.body}');
  //
  //     final jsonResponse = jsonDecode(response.body);
  //
  //     // ✅ Check the API response (not response object)
  //     if (jsonResponse['status'] == 'success') {
  //       debugPrint('✅ Update successful: $jsonResponse');
  //       return jsonResponse;
  //     } else {
  //       debugPrint('❌ API returned failure: $jsonResponse');
  //       throw Exception(jsonResponse['message'] ?? 'Failed to update task');
  //     }
  //   } catch (e) {
  //     debugPrint('❌ Error updating task: $e');
  //     rethrow;
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

///new update function
  Future<Map<String, dynamic>> updateTask({
    required String taskId,
    required Map<String, dynamic> existingTaskData,
    File? file,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final apiUrl = '${ApiConstants.baseUrl}${ApiConstants.addTask}';
      debugPrint('🌐 API URL: $apiUrl');
      debugPrint('📦 Request data: $existingTaskData');

      // Prepare the base request body
      final Map<String, dynamic> body = Map.from(existingTaskData);
      body['task_id'] = taskId;

      // Handle file upload if present - send as simple base64 string
      if (file != null) {
        try {
          final fileBytes = await file.readAsBytes();
          final base64File = base64Encode(fileBytes);

          // Send as simple base64 string, not as JSON object
          body['task_docs_re'] = base64File;

          debugPrint("📁 File attached as base64 string");
        } catch (e) {
          debugPrint("❌ Error processing file: $e");
          throw Exception('Failed to process file: $e');
        }
      } else {
        // If no new file, ensure task_docs_re is not included
        body.remove('task_docs_re');
      }

      // Make the POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('🔁 Response Code: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      final jsonResponse = jsonDecode(response.body);

      // ✅ Check the API response
      if (jsonResponse['status'] == 'success') {
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
      _isLoading = false;
      notifyListeners();
    }
  }


//
}
