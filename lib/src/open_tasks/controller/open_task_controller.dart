import 'package:flutter/cupertino.dart';
import 'package:project_management/src/services/api_service.dart';
import '../../services/constants/api_constants.dart';


class OpenTaskController extends ChangeNotifier{
  List<dynamic> openTaskList = [];
  bool isLoading = true;
  /// Fetch Open Tasks
  Future<void> fetchOpenTasks({
    required String userId,
    String? taskId,
    String? fromDate,
    String? assignTo,
    String? toDate,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      Map<String, String> queryParams = {
        'task_id': taskId ?? '',          // empty string if no task selected
        'user_id': userId,                // always logged-in user
        'assign_to': assignTo ?? '',      // empty string if no user selected
        'from_date': fromDate ?? '',      // empty string if null
        'to_date': toDate ?? '',          // empty string if null
      };

      final response = await ApiService.get(
        ApiConstants.openTaskList,
        queryParams: queryParams,
      );

      debugPrint('🌐 Open Task API Response: $response');


      if (response != null) {
        if (response is List) {
          // Direct list response
          openTaskList = response;
        } else if (response is Map<String, dynamic> && response['data'] is List) {
          // Wrapped response with data key
          openTaskList = response['data'];
        } else {
          openTaskList = [];
          debugPrint("⚠️ Unexpected API response format");
        }

        // Sort tasks by creation date (newest first)
        openTaskList.sort((a, b) {
          final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
          final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
          return bTime.compareTo(aTime); // Descending order
        });

        debugPrint('✅ Loaded ${openTaskList.length} tasks');
        notifyListeners();
      } else {
        openTaskList = [];
        debugPrint("⚠️ Null API response");
      }

      // Debug log each task
      for (var task in openTaskList) {
        debugPrint('🔹 Task ID: ${task['id']}, Name: ${task['task_name']}');
      }

    } catch (e) {
      debugPrint('❌ Open Task API Error: $e');
      openTaskList = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  void insertNewTaskAtTop(Map<String, dynamic> newTask) {
    openTaskList.insert(0, newTask);
   // notifyListeners();
  }

  void clearTask() {
    openTaskList.clear();
    //notifyListeners();
  }
}