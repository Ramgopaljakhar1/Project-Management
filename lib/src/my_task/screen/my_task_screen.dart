import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:project_management/src/common_widgets/app_state_screen.dart';
import 'package:project_management/src/my_task/contrroller/my_task_controller.dart';
import 'package:project_management/src/utils/img.dart';
import 'package:provider/provider.dart';
import '../../common_widgets/appbar.dart';
import '../../common_widgets/common_shimmer_loader.dart';
import '../../common_widgets/searching_field.dart';
import '../../common_widgets/task_card.dart';
import '../../utils/colors.dart';
import '../../utils/no_internet_connectivity.dart';
import '../../utils/shared_pref_constants.dart';
import '../../utils/shared_preference.dart';
import '../../view_my_task/screen/view_my_task_screen.dart';

class MyTaskScreen extends StatefulWidget {
  final String? userId;
  final String? assignedUserId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? taskId;
  const MyTaskScreen({super.key, this.userId, this.fromDate, this.toDate, this.taskId, this.assignedUserId});

  @override
  State<MyTaskScreen> createState() => _MyTaskScreenState();
}

class _MyTaskScreenState extends State<MyTaskScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String? _userId;
  dynamic user;
  bool isTimedOut = false;
  Timer? _timeoutTimer;
  final Connectivity _connectivity = Connectivity();
  bool _isNetworkAvailable = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool isLoading = false;

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
    final userData = await prefs.read(SharedPrefConstant().kUserData);

    if (mounted) {
      setState(() {
        user = userData;
        _userId = userData?['id']?.toString();
      });

      debugPrint("👤 Loaded User ID: $_userId");

      if (_userId != null) {
        // ⏳ Start timeout countdown
        _timeoutTimer = Timer(const Duration(seconds: 20), () {
          if (mounted &&
              Provider.of<MyTaskController>(context, listen: false).isLoading) {
            setState(() {
              isTimedOut = true;
            });
          }
        });
        Provider.of<MyTaskController>(
          context,
          listen: false,
        ).fetchMyTasks(
          userId: _userId!,
          taskId: widget.taskId,
          assignedUser: widget.assignedUserId,
          fromDate: widget.fromDate?.toIso8601String().split('T')[0], // Format date
          toDate: widget.toDate?.toIso8601String().split('T')[0],
        ).then((_) {
          if (_timeoutTimer?.isActive ?? false) {
            _timeoutTimer?.cancel();
          }
        });
      } else {
        debugPrint("❌ User ID is null!");
      }
    }
  }

  void updateSearch(String query) {
    setState(() {
      searchQuery = query.trim().toLowerCase();
    });
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
    _timeoutTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
  // String getTaskStatus(Map<String, dynamic> task) {
  //   try {
  //     // Parse dates safely
  //     DateTime? estEnd = task['est_end_date'] != null && task['est_end_date'].toString().isNotEmpty
  //         ? DateTime.parse(task['est_end_date'])
  //         : null;
  //
  //     DateTime? actualStart = task['actual_est_start_date'] != null && task['actual_est_start_date'].toString().isNotEmpty
  //         ? DateTime.parse(task['actual_est_start_date'])
  //         : null;
  //
  //     DateTime? actualEnd = task['actual_est_end_date'] != null && task['actual_est_end_date'].toString().isNotEmpty
  //         ? DateTime.parse(task['actual_est_end_date'])
  //         : null;
  //
  //     DateTime today = DateTime.now();
  //
  //     // ✅ Rule 1: Completed
  //     if (actualStart != null && actualEnd != null) {
  //       if (estEnd != null && actualEnd.isAfter(estEnd)) {
  //         return "Delayed"; // Finished late
  //       }
  //       return "Completed"; // Finished on or before planned end
  //     }
  //
  //     // ✅ Rule 2: Overdue
  //     if (actualEnd == null && estEnd != null && today.isAfter(estEnd)) {
  //       return "Overdue";
  //     }
  //
  //     return "In Progress"; // Default for ongoing tasks
  //
  //   } catch (e) {
  //     debugPrint("Error calculating task status: $e");
  //     return "Unknown";
  //   }
  // }
  String getTaskStatus(Map<String, dynamic> task) {
    try {
      // Parse dates safely
      DateTime? estEnd = task['est_end_date'] != null && task['est_end_date'].toString().isNotEmpty
          ? DateTime.parse(task['est_end_date'])
          : null;

      DateTime? actualStart = task['actual_est_start_date'] != null && task['actual_est_start_date'].toString().isNotEmpty
          ? DateTime.parse(task['actual_est_start_date'])
          : null;

      DateTime? actualEnd = task['actual_est_end_date'] != null && task['actual_est_end_date'].toString().isNotEmpty
          ? DateTime.parse(task['actual_est_end_date'])
          : null;

      DateTime today = DateTime.now();
      DateTime todayDateOnly = DateTime(today.year, today.month, today.day);

      // ✅ Rule 1: Completed or Delayed
      if (actualStart != null && actualEnd != null) {
        if (estEnd != null && actualEnd.isAfter(estEnd)) {
          return "Delayed"; // Finished late
        }
        return "Completed"; // Finished on or before planned end
      }
      // ✅ Rule 2: Assigned date is today → No status
      if (estEnd != null) {
        DateTime estEndDateOnly = DateTime(estEnd.year, estEnd.month, estEnd.day);
        if (estEndDateOnly.isAtSameMomentAs(todayDateOnly)) {
          return ""; // No status
        }
      }
      // ✅ Rule 3: Overdue (planned end date passed but not completed yet)
      if (actualEnd == null && estEnd != null && today.isAfter(estEnd)) {
        return "Overdue";
      }
      // ✅ Default
      return "In Progress";
    } catch (e) {
      debugPrint("Error calculating task status: $e");
      return "Unknown";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyTaskController>(
      builder: (context, controller, child) {
        // final filteredTasks = controller.myTaskListData.where((task) {
        //   final name = task['task_name']?.toString().toLowerCase() ?? '';
        //   final projectName = task['project_name']?.toString().toLowerCase() ?? '';
        //   final status = getTaskStatus(task).toLowerCase();
        //   final id = task['id']?.toString().toLowerCase() ?? '';
        //   final query = searchQuery.toLowerCase();
        //   if (query.isEmpty) return true;
        //   // ✅ Status keyword search
        //   if ((query == 'overdue' && status == 'overdue') ||
        //       (query == 'completed' && status == 'completed') ||
        //       (query == 'delayed' && status == 'delayed')) {
        //     return true;
        //   }
        //   // ✅ Search by task name, project name or ID
        //   if (name.contains(query) || projectName.contains(query) || id.contains(query)) {
        //     return true;
        //   }
        //
        //   return false;
        // }).cast<Map<String, dynamic>>().toList();

        final filteredTasks = controller.myTaskListData.where((task) {
          final name = task['task_name']?.toString().toLowerCase() ?? '';
          final projectName = task['project_name']?.toString().toLowerCase() ?? '';
          final id = task['id']?.toString().toLowerCase() ?? '';
          final query = searchQuery.toLowerCase();

          final taskStatus = getTaskStatus(task).toLowerCase();

          if (query.isEmpty) return true;

          // Match by task name, project name, ID, or status substring
          if (name.contains(query) ||
              projectName.contains(query) ||
              id.contains(query) ||
              taskStatus.contains(query)) {
            return true;
          }

          return false;
        }).cast<Map<String, dynamic>>().toList();

        // ✅ Yaha sort karo ID ke basis par (descending = newest on top)
        filteredTasks.sort((a, b) {
          int idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
          int idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
          return idB.compareTo(idA); // Newest first
        });
        return _isNetworkAvailable
            ? Scaffold(
                      appBar: customAppBar(context, title: 'My Tasks', showBack: true,showLogo: false),
                      body: controller.isLoading
              ? isTimedOut
              ? AppStateScreen(
            showAppBar: false,
            imagePath: AppImages.dataNotFound,
            title: 'Data Not Found !',
            subtitle1: 'We are unable to find the data that',
            subtitle2: 'you are looking for.',
            buttonText: 'Retry',
            onButtonPressed: () {
              setState(() {
                isTimedOut = false;
              });
              _loadUserData();
            },
                      )
              : Center(child: buildShimmerLoader())
              : Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12.0, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔍 Search Field
                searchingField(
                  onPress: () {
                    searchController.clear();
                    updateSearch('');
                  },
                  fillColor: AppColors.white,
                  searchController: searchController,
                  onChanged: updateSearch,
                ),
                const SizedBox(height: 11),

                /// 📋 Task List
                Expanded(
                  child: filteredTasks.isEmpty
                      ? AppStateScreen(
                    showAppBar: false,
                    imagePath: AppImages.dataNotFound,
                    title: 'Data Not Found !',
                    subtitle1: 'We are unable to find the data that',
                    subtitle2: 'you are looking for.',
                    buttonText: 'Retry',
                    onButtonPressed: () {
                      setState(() {
                        isTimedOut = false;
                      });
                      _loadUserData();
                    },
                  )
                      : ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      final status = getTaskStatus(task);

                      final String taskName =
                          task['task_name']?.toString() ??
                              'Unnamed Task';
                      final String? priorityRaw = task[
                      'priority_lookupdet_desc']
                          ?.toString();
                      final String? priority =
                      (priorityRaw != null &&
                          priorityRaw.trim().isNotEmpty)
                          ? priorityRaw
                          : null;

                      final String assignedDateStr =
                          task['assign_date']?.toString() ?? '';
                      DateTime assignedDate;
                      try {
                        assignedDate =
                            DateTime.parse(assignedDateStr);
                      } catch (e) {
                        assignedDate = DateTime.now();
                      }

                      return taskCard(
                        taskStatus: status,
                        taskStatusType: status,
                        showTaskStatus: true,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 1, vertical: 11),
                        showBell: false,
                        priority: priority,
                        taskName: taskName,
                        showFavourite: false,
                        assignedDate: assignedDate,
                        onEyeTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ViewMyTaskScreen(
                                    taskData: task,
                                    source: 'Assign',
                                  ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
                      ),
                    )
            : InternetIssue(
          onRetryPressed: () async {
            final result = await _connectivity.checkConnectivity();
            _updateConnectionStatus(result);
          },
          showAppBar: false,
        );
      },
    );
  }

}
