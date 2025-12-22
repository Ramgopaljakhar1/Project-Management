// controllers/add_task_favourite_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:project_management/src/utils/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/constants/api_constants.dart';
import '../../utils/shared_pref_constants.dart';
import '../../utils/shared_preference.dart';
class AddTaskFavouriteController extends ChangeNotifier {
  List<Map<String, dynamic>> favouriteTasks = [];

  Future<void> fetchFavouriteTasks() async {
    try {
      final prefs = SharedPref();
      final userData = await prefs.read(SharedPrefConstant().kUserData);

      if (userData == null || userData is! Map<String, dynamic>) {
        debugPrint("❌ User data not found or not in correct format.");
        return;
      }

      final userId = userData['id'];

      if (userId == null) {
        debugPrint("❌ User ID is null.");
        return;
      }

      debugPrint('✅ User ID@@@: $userId');

      final response = await ApiService.get(
        ApiConstants.getFavTaskList,
        queryParams: {'user_id': userId.toString()},
      );

      if (response != null && response['data'] != null) {
        favouriteTasks = List<Map<String, dynamic>>.from(response['data']);
        notifyListeners();
      } else {
        debugPrint('⚠️ No data found in response.');
      }
    } catch (e) {
      debugPrint("❌ Error fetching fav tasks: $e");
    }
  }
  Future<void> toggleFavouriteStatus({
    required BuildContext context,
    required Map<String, dynamic> task,
    required String token,
    required String userId, // pass userId explicitly
  }) async {
    final taskId = task['id'];
    if (taskId == null) {
      debugPrint("❌ Task ID is null, cannot proceed");
      return;
    }

    // Log task details
    debugPrint("🔍 Removing Favourite Task Details:");
    debugPrint("Task ID: ${task['id']}");
    debugPrint("Task Name: ${task['task_name']}");
    debugPrint("Created By: ${task['created_by']}");
    debugPrint("Assign To: ${task['assign_to']}");

    try {
      final body = {
        'task_id': taskId,
        'favorite_flag': 'N', // removing favourite
        'user_id': userId,
      };

      // Log API request body
      debugPrint("📤 API Request Body: ${jsonEncode(body)}");

      final response = await ApiService.post(
        ApiConstants.addTask, // Ensure correct endpoint
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Log API response
      debugPrint("📥 API Response for Task ID $taskId: ${jsonEncode(response)}");

      final msg = response?['message']?.toString() ?? "No message returned";

      if (msg.toLowerCase().contains('success')) {
        favouriteTasks.removeWhere((element) => element['id'] == taskId);
        notifyListeners();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor:  AppColors.appBar,content: Text("Task removed from favourites")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint("❌ Exception while removing favourite for Task ID $taskId: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error removing favourite"), backgroundColor: Colors.red),
      );
    }
  }


  void removeFromFavourites(Map<String, dynamic> task) {
    favouriteTasks.remove(task);
    notifyListeners();
  }
}


