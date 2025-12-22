import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import '../../services/constants/api_constants.dart';

class NotificationController extends ChangeNotifier {
  List<dynamic> notifications = [];
  bool isLoading = false;

  Future<void> fetchNotifications({required String userId}) async {
    isLoading = true;
    notifyListeners();

    try {
      debugPrint("👤 Fetching notifications for userId: $userId");

      final url = "${ApiConstants.notification}$userId";
      debugPrint("🌐 GET URL: $url");

      final response = await ApiService.get(url);
      debugPrint("📦 Raw Response: $response");

      if (response is List) {
        notifications = response;
        debugPrint("✅ Loaded ${notifications.length} notifications");
      } else {
        notifications = [];
        debugPrint("⚠️ Unexpected response format — expected List");
      }
    } catch (e) {
      debugPrint("❌ Error fetching notifications: $e");
      notifications = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  Future<Map<String, dynamic>> deleteNotification(String userId, String notificationId) async {
    try {
      // Use relative endpoint only (without baseUrl) because ApiService adds it
      final endpoint = "${ApiConstants.deleteNotification}$userId/$notificationId/";
      debugPrint("🗑 Full POST endpoint: $endpoint");

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // 'Authorization': 'Bearer $token', // if your API requires auth
      };

      // POST request with empty body (if API doesn't need extra data)
      final response = await ApiService.post(endpoint, {}, headers: headers);

      // Parse JSON safely
      Map<String, dynamic> data = {};
      if (response is String) {
        data = jsonDecode(response);
      } else if (response is Map<String, dynamic>) {
        data = response;
      }

      if (data['message'] != null) {
        notifications.removeWhere((n) => n['id'].toString() == notificationId);
        notifyListeners();
        debugPrint("✅ Notification cleared: ${data['message']}");
        return {"success": true, "message": data['message']};
      } else {
        return {"success": false, "message": "Failed to clear notification"};
      }
    } catch (e) {
      debugPrint("❌ Error clearing notification: $e");
      return {"success": false, "message": e.toString()};
    }
  }
}
