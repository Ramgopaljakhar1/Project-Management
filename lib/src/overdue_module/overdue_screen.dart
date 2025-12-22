import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_management/src/overdue_module/controller/overdue_controller.dart';
import 'package:provider/provider.dart';

import '../assigned_to_team_module/controller/controller.dart';
import '../common_widgets/app_state_screen.dart';
import '../common_widgets/appbar.dart';
import '../common_widgets/common_bottom_button.dart';
import '../common_widgets/common_shimmer_loader.dart';
import '../common_widgets/custom_snackbar.dart';
import '../common_widgets/searching_field.dart';
import '../common_widgets/task_card.dart';
import '../completed_on_time_tasks_module/screen/task_completed_screen.dart';
import '../utils/animated_bell_icon.dart';
import '../utils/colors.dart';
import '../utils/img.dart';
import '../utils/no_internet_connectivity.dart';
import '../utils/shared_pref_constants.dart';
import '../utils/shared_preference.dart';
import '../utils/topbar.dart';

class OverdueScreen extends StatefulWidget {
  final bool showAppBar;
  final String? userId;
  final String? assignTo;
  final DateTime? fromDate;

  final DateTime? toDate;
  final String? taskId;
  const OverdueScreen({
    super.key,
    this.showAppBar = false,
    this.userId,
    this.fromDate,
    this.toDate,
    this.taskId,
    this.assignTo,
  });

  @override
  State<OverdueScreen> createState() => _OverdueScreenState();
}

