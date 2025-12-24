import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:project_management/src/completed_on_time_tasks_module/screen/task_completed_screen.dart';
import 'package:project_management/src/view_my_task/screen/view_my_task_screen.dart';
import '../common_widgets/custom_snackbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:project_management/src/utils/colors.dart';
import 'package:provider/provider.dart';
import '../common_widgets/app_state_screen.dart';
import '../common_widgets/appbar.dart';
import '../utils/no_internet_connectivity.dart';
import '../utils/shared_pref_constants.dart';
import '../utils/shared_preference.dart';
import 'controller/notification_controller.dart';



class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}
class _NotificationsState extends State<Notifications> {
  String? token;
  dynamic user;
  String? _userId;
  final Connectivity _connectivity = Connectivity();
  bool _isNetworkAvailable = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }
  Future<void> _loadUserData() async {
    final prefs = SharedPref();
    final tokenVal = await prefs.read(SharedPrefConstant().kAuthToken);
    final userData = await prefs.read(SharedPrefConstant().kUserData);
    if (mounted) {
      setState(() {
        token = tokenVal;
        user = userData;
        _userId = userData?['id']?.toString();
        print('user id ++: $_userId');
      });

      if (_userId != null) {
        _fetchNotifications();
      }
    }
  }

  void _fetchNotifications() {
    if (_userId != null) {
      final controller =
      Provider.of<NotificationController>(context, listen: false);
      controller.fetchNotifications(userId: _userId!);
      final notificationUserList = controller.notifications;
      print('notification list :  $notificationUserList');
    }
  }

  Future<void> _initConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }

  // Update connection status handler
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final isConnected = results.any(
          (result) =>
      result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi,
    );

    setState(() {
      _isNetworkAvailable = isConnected;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isNetworkAvailable
        ? Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: customAppBar(context, title: 'Notifications', showBack: true, showLogo: false),
      body: Consumer<NotificationController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = controller.notifications;
          if (notifications.isEmpty) {
            return AppStateScreen(
              showAppBar: false,
              imagePath:'assets/images/DataNotFound.jpg',
              title: 'No Notifications Found!',
              subtitle1: 'You don\'t have any notifications',
              subtitle2: 'at the moment.',
              buttonText: 'Retry',
              onButtonPressed: () {
                _fetchNotifications();
              },
            );
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final message = notif['message'] ?? '';
              final createdDate = notif['created_date'] ?? '';
              DateTime? parsedDate = DateTime.tryParse(createdDate);
              String formattedDate = parsedDate != null
                  ? DateFormat('dd MMM, hh:mm a').format(parsedDate.toLocal())
                  : createdDate;

              return Dismissible(
                key: Key(notif['id'].toString()),
                direction: DismissDirection.startToEnd,
                background: Container(
                  color: Colors.red,
                  padding: const EdgeInsets.only(left: 20),
                  alignment: Alignment.centerLeft,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  final controller = Provider.of<NotificationController>(context, listen: false);
                  final result = await controller.deleteNotification(_userId!, notif['id'].toString());

                  if (result["success"] != true) {
                    CustomSnackBar.errorSnackBar(context, result["message"]);
                    controller.notifications.insert(index, notif);
                    controller.notifyListeners();
                  }
                },
                child: GestureDetector(
                  onTap: () {
                    _handleNotificationTap(notif, context);
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(-3, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: GoogleFonts.nunitoSans(
                              fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.darkGray),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            formattedDate,
                            style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.gray),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    ) : InternetIssue(
      onRetryPressed: () async {
        final result = await _connectivity.checkConnectivity();
        _updateConnectionStatus(result);
      },
      showAppBar: false,
    );
  }

  /// Handle notification tap based on user role
  void _handleNotificationTap(Map<String, dynamic> notif, BuildContext context) {
    print('Notification clicked: ${notif['id']}');

    // Get task ID from notification
    final taskId = notif['task_id'];
    print('Task ID: $taskId');

    if (taskId == null) {
      // Show alert if task ID is missing
      _showTaskIdNotFoundDialog(context);
      return;
    }

    // Get current user ID
    final currentUserId = _userId.toString();
    final message = notif['message'] ?? '';

    print('Current User ID: $currentUserId');
    print('Notification Message: $message');

    // Parse notification message to determine user role
    if (_isTaggedUser(message)) {
      print('✅ User is TAGGED - Navigating to TaskCompletedScreen');
      _navigateToTaskCompletedScreen(context, taskId);
    } else if (_isAssignedOrAssignerUser(message)) {
      print('✅ User is ASSIGNEE or ASSIGNER - Navigating to ViewMyTaskScreen');
      _navigateToViewMyTaskScreen(context, taskId,notif);
    } else {
      print('⚠️ Could not determine user role - Defaulting to TaskCompletedScreen');
      _navigateToTaskCompletedScreen(context, taskId);
    }
  }

  /// Check if user is tagged in the notification
  bool _isTaggedUser(String message) {
    return message.toLowerCase().contains('tagged you') ||
        message.toLowerCase().contains('mentioned you') ||
        message.toLowerCase().contains('notified you');
  }

  /// Check if user is assignee or assigner
  bool _isAssignedOrAssignerUser(String message) {
    return message.toLowerCase().contains('assigned you') ||
        message.toLowerCase().contains('assigned to you') ||
        message.toLowerCase().contains('your task') ||
        message.toLowerCase().contains('assigned by');
  }

  /// Navigate to TaskCompletedScreen
  void _navigateToTaskCompletedScreen(BuildContext context, dynamic taskId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskCompletedScreen(
          taskData: {
            'id': taskId,
          },
          previousScreenTitle: 'Notification Details',
        ),
      ),
    );
  }

  /// Navigate to ViewMyTaskScreen
  void _navigateToViewMyTaskScreen(BuildContext context, dynamic taskId,Map<String, dynamic> notif) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewMyTaskScreen(
          taskData: {
            'id': taskId,
            'assign_to_remark': notif['assign_to_remark'] ?? '',
          },
          source: 'notifications',
          showEditButton: true,
        ),
      ),
    );
  }

  /// Enhanced message parsing for different notification types
  Map<String, dynamic> _parseNotificationMessage(String message) {
    final Map<String, dynamic> result = {
      'isTagged': false,
      'isAssigned': false,
      'isTaskCompleted': false,
      'isTaskAssigned': false,
    };

    final lowerMessage = message.toLowerCase();

    // Check for different notification patterns
    if (lowerMessage.contains('tagged you') ||
        lowerMessage.contains('mentioned you')) {
      result['isTagged'] = true;
    } else if (lowerMessage.contains('assigned you') ||
        lowerMessage.contains('assigned to you')) {
      result['isAssigned'] = true;
    } else if (lowerMessage.contains('your task') &&
        lowerMessage.contains('has been completed')) {
      result['isTaskCompleted'] = true;
    } else if (lowerMessage.contains('assigned') &&
        lowerMessage.contains('to the task')) {
      result['isTaskAssigned'] = true;
    }

    return result;
  }

  /// Complete notification handler with all cases
  void _handleCompleteNotificationTap(Map<String, dynamic> notif, BuildContext context) {
    final taskId = notif['task_id'];
    final message = notif['message'] ?? '';

    if (taskId == null) {
      _showTaskIdNotFoundDialog(context);
      return;
    }

    final parsedMessage = _parseNotificationMessage(message);

    // Decision tree for navigation
    if (parsedMessage['isTagged']) {
      // User is tagged/mentioned
      print('🔔 Tagged User - Going to TaskCompletedScreen');
      _navigateToTaskCompletedScreen(context, taskId);
    } else if (parsedMessage['isAssigned'] ||
        parsedMessage['isTaskAssigned'] ||
        parsedMessage['isTaskCompleted']) {
      // User is assignee, assigner, or task owner
      print('📋 Assignee/Assigner - Going to ViewMyTaskScreen');
      _navigateToViewMyTaskScreen(context, taskId,notif);
    } else {
      // Default case - check if we have additional data
      if (notif.containsKey('user_role')) {
        // Use explicit user_role from API if available
        final userRole = notif['user_role'];
        if (userRole == 'tagged' || userRole == 'mentioned') {
          _navigateToTaskCompletedScreen(context, taskId);
        } else if (userRole == 'assignee' || userRole == 'assigner') {
          _navigateToViewMyTaskScreen(context, taskId,notif);
        } else {
          _navigateToTaskCompletedScreen(context, taskId); // Default
        }
      } else {
        _navigateToTaskCompletedScreen(context, taskId); // Default fallback
      }
    }
  }

  void _showTaskIdNotFoundDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Task ID Not Found"),
        content: const Text("Task ID is not available for this notification."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Alternative approach - Using API data if available
  void _handleNotificationTapWithApiData(Map<String, dynamic> notif, BuildContext context) {
    print('Notification clicked: ${notif['id']}');

    final taskId = notif['task_id'];
    final currentUserId = _userId.toString();

    if (taskId == null) {
      _showTaskIdNotFoundDialog(context);
      return;
    }

    // Get user role information from notification data (if available)
    final assignedById = notif['assigned_by_id']?.toString();
    final assignedToId = notif['assigned_to_id']?.toString();
    final taggedUserIds = notif['tagged_user_ids'] ?? [];

    print('Assigned By ID: $assignedById');
    print('Assigned To ID: $assignedToId');
    print('Tagged User IDs: $taggedUserIds');
    print('Current User ID: $currentUserId');

    // Convert taggedUserIds to list if it's a string
    List<String> taggedIds = [];
    if (taggedUserIds is String && taggedUserIds.isNotEmpty) {
      taggedIds = taggedUserIds.split(',').map((id) => id.trim()).toList();
    } else if (taggedUserIds is List) {
      taggedIds = taggedUserIds.map((id) => id.toString()).toList();
    }

    // Determine navigation based on user role
    if (taggedIds.contains(currentUserId)) {
      // User is tagged (mentioned) in the task
      print('✅ User is TAGGED - Navigating to TaskCompletedScreen');
      _navigateToTaskCompletedScreen(context, taskId);
    } else if (currentUserId == assignedById || currentUserId == assignedToId) {
      // User assigned the task OR user was assigned the task
      print('✅ User is ASSIGNER or ASSIGNEE - Navigating to ViewMyTaskScreen');
      _navigateToViewMyTaskScreen(context, taskId,notif);
    } else {
      // Fallback - use message parsing
      _handleNotificationTap(notif, context);
    }
  }
}