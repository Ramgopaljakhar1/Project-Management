
import 'package:flutter/material.dart';
import 'package:project_management/src/services/api_service.dart';
import '../../common_widgets/custom_snackbar.dart';
import '../../services/constants/api_constants.dart';

class AssignedToTeam extends ChangeNotifier{
  List<dynamic> teamTaskListData = [];
  bool isLoading = false;
  String? selectedUser;

  /// Team Tasks
  Future<void> fetchTeamTasks({
    required String userId,
    String? taskId,
    String? assignTo,
    String? fromDate,
    String? toDate,
  }) async {
    isLoading = true;
    notifyListeners();
//
    try {
      Map<String, String> queryParams = {
        'task_id': taskId ?? '',          // empty string if no task selected
        'user_id': userId,                // always logged-in user
        'assign_to': assignTo ?? '',      // empty string if no user selected
        'from_date': fromDate ?? '',      // empty string if null
        'to_date': toDate ?? '',          // empty string if null
      };
      // Always include user_id
     // Map<String, String> queryParams = {'user_id': userId.toString()};
     //  Map<String, String> queryParams = {};
     //
     //  if (assignTo != null && assignTo.trim().isNotEmpty) {
     //    // Assigned user is selected → send only assigned_user
     //    queryParams['assign_to'] = assignTo;
     //  } else {
     //    // Assigned user not selected → send only logged-in user
     //    queryParams['user_id'] = userId;
     //  }
     //  // Add filters only if provided
     //  if (taskId != null && taskId.trim().isNotEmpty) {
     //    queryParams['task_id'] = taskId;
     //  }
     //  if (assignTo != null && assignTo.trim().isNotEmpty) {
     //    queryParams['assign_to'] = assignTo;
     //  }
     //  if (fromDate != null && fromDate.trim().isNotEmpty) {
     //    queryParams['from_date'] = fromDate;
     //  }
     //  if (toDate != null && toDate.trim().isNotEmpty) {
     //    queryParams['to_date'] = toDate;
     //  }
      final response = await ApiService.get(
        ApiConstants.teamTaskList,
        queryParams: queryParams,
      );
      debugPrint('🌐 Team Task API URL: ${ApiConstants.teamTaskList}');
      debugPrint('🔍 Filter Parameters: $queryParams');
      debugPrint('📦 Response: $response');
      debugPrint('🌐 Assigned Task API Response: $response');
      debugPrint('🔍 Filter Parameters: task_id=$taskId, assign_to=$assignTo, from_date=$fromDate, to_date=$toDate');
      debugPrint("📦 API Response---: $response");
      // ✅ Check and extract 'data' from the response map
      if (response is Map<String, dynamic> && response['data'] is List) {
        teamTaskListData = response['data'];
      } else {
        teamTaskListData = [];
        debugPrint('⚠️ Unexpected response format: $response');
      }

      debugPrint('🌐 Team Task API Response: $teamTaskListData');
      for (var task in teamTaskListData) {
        debugPrint('🔸 Task ID: ${task['id']}, Name: ${task['task_name']}');
      }

    } catch (e) {
      debugPrint('❌ Team Task API Error: $e');
     // CustomSnackBar.errorSnackBar(e.toString());
      teamTaskListData = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> fetchProjectList() async {
    try {
      final response = await ApiService.get(
        ApiConstants.ProjectList,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response != null && response['lookup'] != null) {
        final lookupDetails = response['lookup']['lookup_det_id'] as List;
        return lookupDetails
            .where((item) => item['status'] == 'Active' || item['status'] == 'active')
            .map<Map<String, dynamic>>((item) => {
          'id': item['lookup_det_id'].toString(),
          'name': item['lookup_det_desc_en'],
        })
            .toList();

      }
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching project list: $e');
      rethrow;
    }
  }
  Future<void> fetchFilteredTeamTasks({
    required String userId,
    String? taskId,
    String? projectId,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      Map<String, String> queryParams = {'user_id': userId};
      if (projectId != null && projectId.isNotEmpty) {
        queryParams['project_name'] = projectId; // API expects 'project_name' for project filter
      }
      // Add filters only if provided
      if (taskId != null && taskId.isNotEmpty) {
        queryParams['id'] = taskId; // API expects 'id' for task filter
      }
      final response = await ApiService.get(
        ApiConstants.teamTaskList,
        queryParams: queryParams,
      );

      debugPrint("🌐 Filter API URL: ${ApiConstants.teamTaskList}");
      debugPrint("📌 Filter Params: $queryParams");
      debugPrint("📦 Response: $response");

      if (response is Map<String, dynamic> && response['data'] is List) {
        teamTaskListData = (response['data'] as List).cast<Map<String, dynamic>>();
        debugPrint("✅ Filtered ${teamTaskListData.length} tasks");
      } else {
        teamTaskListData = [];
        debugPrint("⚠️ No data found or unexpected response format");
      }

    } catch (e) {
      debugPrint("❌ Filter API Error: $e");
      teamTaskListData = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  Future<String> sendReminder({
    required int taskId,
    required int notifyTo,
    required int createdBy,
  }) async {
    final body = {
      "task_id": taskId,
      "notify_to": notifyTo,
      "created_by": createdBy,
    };

    try {
      final response = await ApiService.post(
         ApiConstants.createReminder,body,headers:{}
      );

      debugPrint("✅ Reminder API Response: $response");

      // The API returns a Map with a 'message'
      if (response.containsKey('message')) {
        return response['message'].toString();
      }

      return "Reminder sent successfully!";
    } catch (e) {
      debugPrint("❌ Reminder API Error: $e");
      return "Failed to send reminder: $e";
    }
  }

}