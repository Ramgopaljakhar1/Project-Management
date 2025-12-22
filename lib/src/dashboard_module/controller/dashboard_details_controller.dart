// DashboardDetailsController.dart
import 'package:flutter/material.dart';
import 'package:project_management/src/services/api_service.dart';
import '../../services/constants/api_constants.dart';
import '../../utils/shared_pref_constants.dart';
import '../../utils/shared_preference.dart';
import '../model/task_count_model.dart';

class DashboardDetailsController extends ChangeNotifier {
  TaskSummaryCount? taskSummary;
  bool get hasSummary => taskSummary != null;
  int get myTasksCount => taskSummary?.myTasksCount ?? 0;

  String? token;
  Map<String, dynamic>? user;
  String? userId;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _taskList = [];
  List<Map<String, dynamic>> get taskList => _taskList;

  Future<void> loadUserDataAndFetchTasks() async {
    final prefs = SharedPref();
    token = await prefs.read(SharedPrefConstant().kAuthToken);
    user = await prefs.read(SharedPrefConstant().kUserData);
    userId = user?['id']?.toString();

    debugPrint("👤 Loaded User ID: $userId");
    debugPrint("🔐 Loaded Token: $token");

    await fetchTasksCount(userId: userId);
  }

  Future<void> fetchTasksCount({
    String? userId,
    String? taskId,
    String? assignedUser,
    String? fromDate,
    String? toDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      Map<String, String> queryParams = {};

      // Logged-in user ID
      if (userId != null && userId.trim().isNotEmpty) {
        queryParams['user_id'] = userId;
      }

      // Selected user dropdown as assign_to
      if (assignedUser != null && assignedUser.trim().isNotEmpty) {
        queryParams['assign_to'] = assignedUser;
      }

      // Task ID filter (optional)
      if (taskId != null) {
        queryParams['task_id'] = taskId;
      }

      // From date filter
      if (fromDate != null && fromDate.trim().isNotEmpty) {
        queryParams['from_date'] = fromDate;
      }

      // To date filter
      if (toDate != null && toDate.trim().isNotEmpty) {
        queryParams['to_date'] = toDate;
      }

      debugPrint("🔍 Fetching tasks count with params: $queryParams");

      final response = await ApiService.get(
        ApiConstants.getTaskCount,
        queryParams: queryParams,
      );

      debugPrint("📦 Task Count Response: $response");

      if (response['status'] == 'success' && response['data'] != null) {
        taskSummary = TaskSummaryCount.fromJson(response['data']);
      } else {
        taskSummary = null;
      }
    } catch (e) {
      debugPrint("❌ Error fetching task count: $e");
      taskSummary = null;
    } finally {
      _isLoading = false;
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
        debugPrint('✅ User List Loaded (${userList.length} users)');
        return userList;
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching user list: $e');
      rethrow;
    }
  }

  Future<void> fetchTaskList({String? assignTo}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final effectiveAssignTo = assignTo ?? userId;

      // 🔍 debugPrint parameters before calling API
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📤 API Call: Fetch Task List");
      debugPrint("🔹 Assign To User ID : $effectiveAssignTo");
      debugPrint("🔹 Base URL          : ${ApiConstants.getTasksByAssignee}");
      final apiUrl = '${ApiConstants.getTasksByAssignee}/$effectiveAssignTo';
      debugPrint("🌐 Final URL         : $apiUrl");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      // 📡 API Call
      final response = await ApiService.get(
        ApiConstants.getTasksByAssignee,
        queryParams: {"assign_to": effectiveAssignTo.toString()},
      );


      // 📥 Print the full raw response
      debugPrint("📦 Raw Response: $response");

      // ✅ Parse and print task list
      if (response != null && response['tasks'] != null) {
        _taskList = List<Map<String, dynamic>>.from(response['tasks']);
        debugPrint("✅ Task List Loaded: ${_taskList.length} tasks");
        for (var task in _taskList) {
          debugPrint("   - ${task['task_name']} (ID: ${task['id']})");
        }
      } else {
        _taskList = [];
        debugPrint("⚠️ No tasks data received or 'tasks' key missing");
      }
    } catch (e) {
      debugPrint('❌ Error fetching task list: $e');
      _taskList = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}