import 'package:flutter/cupertino.dart';
import 'package:project_management/src/services/api_service.dart';
import '../../services/constants/api_constants.dart';

class MyTaskController extends ChangeNotifier{
  List<dynamic> myTaskListData = [];
  bool isLoading = false;
  /// My Tasks
  Future<void> fetchMyTasks({
    required String userId,
    String? taskId,
    String? assignedUser,
    String? fromDate,
    String? toDate,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      //Map<String, String> queryParams = {'user_id': userId.toString()};
      Map<String, String> queryParams = {};
      if (assignedUser != null && assignedUser.trim().isNotEmpty) {
        // 🟢 Case 1: Dashboard से आए → assigned_user भेजो
        queryParams['assigned_user'] = assignedUser;
      } else {
        // 🟢 Case 2: Direct login user → user_id भेजो
        queryParams['user_id'] = userId.toString();
      }
      // Add filters only if provided
      if (taskId != null && taskId.trim().isNotEmpty) {
        queryParams['task_id'] = taskId;
      }
      if (assignedUser != null && assignedUser.trim().isNotEmpty) {
        queryParams['assigned_user'] = assignedUser;
      }
      if (fromDate != null && fromDate.trim().isNotEmpty) {
        queryParams['from_date'] = fromDate;
      }
      if (toDate != null && toDate.trim().isNotEmpty) {
        queryParams['to_date'] = toDate;
      }
      final response = await ApiService.get(
        ApiConstants.myTaskList,
        queryParams: queryParams,
      );

      // ✅ Validate and extract list from "data"
      if (response is Map<String, dynamic> && response['data'] is List) {
        myTaskListData = response['data'];
      } else {
        myTaskListData = [];
        debugPrint('⚠️ Unexpected response format: $response');
      }

      debugPrint('🌐 My Task API Response: $myTaskListData');
      for (var task in myTaskListData) {
        debugPrint('🔸 Task ID: ${task['id']}, Name: ${task['task_name']}');
      }

    } catch (e) {
      debugPrint('❌ My Task API Error: $e');
      myTaskListData = [];
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

}