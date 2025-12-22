import 'package:flutter/material.dart';
import '../../services/constants/api_constants.dart';
import '../../utils/shared_preference.dart';
import '../../utils/shared_pref_constants.dart';
import '../../services/api_service.dart';
import '../screen/completed_on_time_task.dart';
import '../task_model/model.dart';

class CompletedOnTimeController extends ChangeNotifier {
  String? token;
  Map<String, dynamic>? _task;
  Map<String, dynamic>? user;
  String? userId;
  List<CompletedOnTimeTaskModel> _completedTasks = [];
  List<CompletedOnTimeTaskModel> get completedTasks => _completedTasks;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? errorMessage;




  Future<void> loadUserDataAndFetchTasks(
      {
        String? taskId,
        String? assignedUser,
        String? fromDate,
        String? toDate,
      }

      ) async {
    final prefs = SharedPref();
    token = await prefs.read(SharedPrefConstant().kAuthToken);
    user = await prefs.read(SharedPrefConstant().kUserData);
    userId = user?['id']?.toString();

    debugPrint("👤 Loaded User ID: $userId");
    debugPrint("🔐 Loaded Token: $token");

    // await fetchCompletedOnTimeTasks(
    //   taskId: taskId,
    //   assignedUser: assignedUser,
    //   fromDate: fromDate,
    //   toDate: toDate,
    // );
  }
  Future<void> initializeAndFetchTask(String taskId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final pref = SharedPref();
      final userData = await pref.read(SharedPrefConstant().kUserData);
      userId = userData != null ? userData['id'] : null;

      print('user Id : --->>??: $userId');
      if (userId == null) {
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

  Future<void> fetchCompletedOnTimeTasks(
  {
    required String userId,
    String? taskId,
    String? assignTo,
    String? fromDate,
    String? toDate,
}
      ) async {

  //  final response = await ApiService.get(ApiConstants.completedOnTime, queryParams: {'user_id': userId ?? ''});
    _isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await loadUserDataAndFetchTasks();
      Map<String, String> queryParams = {
        'task_id': taskId ?? '',          // empty string if no task selected
        'user_id': userId,                // always logged-in user
        'assign_to': assignTo ?? '',      // empty string if no user selected
        'from_date': fromDate ?? '',      // empty string if null
        'to_date': toDate ?? '',          // empty string if null
      };
      // Map<String, String> queryParams = {};
      // if (assignedUser != null && assignedUser.trim().isNotEmpty) {
      //   // 🟢 Case 1: Dashboard से आए → assigned_user भेजो
      //   queryParams['assigned_user'] = assignedUser;
      // } else {
      //   // 🟢 Case 2: Direct login user → user_id भेजो
      //   queryParams['user_id'] = userId.toString();
      // }
      // // Add filters only if provided
      // if (taskId != null && taskId.trim().isNotEmpty) {
      //   queryParams['task_id'] = taskId;
      // }
      // if (assignedUser != null && assignedUser.trim().isNotEmpty) {
      //   queryParams['assigned_user'] = assignedUser;
      // }
      // if (fromDate != null && fromDate.trim().isNotEmpty) {
      //   queryParams['from_date'] = fromDate;
      // }
      // if (toDate != null && toDate.trim().isNotEmpty) {
      //   queryParams['to_date'] = toDate;
      // }
      debugPrint('🔍 Fetching with filters: $queryParams');

      final response = await ApiService.get(
        ApiConstants.completedOnTime,
        queryParams: queryParams,
      );

      if (response['status'] == 'success') {
        final List data = response['data'];
        _completedTasks = data.map((e) {
          final task = CompletedOnTimeTaskModel.fromJson(e);
          debugPrint("📦 Task taskName: ${task.taskName}");
          debugPrint("📦 Task id: ${task.id}");
          debugPrint("📦 Task taskDetail: ${task.taskDetail}");
          debugPrint("📦 Task assignToUser: ${task.assignToUser}");
          return task;
        }).toList();

      }
    } catch (e) {
      debugPrint('❌ Error fetching completed tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
