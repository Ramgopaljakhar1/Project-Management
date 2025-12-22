import 'package:flutter/cupertino.dart';
import '../../services/api_service.dart';

import '../../services/constants/api_constants.dart';
import '../../utils/shared_pref_constants.dart';
import '../../utils/shared_preference.dart';

class OverDueController extends ChangeNotifier {
  List<Map<String, dynamic>> overDue = [];
  bool isLoading = true;



  Future<void> fetchOverdueTasks(
      {
        required String userId,
        String? taskId,
        String? assignTo,
        String? fromDate,
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
        ApiConstants.overDueTaskList,
        queryParams: queryParams,
      );

      if (response != null && response['data'] != null) {
        overDue = List<Map<String, dynamic>>.from(response['data']);
      } else {
        debugPrint('⚠️ No data found in response.');
        overDue = []; // Set to empty if no data
      }
    } catch (e) {
      debugPrint("❌ Error fetching fav tasks: $e");
      overDue = []; // Reset on error
    }

    isLoading = false; // ✅ Stop loading after everything
    notifyListeners();
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
}
