import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_management/src/services/api_service.dart';
import '../../../services/constants/api_constants.dart';
import '../../../utils/shared_pref_constants.dart';
import '../../../utils/shared_preference.dart';
import '../../delayed_task_model.dart';

class GetDelayedController extends ChangeNotifier {
  String? token;
  Map<String, dynamic>? user;
  String? userId;


  List<DelayedTaskModel> _delayedTasks = [];
  List<DelayedTaskModel> get delayedTasks => _delayedTasks;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

//   Future<void> loadUserDataAndFetchDelayedTasks(
//   {
//     required String userId,
//     String? taskId,
//     String? assignedUser,
//     String? fromDate,
//     String? toDate,
// }
//       ) async {
//     final prefs = SharedPref();
//     token = await prefs.read(SharedPrefConstant().kAuthToken);
//     user = await prefs.read(SharedPrefConstant().kUserData);
//     userId = user?['id']?.toString();
//
//     debugPrint("👤 [DELAYED] Loaded User ID: $userId");
//     debugPrint("🔐 [DELAYED] Loaded Token: $token");
//
//     await fetchDelayedTasks();
//   }

  Future<void> fetchDelayedTasks(
      {
        required String userId,
        String? taskId,
        String? assignTo,
        String? fromDate,
        String? toDate,
      }
      ) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Always include user_id
     // Map<String, String> queryParams = {'user_id': userId.toString()};
     //  Map<String, String> queryParams = {};
     //  if (assignedUser != null && assignedUser.trim().isNotEmpty) {
     //    // 🟢 Case 1: Dashboard से आए → assigned_user भेजो
     //    queryParams['assigned_user'] = assignedUser;
     //  } else {
     //    // 🟢 Case 2: Direct login user → user_id भेजो
     //    queryParams['user_id'] = userId.toString();
     //  }
     //  // Add filters only if provided
     //  if (taskId != null && taskId.trim().isNotEmpty) {
     //    queryParams['task_id'] = taskId;
     //  }
     //  if (assignedUser != null && assignedUser.trim().isNotEmpty) {
     //    queryParams['assigned_user'] = assignedUser;
     //  }
     //  if (fromDate != null && fromDate.trim().isNotEmpty) {
     //    queryParams['from_date'] = fromDate;
     //  }
     //  if (toDate != null && toDate.trim().isNotEmpty) {
     //    queryParams['to_date'] = toDate;
     //  }
      Map<String, String> queryParams = {
        'task_id': taskId ?? '',          // empty string if no task selected
        'user_id': userId,                // always logged-in user
        'assign_to': assignTo ?? '',      // empty string if no user selected
        'from_date': fromDate ?? '',      // empty string if null
        'to_date': toDate ?? '',          // empty string if null
      };
      final response = await ApiService.get(
        ApiConstants.getDelayedTasks, // Make sure this key exists in ApiConstants
        queryParams: queryParams,
      );

      if (response['status'] == 'success') {
        final List data = response['data'];
        _delayedTasks = data.map((e) {
          final task = DelayedTaskModel.fromJson(e);
          debugPrint("🐢 [DELAYED] Task Name: ${task.taskName}");
          debugPrint("🐢 [DELAYED] Task ID: ${task.id}");
          return task;
        }).toList();
      } else {
        debugPrint("⚠️ Failed to fetch delayed tasks: ${response['message']}");
      }
    } catch (e) {
      debugPrint('❌ Exception in fetching delayed tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