class _OverdueScreenState extends State<OverdueScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String? token;
  dynamic user;
  String? _userId;
  final Connectivity _connectivity = Connectivity();
  bool _isNetworkAvailable = true;
  List<Map<String, dynamic>> _projectList = [];
  bool _isLoadingProjects = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final controller = Provider.of<OverDueController>(context, listen: false);
    //   controller.fetchOverdueTasks(
    //
    //   );
    // });
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    _loadProjectList();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = SharedPref();
    final tokenVal = await prefs.read(SharedPrefConstant().kAuthToken);
    final userData = await prefs.read(SharedPrefConstant().kUserData);

    if (mounted) {
      setState(() {
        token = tokenVal;
        user = userData;
        _userId = widget.userId ?? userData?['id']?.toString();
      });

      debugPrint("🔑 Token: $token");
      debugPrint("👤 Username: ${user?['username']}");
      debugPrint("🆔 User ID: $_userId");

      if (_userId != null) {
        _fetchDashboardData();
      } else {
        debugPrint("❌ User ID is null!");
      }
    }
  }

  void _fetchDashboardData() {
    if (_userId != null) {
      final controller = Provider.of<OverDueController>(context, listen: false);
      controller
          .fetchOverdueTasks(
            userId: _userId!,
            taskId: widget.taskId,
            assignTo: widget.assignTo,
            fromDate:
                widget.fromDate?.toIso8601String().split('T')[0], // Format date
            toDate: widget.toDate?.toIso8601String().split('T')[0],
          )
          .then((_) {
            // Sort overdue tasks by ID descending
            controller.overDue.sort((a, b) {
              final idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
              final idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
              return idB.compareTo(idA);
            });

            setState(() {});
          });
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

  Future<void> _loadProjectList() async {
    setState(() {
      _isLoadingProjects = true;
    });

    try {
      final controller = Provider.of<OverDueController>(context, listen: false);
      final projects = await controller.fetchProjectList();
      setState(() {
        _projectList = projects;
      });
    } catch (e) {
      debugPrint("❌ Error loading projects: $e");
      setState(() {
        _projectList = [];
      });
    } finally {
      setState(() {
        _isLoadingProjects = false;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<OverDueController>(context);
    final isLoading = controller.isLoading;

    final filteredTasks =
        controller.overDue.where((task) {
          final name = task['task_name']?.toLowerCase() ?? '';
          return name.contains(searchQuery.toLowerCase());
        }).toList();

    return _isNetworkAvailable
        ? Scaffold(
          backgroundColor: Colors.white,
          appBar:
              widget.showAppBar
                  ? customAppBar(
                    context,
                    title: 'Overdue Tasks',
                    showBack: true,
                    showLogo: false,
                    // filter: () async {
                    //   await _loadProjectList();
                    //   showFilterBottomSheet(context);
                    // },
                  )
                  : null,
          body:
              isLoading
                  ? Center(child: buildShimmerLoader())
                  : controller.overDue.isEmpty
                  ? AppStateScreen(
                    showAppBar: false,
                    imagePath: AppImages.dataNotFound,
                    title: 'Data Not Found!',
                    subtitle1: 'We are unable to find the data that',
                    subtitle2: 'you are looking for.',
                    buttonText: 'Retry',
                    onButtonPressed: () {
                      _fetchDashboardData(); // ✅ Re-fetch data
                    },
                  )
                  : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        //   const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: searchingField(
                            onPress: () {
                              setState(() {
                                searchController.clear();
                                searchQuery = '';
                              });
                            },
                            fillColor: AppColors.white,
                            searchController: searchController,
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value.trim();
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredTasks.length,
                            itemBuilder: (context, index) {
                              final task = filteredTasks[index];
                              debugPrint("🔍 Over Task: ${jsonEncode(task)}");

                              return taskCard(
                                taskName: task['task_name'] ?? 'No Task Name',
                                priority:
                                    task['priority_lookupdet_desc'] ?? 'Low',
                                assignedDate:
                                    DateTime.tryParse(
                                      task['assign_date'] ?? '',
                                    ) ??
                                    DateTime.now(),
                                showBell: true,
                                onBellTap: () async {
                                  final controller =
                                      Provider.of<AssignedToTeam>(
                                        context,
                                        listen: false,
                                      );
                                  // final notifyTo = task['assigned_to_user_id'];
                                  final taskId = task['id'];
                                  final String assigned_id =
                                      task['assign_to']?.toString() ?? '';
                                  final createdBy = int.parse(_userId!);
                                  print('Task Id : $taskId');
                                  print('notify To : ${'147'}');
                                  print('createdBy : $createdBy');
                                  if (taskId != null && assigned_id != null) {
                                    try {
                                      final message = await controller
                                          .sendReminder(
                                            taskId: taskId,
                                            notifyTo: int.parse(assigned_id),
                                            createdBy: createdBy,
                                          );

                                      // Show API message dynamically
                                      //    showTopNotification(context, message, bgColor: AppColors.appBar);
                                    } catch (e) {
                                      showTopNotification(
                                        context,
                                        "❌ Failed to send reminder",
                                        bgColor: AppColors.red,
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppColors.red,
                                        content: Text('❌ Cannot send reminder'),
                                      ),
                                    );
                                  }
                                },

                                showFavourite: false,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 8,
                                ),
                                padding: const EdgeInsets.all(10),
                                onEyeTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => TaskCompletedScreen(
                                            taskData: task,
                                            previousScreenTitle:
                                                "Overdue Task Details Screen",
                                          ),
                                    ),
                                  );
                                  print('click view...');
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
  }

  Future<void> showFilterBottomSheet(BuildContext context) async {
    final controller = Provider.of<AssignedToTeam>(context, listen: false);

    // Selected values
    String? selectedProjectId;
    String? selectedProjectName;
    String? selectedTaskId;
    String? selectedTaskName;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Filter tasks based on selected project
            List<dynamic> filteredTasks =
                selectedProjectId != null
                    ? controller.teamTaskListData.where((task) {
                      final taskProjectId = task['project_name']?.toString();
                      return taskProjectId == selectedProjectId;
                    }).toList()
                    : controller.teamTaskListData;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Filters',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 40),

                    /// 🔽 Project Dropdown
                    if (_isLoadingProjects)
                      const CircularProgressIndicator()
                    else if (_projectList.isEmpty)
                      const Text('No projects available')
                    else
                      DropdownSearch<String>(
                        items:
                            (filter, loadProps) =>
                                _projectList
                                    .map(
                                      (project) =>
                                          project['name']?.toString() ??
                                          'Unknown Project',
                                    )
                                    .toList(),
                        selectedItem: selectedProjectName,
                        popupProps: PopupProps.modalBottomSheet(
                          showSearchBox: true,
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.7,
                          ),
                          searchFieldProps: TextFieldProps(
                            // autofocus: true, // This ensures keyboard stays open
                            padding: const EdgeInsets.symmetric(
                              vertical: 30,
                              horizontal: 17,
                            ),
                            decoration: InputDecoration(
                              hintText: "Search...",
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        decoratorProps: DropDownDecoratorProps(
                          decoration: InputDecoration(
                            labelStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w300,
                              fontStyle: FontStyle.italic,
                            ),
                            labelText: "Project Name",
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SvgPicture.asset(AppImages.projectSvg),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                width: 0.8,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            selectedProjectName = val;

                            // Get selected project ID
                            final selectedProject = _projectList.firstWhere(
                              (project) =>
                                  project['name'] == selectedProjectName,
                              orElse: () => <String, dynamic>{},
                            );
                            selectedProjectId =
                                selectedProject['id']?.toString();

                            debugPrint(
                              'Selected Project: $selectedProjectName ($selectedProjectId)',
                            );

                            // Reset task selection when project changes
                            selectedTaskId = null;
                            selectedTaskName = null;
                          });
                        },
                      ),

                    const SizedBox(height: 16),

                    /// 🔽 Task Dropdown (filtered by selected project)
                    DropdownSearch<String>(
                      items:
                          (filter, loadProps) =>
                              filteredTasks
                                  .map(
                                    (task) =>
                                        task['task_name']?.toString() ??
                                        'Unknown Task',
                                  )
                                  .toList(),
                      selectedItem: selectedTaskName,
                      popupProps: PopupProps.modalBottomSheet(
                        showSearchBox: true,
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.7,
                        ),
                        searchFieldProps: TextFieldProps(
                          autofocus: true, // This ensures keyboard stays open
                          padding: const EdgeInsets.symmetric(
                            vertical: 30,
                            horizontal: 17,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search...",
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w300,
                            fontStyle: FontStyle.italic,
                          ),
                          labelText: "Task Name",
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SvgPicture.asset(AppImages.tagUserSvg),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              width: 0.8,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          selectedTaskName = val;
                          final selectedTask = filteredTasks.firstWhere(
                            (task) => task['task_name'] == selectedTaskName,
                            orElse: () => <String, dynamic>{},
                          );
                          selectedTaskId = selectedTask['id']?.toString();
                          debugPrint(
                            'Selected Task: $selectedTaskName ($selectedTaskId)',
                          );
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    /// 🔘 Buttons
                    bottomButton(
                      title: 'Apply',
                      subtitle: 'Clear',
                      icon: Icons.done,
                      icons: Icons.close,
                      onPress: () {
                        // Call API with selected filters
                        controller.fetchFilteredTeamTasks(
                          userId: _userId!,
                          taskId: selectedTaskId,
                          projectId: selectedProjectId,
                        );
                        Navigator.pop(context);
                      },
                      onTap: () {
                        // Clear filters and reset to show all tasks
                        setModalState(() {
                          selectedProjectId = null;
                          selectedProjectName = null;
                          selectedTaskId = null;
                          selectedTaskName = null;
                        });

                        controller.fetchTeamTasks(userId: _userId!);
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
