import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:project_management/src/utils/string.dart';
import 'package:provider/provider.dart';

import '../../common_widgets/app_state_screen.dart';
import '../../common_widgets/appbar.dart';
import '../../common_widgets/common_bottom_button.dart';
import '../../common_widgets/common_shimmer_loader.dart';
import '../../common_widgets/custom_dropdown.dart';
import '../../common_widgets/custom_snackbar.dart';
import '../../common_widgets/searching_field.dart';
import '../../common_widgets/task_card.dart';
import '../../edit_Task_module/edit_task_details.dart';
import '../../task_module/models/task_details_model.dart';
import '../../utils/colors.dart';
import '../../utils/img.dart';
import '../../utils/no_internet_connectivity.dart';
import '../../utils/shared_pref_constants.dart';
import '../../utils/shared_preference.dart';
import '../../utils/topbar.dart';
import '../controller/controller.dart';

class AssignedToTeamScreen extends StatefulWidget {
  final bool showAppBar;
  final String? userId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? assignTo;
  final String? taskId;
  const AssignedToTeamScreen({
    super.key,
    this.showAppBar = true,
    this.userId,
    this.assignTo,
    this.fromDate,
    this.toDate,
    this.taskId,
  });
  //
  @override
  State<AssignedToTeamScreen> createState() => _AssignedToTeamScreenState();
}

class _AssignedToTeamScreenState extends State<AssignedToTeamScreen> {
  String searchQuery = '';
  List<Map<String, dynamic>> _projectList = [];
  bool _isLoadingProjects = false;

