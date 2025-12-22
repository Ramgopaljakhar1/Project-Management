// DashboardDetails.dart (updated)
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:project_management/src/completed_on_time_tasks_module/screen/completed_on_time_task.dart';
import 'package:project_management/src/dashboard_module/controller/dashboard_details_controller.dart';
import 'package:project_management/src/my_task/screen/my_task_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../assigned_tasks/screen/assigned_tasks.dart';
import '../assigned_to_team_module/screen/assigned_to_team_screen.dart';
import '../common_widgets/appbar.dart';
import '../common_widgets/custom_dropdown.dart';
import '../deyaled_module/deyaled_screen.dart';
import '../open_tasks/screen/to_do_board.dart';
import '../overdue_module/overdue_screen.dart';
import '../task_module/controller/add_task_controller.dart';
import '../utils/img.dart';
import '../utils/colors.dart';
import '../utils/no_internet_connectivity.dart';
import '../utils/shared_pref_constants.dart';
import '../utils/shared_preference.dart';

class DashboardDetails extends StatefulWidget {
  const DashboardDetails({super.key});
  @override
  State<DashboardDetails> createState() => _DashboardDetailsState();
}

class _DashboardDetailsState extends State<DashboardDetails> {
  String? selectedProject;
  String? selectedUser;
  DateTime? fromDate;
  DateTime? toDate;
  int? selectedIndex;
  String? token;
  dynamic user;
  String? _userId;
  List<Map<String, dynamic>> userList = [];
  List<Map<String, dynamic>> filteredTaskList = [];
  String? _selectedUserId;
  final Connectivity _connectivity = Connectivity();
  bool _isNetworkAvailable = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool isLoading = false;
  DashboardDetailsController? dashboardDetailsController;

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    DateTime initialDate = DateTime.now();

