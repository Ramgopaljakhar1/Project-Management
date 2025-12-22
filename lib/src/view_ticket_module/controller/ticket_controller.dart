import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/constants/api_constants.dart';

class TicketController extends ChangeNotifier {
  bool isLoading = false;
  List<Map<String, dynamic>> _tasks = []; // ✅ list instead of single map
  String? error;

  List<Map<String, dynamic>> get tasks => _tasks;

  Future<void> fetchTaskDetailById(String ticketId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    debugPrint("📌 Fetching Task Detail for Ticket ID: $ticketId");

    try {
      final response = await ApiService.get('${ApiConstants.ticketIDDetails}${ticketId}/');

      if (response != null) {
        // ✅ Check if response is a list or single object
        if (response is List) {
          _tasks = List<Map<String, dynamic>>.from(response);
        } else if (response is Map<String, dynamic>) {
          _tasks = [response];
        }
        debugPrint('✅ Task details fetched successfully');
      //  debugPrint("📦 API Response (_tasks)----: ${jsonEncode(_tasks)}");
      } else {
        error = 'Task not found';
        _tasks = [];
        debugPrint('❌ Task not found');
      }
    } catch (e) {
      error = e.toString();
      _tasks = [];
      debugPrint('❌ Error fetching task details: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