  String? token;
  dynamic user;
  String? _userId;
  final Connectivity _connectivity = Connectivity();
  bool _isNetworkAvailable = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool isLoading = false;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initConnectivity();
    didChangeDependencies();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    _loadProjects();
  }
  Future<void> _loadProjects() async {
    if (mounted) {
      setState(() {
        _isLoadingProjects = true;
      });
    }

    try {
      final controller = Provider.of<AssignedToTeam>(context, listen: false);
      final projects = await controller.fetchProjectList();

      if (mounted) {
        setState(() {
          _projectList = projects;
          _isLoadingProjects = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProjects = false;
        });
      }
      debugPrint('Error loading projects: $e');
    }
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
      debugPrint("🆔 User ID---: $_userId");

      if (_userId != null) {
        _fetchDashboardData();
      } else {
        debugPrint("❌ User ID is null!");
      }
    }
  }

  void _fetchDashboardData() {
    if (_userId != null) {
      final controller = Provider.of<AssignedToTeam>(context, listen: false);

      // If assignedUserId is null (not selected from Dashboard), default to logged-in user
      final assignedUserToUse = widget.assignTo;

      controller.fetchTeamTasks(
        userId: _userId!,
        taskId: widget.taskId,
        assignTo: assignedUserToUse,
        fromDate: widget.fromDate?.toIso8601String().split('T')[0],
        toDate: widget.toDate?.toIso8601String().split('T')[0],
      );
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
  final FocusNode _searchFocusNode = FocusNode();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchDashboardData();
  }
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
  void clearSearch() {
    setState(() {
      searchQuery = '';
      searchController.clear();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<AssignedToTeam>(
      builder: (context, controller, child) {
        final filteredTasks = controller.teamTaskListData.where((task) {
          if (searchQuery.isEmpty) return true;

          final name = task['task_name']?.toString().toLowerCase() ?? '';
          final id = task['id']?.toString().toLowerCase() ?? '';
          final description = task['task_detail']?.toString().toLowerCase() ?? '';
          final assignee = task['assign_to_user_name']?.toString().toLowerCase() ?? '';
          final date = task['assign_date']?.toString().toLowerCase() ?? '';
          return name.contains(searchQuery) ||
              id.contains(searchQuery) ||
              description.contains(searchQuery) ||
              assignee.contains(searchQuery) || date.contains(searchQuery);
        }).toList();
        filteredTasks.sort((a, b) {
          final idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
          final idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
          return idB.compareTo(idA); // descending
        });
        return _isNetworkAvailable
            ? Scaffold(
              appBar:
                  widget.showAppBar
                      ? customAppBar(
                        context,
                        title: 'Assigned Tasks',
                        showBack: true,showLogo: false
                        // filter: () {
                        //   showFilterBottomSheet(context);
                        // },
                      )
                      : null,
              backgroundColor: AppColors.backGroundColor,
              body:
                  controller.isLoading
                      ? Center(child: buildShimmerLoader())
                      : filteredTasks.isEmpty
                      ? AppStateScreen(
                        showAppBar: false,
                        imagePath: AppImages.dataNotFound,
                        title: 'Data Not Found !',
                        subtitle1: 'We are unable to find the data that',
                        subtitle2: 'you are looking for.',
                        buttonText: 'Retry',
                        onButtonPressed: () {
                          _fetchDashboardData();
                        },
                      )
                      : Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 7,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// 🔍 Search Field
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(2, -2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: searchController,
                                      focusNode: _searchFocusNode, // Use focus node
                                      onChanged: updateSearch,
                                      decoration: InputDecoration(
                                        hintText: 'Search tasks...',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 15,
                                        ),
                                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  if (searchQuery.isNotEmpty)
                                    IconButton(
                                      icon: Icon(Icons.clear),
                                      onPressed: clearSearch,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 11),

                            // Show search status
                            // if (searchQuery.isNotEmpty)
                            //   Padding(
                            //     padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            //     child: Text(
                            //       'Found ${filteredTasks.length} results for "$searchQuery"',
                            //       style: GoogleFonts.lato(
                            //         fontSize: 14,
                            //         color: Colors.grey[600],
                            //       ),
                            //     ),
                            //   ),
                            const SizedBox(height: 11),

                            /// 📋 Task List
                            Expanded(
                              child:
                                  controller.isLoading
                                      ? Center(child: buildShimmerLoader())
                                      : filteredTasks.isEmpty
                                      ? const Center(
                                        child: Text('No tasks found'),
                                      )
                                      : ListView.builder(
                                        itemCount: filteredTasks.length,
                                        itemBuilder: (context, index) {
                                          final task = filteredTasks[index];

                                          final String priority =
                                              task['priority_lookupdet_desc']
                                                  ?.toString() ??
                                              'Low';

                                          final String taskName =
                                              task['task_name']?.toString() ??
                                              'Unnamed Task';
                                          final String assignedName =
                                              task['assign_to_user_name']
                                                  ?.toString() ??
                                              'Unnamed Task';
                                          final String assigned_id =
                                              task['assign_to']
                                                  ?.toString() ??
                                              'Unnamed Task';
                                          print('assign  to : $assignedName');
                                          print('assign  to Id : $assigned_id');
                                          final String assignedDateStr =
                                              task['assign_date']?.toString() ??
                                              '';
                                          DateTime assignedDate;
                                          try {
                                            assignedDate = DateTime.parse(
                                              assignedDateStr,
                                            );
                                          } catch (e) {
                                            assignedDate = DateTime.now();
                                          }
                                          return taskCard(
                                            showFavourite: false,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 2,
                                              vertical: 11,
                                            ),
                                            onBellTap: () async {
                                              final controller =
                                                  Provider.of<AssignedToTeam>(
                                                    context,
                                                    listen: false,
                                                  );
                                             // final notifyTo = task['assigned_to_user_id'];
                                              final taskId = task['id'];

                                              final createdBy = int.parse(
                                                _userId!,
                                              );
                                              print('Task Id : $taskId');
                                              print('notify To : ${'147'}');
                                              print('createdBy : $createdBy');
                                              if (taskId != null &&
                                                  assigned_id != null) {
                                                try {
                                                  final message =
                                                      await controller
                                                          .sendReminder(
                                                            taskId: taskId,
                                                            notifyTo: int.parse(assigned_id),
                                                            createdBy:
                                                                createdBy,
                                                          );

                                                  // Show API message dynamically
                                                 // showTopNotification(context, message, bgColor: AppColors.appBar);
                                                } catch (e) {

                                                  showTopNotification(context, '❌ Failed to send reminder', bgColor:  AppColors.red);
                                                }
                                              } else {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    backgroundColor:
                                                        AppColors.red,
                                                    content: Text(
                                                      '❌ Cannot send reminder',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
//
                                            onEyeTap: () {
                                              final taskId =
                                                  task['id']?.toString() ??
                                                  'Unknown ID';
                                              final taskName =
                                                  task['task_name']
                                                      ?.toString() ??
                                                  'Unnamed Task';
                                              print(
                                                "📌 Navigating to ViewMyTaskScreen",
                                              );
                                              print("🆔 Task ID: $taskId");
                                              print("📋 Task Name: $taskName");
                                              print("👁 Eye tapped");
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        context,
                                                      ) => EditTaskDetails(
                                                        taskId:
                                                            taskId.toString(),
                                                        // task:TaskDetailsModel.fromJson(task),
                                                      ),
                                                ),
                                              ).then((_) {
                                                // This runs when returning from the pushed screen
                                                _fetchDashboardData(); // refresh the tasks
                                              });
                                            },
                                            priority: priority,
                                            taskName: taskName,
                                            showAssignedTo: true,
                                            assignedDate: assignedDate,
                                            subTitle: assignedName,
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
            List<dynamic> filteredTasks = selectedProjectId != null
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
                        items:(filter, loadProps) =>  _projectList
                            .map((project) => project['name']?.toString() ?? 'Unknown Project')
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
                                  (project) => project['name'] == selectedProjectName,
                              orElse: () => <String, dynamic>{},
                            );
                            selectedProjectId = selectedProject['id']?.toString();

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
                      items:(filter, loadProps) =>  filteredTasks
                          .map((task) => task['task_name']?.toString() ?? 'Unknown Task')
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