    if (isFromDate) {
      initialDate = fromDate ?? DateTime.now();
    } else {
      initialDate = toDate ?? fromDate ?? DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate:
          isFromDate
              ? DateTime(2000)
              : fromDate ??
                  DateTime(2000), // To Date cannot be before From Date
      lastDate:
          isFromDate
              ? toDate ??
                  DateTime(2101) // From Date cannot be after To Date
              : DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
          // Automatically adjust toDate if it's before new fromDate
          if (toDate != null && toDate!.isBefore(fromDate!)) {
            toDate = fromDate;
          }
        } else {
          toDate = picked;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
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

  Future<void> _initializeData() async {
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    final dashboardController = Provider.of<DashboardDetailsController>(
      context,
      listen: false,
    );

    setState(() {
      isLoading = true;
    });

    try {
      userList = await dashboardController.fetchUserList();

      final prefs = SharedPref();
      token = await prefs.read(SharedPrefConstant().kAuthToken);
      user = await prefs.read(SharedPrefConstant().kUserData);

      if (mounted) {
        setState(() {
          token = token;
          user = user;
          _userId = user?['id']?.toString();
          // _selectedUserId = _userId; // Initialize with current user
        });
      }

      debugPrint("🔑 Token: $token");
      debugPrint("👤 Username: ${user?['username']}");
      debugPrint("🆔 Current User ID: $_userId");

      await dashboardController.loadUserDataAndFetchTasks();
      await dashboardController.fetchTasksCount(userId: _userId);
    } catch (e) {
      debugPrint("Error loading user data: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _applyFilters() async {
    if (fromDate != null && toDate != null && fromDate!.isAfter(toDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.appBar,
          content: Text('From Date cannot be after To Date'),
        ),
      );
      return;
    }

    if (fromDate != null && fromDate!.isBefore(DateTime(2000))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.appBar,
          content: Text('From Date is invalid'),
        ),
      );
      return;
    }

    if (toDate != null && toDate!.isBefore(DateTime(2000))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.appBar,
          content: Text('To Date is invalid'),
        ),
      );
      return;
    }

    final controller = Provider.of<DashboardDetailsController>(
      context,
      listen: false,
    );

    try {
      final assignedUserToUse = selectedUser != null ? _selectedUserId : null;

      await controller.fetchTasksCount(
        userId: _userId,
        assignedUser: _selectedUserId,
        taskId:
            selectedProject != null
                ? _getTaskIdFromName(selectedProject!)
                : null,
        fromDate: fromDate?.toIso8601String().split('T')[0],
        toDate: toDate?.toIso8601String().split('T')[0],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.appBar,
          content: Text('Filters applied successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.appBar,
          content: Text('Error applying filters: ${e.toString()}'),
        ),
      );
    }
  }

  String? _getTaskIdFromName(String taskName) {
    final task = filteredTaskList.firstWhere(
      (t) => t['task_name'] == taskName,
      orElse: () => {},
    );
    return task['id']?.toString();
  }

  Future<void> _onUserSelected(String? userName) async {
    final controller = Provider.of<DashboardDetailsController>(
      context,
      listen: false,
    );

    if (userName != null && userName.isNotEmpty) {
      final selectedUserData = userList.firstWhere(
        (u) =>
            u['user_name']?.toString().trim().toLowerCase() ==
            userName.trim().toLowerCase(),
        orElse: () => {},
      );
      final userId = selectedUserData['user_id']?.toString();

      setState(() {
        _selectedUserId = userId; // Only assigned_user ID
        selectedUser = userName;
      });

      // Fetch tasks assigned to this user
      await controller.fetchTaskList(assignTo: userId);
      setState(() {
        filteredTaskList = controller.taskList;
      });

      // Fetch tasks count with assigned_user only, NOT userId
      await controller.fetchTasksCount(
        userId: _userId, // logged-in user
        assignedUser: _selectedUserId, // selected user
      );
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskController = Provider.of<AddTaskController>(context);
    final dashboardController = Provider.of<DashboardDetailsController>(
      context,
    );
    final summary = dashboardController.taskSummary;

    final List<Map<String, String>> data =
        summary == null
            ? []
            : [
              {
                'icon': AppImages.toDoOpenCount,
                'count': '${summary.openTasksCount}/${summary.totalTaskCount}',
                'label': 'Open',
              },
              {
                'icon': AppImages.assigned,
                'count':
                    '${summary.assignedTasksCount}/${summary.totalTaskCount}',
                'label': 'Assigned',
              },
              {
                'icon': AppImages.completedOnTime,
                'count':
                    '${summary.completedOntimeCount}/${summary.totalTaskCount}',
                'label': 'Completed',
              },
              {
                'icon': AppImages.closedButDelayed,
                'count': '${summary.delayedCount}/${summary.totalTaskCount}',
                'label': 'Delayed',
              },
              //{'icon': AppImages.mytaskpng, 'count': '${summary.myTasksCount}/${summary.totalTaskCount}', 'label': 'My Tasks'},
              {
                'icon': AppImages.overDuePng,
                'count':
                    '${summary.overdueTasksCount}/${summary.totalTaskCount}',
                'label': 'Overdue',
              },
            ];

    final userNames = userList.map((u) => u['user_name'].toString()).toList();
    final taskNames =
        filteredTaskList.map((t) => t['task_name'].toString()).toList();

    return _isNetworkAvailable
        ? Scaffold(
          backgroundColor: AppColors.white,
          appBar: customAppBar(context, title: 'Dashboard', showBack: true),
          body:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        /// Filter card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                offset: const Offset(0, -3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                offset: const Offset(0, 3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              /// User Name dropdown
                              customDropdown(
                                img: AppImages.usernameSvg,
                                title: 'User Name',
                                items: userNames,
                                selectedValue: selectedUser,
                                onChanged: _onUserSelected,
                              ),
                              const SizedBox(height: 12),

                              /// Task Name dropdown
                              customDropdown(
                                img: AppImages.addTaskSvg,
                                title: 'Task Name',
                                items: taskNames,
                                selectedValue: selectedProject,
                                onChanged: (value) {
                                  setState(() => selectedProject = value);
                                  debugPrint("📌 Selected Task: $value");
                                  if (value != null) {
                                    final taskId = _getTaskIdFromName(value);
                                    debugPrint("🔗 Selected Task ID: $taskId");
                                  }
                                },
                              ),
                              const SizedBox(height: 12),

                              /// From Date and To Date pickers
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _selectDate(context, true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 11,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppColors.gray,
                                            width: 0.4,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        //
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_month_outlined,
                                              color: AppColors.gray,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              fromDate != null
                                                  ? DateFormat(
                                                    'dd-MM-yyyy',
                                                  ).format(fromDate!)
                                                  : 'From Date',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _selectDate(context, false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 11,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppColors.gray,
                                            width: 0.4,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_month_outlined,
                                              color: AppColors.gray,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              toDate != null
                                                  ? DateFormat(
                                                    'dd-MM-yyyy',
                                                  ).format(toDate!)
                                                  : 'To Date',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              /// Search button
                              Align(
                                alignment: Alignment.bottomRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.appBar,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: _applyFilters,
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Search',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_outlined,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),
                        Expanded(
                          child: GridView.builder(
                            shrinkWrap:true,
                            itemCount:data.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 13,
                                  crossAxisSpacing: 13,
                                  childAspectRatio: 1.2,
                                ),
                            itemBuilder: (context, index) {
                              if (index >= data.length) {
                                return Container();
                              }
                              final item = data[index];

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedIndex = index;
                                  });

                                  Widget? nextPage;
                                  debugPrint("🔎 Navigation Details:");
                                  debugPrint("👉 Selected Index: $index");
                                  debugPrint(
                                    "👤 Assigned UserId: $_selectedUserId",
                                  );
                                  debugPrint("👤 UserId: $_userId");
                                  debugPrint(
                                    "📌 TaskId: ${selectedProject != null ? _getTaskIdFromName(selectedProject!) : null}",
                                  );
                                  debugPrint(
                                    "📅 FromDate: ${fromDate?.toIso8601String()}",
                                  );
                                  debugPrint(
                                    "📅 ToDate: ${toDate?.toIso8601String()}",
                                  );

                                  switch (index) {
                                    case 0:
                                      nextPage = ToDoBoard(
                                        showAppBar: true,
                                        assignTo: _selectedUserId,
                                        userId: _userId,
                                        taskId:
                                            selectedProject != null
                                                ? _getTaskIdFromName(
                                                  selectedProject!,
                                                )
                                                : null,
                                        fromDate: fromDate,
                                        toDate: toDate,
                                      );
                                      break;
                                    case 1:
                                      nextPage = AssignedToTeamScreen(

                                        assignTo: _selectedUserId,
                                        userId: _userId,
                                        taskId:
                                            selectedProject != null
                                                ? _getTaskIdFromName(
                                                  selectedProject!,
                                                )
                                                : null,
                                        fromDate: fromDate,
                                        toDate: toDate,
                                      );
                                      break;
                                    case 2:
                                      nextPage = CompletedOnTimeTask(
                                        showAppBar: true,
                                        assignTo: _selectedUserId,
                                        userId: _userId,
                                        taskId:
                                            selectedProject != null
                                                ? _getTaskIdFromName(
                                                  selectedProject!,
                                                )
                                                : null,
                                        fromDate: fromDate,
                                        toDate: toDate,
                                      );
                                      break;
                                    case 3:
                                      nextPage = GetDelayedScreen(
                                        showAppBar: true,
                                        assignTo: _selectedUserId,
                                        userId: _userId,
                                        taskId:
                                            selectedProject != null
                                                ? _getTaskIdFromName(
                                                  selectedProject!,
                                                )
                                                : null,
                                        fromDate: fromDate,
                                        toDate: toDate,
                                      );
                                      break;
                                    // case 4:
                                    // // Add your My Tasks screen navigation here
                                    //   nextPage = MyTaskScreen( // Create this screen if it doesn't exist
                                    //     userId: _userId,
                                    //     assignedUserId: _selectedUserId,
                                    //     taskId: selectedProject != null ? _getTaskIdFromName(selectedProject!) : null,
                                    //     fromDate: fromDate,
                                    //     toDate: toDate,
                                    //   );
                                    //   break;
                                    case 4:
                                      // Add your Overdue screen navigation here
                                      nextPage = OverdueScreen(
                                        // Create this screen if it doesn't exist
                                        showAppBar: true,
                                        assignTo: _selectedUserId,
                                        userId: _userId,
                                        taskId:
                                            selectedProject != null
                                                ? _getTaskIdFromName(
                                                  selectedProject!,
                                                )
                                                : null,
                                        fromDate: fromDate,
                                        toDate: toDate,
                                      );
                                      break;
                                    default:
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: const Text('Coming Soon'),
                                              content: const Text(
                                                'This screen is under development and will be available soon.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            ),
                                      );
                                      return;
                                  }

                                  if (nextPage != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => nextPage!,
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.white,
                                    border: const Border(
                                      bottom: BorderSide(
                                        color: Colors.orange,
                                        width: 3,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        offset: const Offset(0, -3),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        offset: const Offset(0, 3),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Image.asset(
                                        item['icon']!,
                                        height: 60,
                                        width: 60,
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(height: 11),
                                          Text(
                                            item['count']!,
                                            style: GoogleFonts.lato(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF333333),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item['label']!,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.lato(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF333333),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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
  }
}
