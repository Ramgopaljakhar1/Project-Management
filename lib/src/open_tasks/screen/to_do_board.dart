import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:project_management/src/common_widgets/common_bottom_button.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../common_widgets/appbar.dart';
import '../../common_widgets/common_shimmer_loader.dart';
import '../../common_widgets/custom_snackbar.dart';
import '../../common_widgets/elevated_button.dart';
import '../../common_widgets/searching_field.dart';
import '../../dashboard_module/controller/controller.dart';
import '../../task_module/controller/add_task_controller.dart';
import '../../task_module/controller/task_detail_controller.dart';
import '../../task_module/models/task_date_time_model.dart';
import '../../task_module/models/task_details_model.dart';
import '../../task_module/models/task_model.dart';
import '../../task_module/screens/task_details.dart';
import '../../task_module/widgets/repeats_screen.dart';
import '../../utils/colors.dart';
import '../../utils/img.dart';
import '../../utils/no_internet_connectivity.dart';
import '../../utils/shared_pref_constants.dart';
import '../../utils/shared_preference.dart';
import '../../utils/string.dart';
import '../controller/open_task_controller.dart';
import '../widget/add _description_Collapse.dart';

class ToDoBoard extends StatefulWidget {
  final bool showAppBar;
  final String? userId;
  final String? assignTo;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? taskId;
  const ToDoBoard({
    super.key,
    this.showAppBar = false,
    this.userId,
    this.fromDate,
    this.toDate,
    this.taskId,
    this.assignTo,
  });

  @override
  State<ToDoBoard> createState() => _ToDoBoardState();
}

class _ToDoBoardState extends State<ToDoBoard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? token;
  bool isLoading = false;
  Map<String, dynamic>? user;
  String searchQuery = '';
  String selectedProject = 'All';
  bool isNameDuplicate = false;
  bool isFavourite = false;
  VoidCallback? _listener;
  String? _userId;
  final Connectivity _connectivity = Connectivity();
  bool _isNetworkAvailable = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  late OpenTaskController openTaskController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final dropdownSearchKey =
      GlobalKey<DropdownSearchState<Map<String, dynamic>>>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController dateRangeController = TextEditingController();
  final assignedDropdownSearchKey =
      GlobalKey<DropdownSearchState<Map<String, dynamic>>>();
  final TextEditingController estimatedHoursController =
      TextEditingController();
  TextEditingController repeatDateTimeController = TextEditingController();
  String? _selectedPriorityId;
  File? _uploadedFile;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  String? _assignToId;
  String? _assignToName;
  List<String> _taggedUserIds = [];
  List<Map<String, dynamic>> _taggedUsers = [];
  String? _repeatSummary;
  Map<String, dynamic>? _repeatData;
  late TabController _tabController;
  TaskDetailController? taskDetailController;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? repeatText;
  DateTime? fromDate;
  DateTime? toDate;
  DateTime? rangeStart;
  DateTime? rangeEnd;
  String? repeatSummary;

  bool isfav = false;
  String? isSelect;
  List<Map<String, dynamic>> userList = [];
  DashboardController? dashboardController;
  AddTaskController? addTaskController;

  // Track current step in the form flow
  int _currentFormStep = 0;
  // Track which bottom sheets are open
  bool _isDescriptionSheetOpen = false;
  bool _isDateTimeSheetOpen = false;
  bool _isAssignToSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _listener = () {
      setState(() {});
    };
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    _loadUserData().then((_) {
      if (token != null) {
        final controller = Provider.of<AddTaskController>(
          context,
          listen: false,
        );
        final openTaskController = Provider.of<OpenTaskController>(
          context,
          listen: false,
        );
        controller.setContext(context);
        openTaskController.openTaskList;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openTaskController = Provider.of<OpenTaskController>(
        context,
        listen: false,
      );
    });
    _refreshTasks();
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

      debugPrint("👤 Loaded User ID: $_userId");
      debugPrint("🔐 Loaded Token: $token");

      debugPrint("👤 Loaded User ID: $_userId");

      if (_userId != null) {
        await Provider.of<OpenTaskController>(
          context,
          listen: false,
        ).fetchOpenTasks(
          userId: _userId!,
          assignTo: widget.assignTo,
          taskId: widget.taskId, // Pass taskId
          fromDate:
              widget.fromDate?.toIso8601String().split('T')[0], // Format date
          toDate: widget.toDate?.toIso8601String().split('T')[0], // Format date
        );
      } else {
        debugPrint("❌ User ID is null!");
      }
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    openTaskController = Provider.of<OpenTaskController>(
      context,
      listen: false,
    );

    // Schedule async call after build is done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
      // _refreshTasks();
    });
  }

  Future<void> _refreshTasks() async {
    if (_userId != null) {
      await openTaskController.fetchOpenTasks(userId: _userId!);
      if (mounted) {
        setState(() {}); // Safe now, since frame is complete
      }
    }
  }

  @override
  void dispose() {
    addTaskController?.taskNameController.clear();
    searchController.dispose();
    openTaskController.clearTask();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AddTaskController>(context);
    final openTaskController = Provider.of<OpenTaskController>(context);
    List allTasks = openTaskController.openTaskList;
    final lowerSearch = searchQuery.toLowerCase();
    final taskNames = controller.taskNames;

    final filteredTasks =
        selectedProject == 'All'
            ? controller.tasks
            : controller.tasks
                .where((task) => task.projectName == selectedProject)
                .toList();

    List<AddTaskModel> searchedTasks =
        filteredTasks.where((task) {
          final name = task.taskName.toLowerCase();
          final description = task.taskDetail.toLowerCase();
          return name.contains(searchQuery.toLowerCase()) ||
              description.contains(searchQuery.toLowerCase());
        }).toList();
    List<dynamic> _getFilteredTasks(List<dynamic> allTasks) {
      if (searchQuery.isEmpty) {
        return allTasks;
      }

      return allTasks.where((task) {
        final taskName = task['task_name']?.toString().toLowerCase() ?? '';
        final taskDetail = task['task_detail']?.toString().toLowerCase() ?? '';
        return taskName.contains(searchQuery.toLowerCase()) ||
            taskDetail.contains(searchQuery.toLowerCase());
      }).toList();
    }

    return _isNetworkAvailable
        ? Scaffold(
          backgroundColor: AppColors.white,
          appBar:
              widget.showAppBar
                  ? customAppBar(
                    context,
                    title: 'Open Task Screen',
                    showBack: true,showLogo: false
                  )
                  : null,
          body: RefreshIndicator(
            onRefresh: _refreshTasks,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11.0),
              child:
                  openTaskController.isLoading
                      ? buildShimmerLoader()
                      : openTaskController.openTaskList.isEmpty
                      ? buildNoTaskUI(context)
                      : buildProjectListUI(
                        context,
                        controller,
                        taskNames,
                        searchedTasks,
                      ),
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

  /// No Task UI
  Widget buildNoTaskUI(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 13),
          child: Image.asset(AppImages.task),
        ),
        const SizedBox(height: 13),
        Text(
          AppStrings.noTasks,
          style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        Text(
          AppStrings.quicklyCreateTask,
          style: GoogleFonts.lato(
            fontSize: 16,
            color: AppColors.gray,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 70),
        Padding(
          padding: const EdgeInsets.only(bottom: 65.0, left: 24, right: 24),
          child: elevatedButton(
            onpress: () {
              _showProjectBottomSheetTask(context);
            },
            title: AppStrings.addTask,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            iconColor: Colors.white,
            foregroundColor: Colors.white,
            backgroundColor: AppColors.appBar,
          ),
        ),
      ],
    );
  }

  /// Project List UI
  Widget buildProjectListUI(
    BuildContext context,
    AddTaskController controller,
    List<String> taskNames,
    List<AddTaskModel> filteredTasks,
  ) {
    final openTaskController = Provider.of<OpenTaskController>(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: []),
        const SizedBox(height: 13),

        /// Search section
        searchingField(
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

        const SizedBox(height: 11),

        /// Task List
        Expanded(
          child:
              controller.isLoading
                  ? buildShimmerLoader()
                  : openTaskController.openTaskList.isEmpty
                  ? Center(
                    child: Text(
                      "No tasks found",
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                  : ListView.builder(
                    itemCount: openTaskController.openTaskList.length,
                    itemBuilder: (context, index) {
                      var sortedTasks = List.from(
                        openTaskController.openTaskList,
                      )..sort((a, b) {
                        // Parse IDs as integers and compare
                        int idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
                        int idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
                        return idB.compareTo(idA); // Descending order
                      });
                      final task = sortedTasks[index];
                      final tasks = openTaskController.openTaskList[index];

                      // Skip this item if it doesn't match search query
                      if (searchQuery.isNotEmpty) {
                        final taskName =
                            task['task_name']?.toString().toLowerCase() ?? '';
                        final taskDetail =
                            task['task_detail']?.toString().toLowerCase() ?? '';
                        if (!taskName.contains(searchQuery.toLowerCase()) &&
                            !taskDetail.contains(searchQuery.toLowerCase())) {
                          return Container(); // Return empty container for non-matching items
                        }
                      }
                      //   final task = openTaskController.openTaskList[index];
                      return GestureDetector(
                        onTap: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => TaskDetailsScreen(
                                    taskName: task['task_name'] ?? '',
                                    taskId: task['id'].toString(),
                                    task: TaskDetailsModel.fromJson(task),
                                  ),
                            ),
                          ).then((_) async {
                            //if (!mounted) return;
                            if (_userId != null) {
                              await Provider.of<OpenTaskController>(
                                context,
                                listen: false,
                              ).fetchOpenTasks(userId: _userId!);
                            }
                            await _refreshTasks();
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 3),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, -3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  AppImages.addTaskSvg,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task['task_name'] ?? 'Unnamed Task',
                                        style: GoogleFonts.lato(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    final controller =
                                        Provider.of<AddTaskController>(
                                          context,
                                          listen: false,
                                        );
                                    final taskId = task['id'];
                                    final taskName =
                                        task['task_name'] ?? 'Unnamed';
                                    final isCurrentlyFav =
                                        task['favorite_flag'] == 'Y';
                                    final updatedFlag =
                                        isCurrentlyFav ? 'N' : 'Y';

                                    task['favorite_flag'] =
                                        updatedFlag; // Optimistically update UI
                                    setState(() {}); // Refresh card UI
                                    /// 🌟 Log basic details
                                    debugPrint('⭐ Favorite tapped');
                                    debugPrint('📌 Task Name: $taskName');
                                    debugPrint('🆔 Task ID: $taskId');
                                    debugPrint('👤 User ID: $_userId');
                                    debugPrint(
                                      '✅ Current Fav Flag: ${task['favorite_flag']} → Updated to: $updatedFlag',
                                    );
                                    if (token != null && _userId != null) {
                                      await controller.updateTaskFavoriteFlag(
                                        token: token!,
                                        taskId: taskId,
                                        favoriteFlag: updatedFlag,
                                        userId: _userId!,
                                      );
                                    } else {
                                      debugPrint("❌ Token or User ID is null");
                                    }
                                  },
                                  // look image
                                  child: SvgPicture.asset(
                                    (task['favorite_flag'] ?? 'N') == 'Y'
                                        ? AppImages.favouriteSvg
                                        : AppImages.makeFavouriteSvg,
                                    height: 28,
                                    width: 28,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                      //   _buildTaskCard(task, () {
                      //   Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //       builder: (context) => TaskDetailsScreen(
                      //         taskName: task['task_name'] ?? '',
                      //         taskId: task['id'].toString(),
                      //         task: TaskDetailsModel.fromJson(task), // <- assuming you have fromJson
                      //       ),
                      //     ),
                      //   );
                      // });
                    },
                  ),
        ),
      ],
    );
  }

  /// Bottom sheet for adding new task
  Future<void> _showProjectBottomSheetTask(BuildContext context) async {
    final controller = Provider.of<AddTaskController>(context, listen: false);
    final taskDetails = Provider.of<TaskDetailController>(
      context,
      listen: false,
    );
    final dashboardController = Provider.of<DashboardController>(
      context,
      listen: false,
    );
    final openTaskController = Provider.of<OpenTaskController>(
      context,
      listen: false,
    );
    late VoidCallback? _listener;

    controller.taskNameController.clear();
    controller.resetForm();
    dashboardController.resetForm();
    taskDetails.resetForm();
    controller.setContext(context);
    final token = this.token;

    await showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      isScrollControlled: true,

      builder: (context) {
        return SafeArea(
          child: Consumer<AddTaskController>(
            builder: (context, controller, child) {
              bool hasTaskName = false;
              bool isFavourite = false;

              return WillPopScope(
                onWillPop: () async {
                  if (!controller.isSaving) {
                    controller.resetForm();
                    controller.taskNameController.clear();
                    return true;
                  }
                  return false; // Prevent closing while saving
                },
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          child: Form(
                            key: controller.formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Add Task',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                TextFormField(
                                  controller: controller.taskNameController,
                                  onChanged: (value) {
                                    final hasValue = value.trim().isNotEmpty;
                                    hasTaskName = hasValue;

                                    isNameDuplicate =
                                        hasValue
                                            ? controller.isTaskNameExists(
                                              value.trim(),
                                            )
                                            : false;
                                  },
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter task name';
                                    }
                                    if (value.trim().length < 10) {
                                      return 'Task name must be at least 10 characters';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Task Name',
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Image.asset(
                                        AppImages.addTask,
                                        height: 24,
                                        width: 24,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Icons row
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable:
                                      controller.taskNameController,
                                  builder: (context, value, child) {
                                    final hasTaskName =
                                        value.text.trim().length >= 10;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        left: 17.0,
                                      ),
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap:
                                                hasTaskName
                                                    ? () {
                                                      _currentFormStep = 1;
                                                      _showDescriptionBottomSheet(
                                                        context,
                                                        dashboardController,
                                                        taskDetails,
                                                      );
                                                    }
                                                    : null,
                                            child: SvgPicture.asset(
                                              AppImages.descriptionSvg,
                                              width: 28,
                                              height: 28,
                                              color:
                                                  hasTaskName
                                                      ? null
                                                      : Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 26),
                                          GestureDetector(
                                            onTap:
                                                hasTaskName
                                                    ? () {
                                                      _currentFormStep = 2;
                                                      _showProjectBottomSheetDate(
                                                        context,
                                                      );
                                                    }
                                                    : null,
                                            child: SvgPicture.asset(
                                              AppImages.dateTimeSvg,
                                              width: 28,
                                              height: 28,
                                              color:
                                                  hasTaskName
                                                      ? null
                                                      : Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 26),
                                          GestureDetector(
                                            onTap:
                                                hasTaskName
                                                    ? () {
                                                      _currentFormStep = 3;
                                                      _showAssignToBottomSheet(
                                                        context,
                                                      );
                                                    }
                                                    : null,
                                            child: SvgPicture.asset(
                                              AppImages.assignToSvg,
                                              width: 28,
                                              height: 28,
                                              color:
                                                  hasTaskName
                                                      ? null
                                                      : Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 26),
                                          GestureDetector(
                                            onTap:
                                                hasTaskName
                                                    ? () {
                                                      controller
                                                          .toggleFavouriteFlag();
                                                    }
                                                    : null,
                                            child: SvgPicture.asset(
                                              controller.isFavourite
                                                  ? AppImages.favouriteSvg
                                                  : AppImages.makeFavouriteSvg,
                                              width: 28,
                                              height: 28,
                                              color:
                                                  hasTaskName
                                                      ? null
                                                      : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                                if (isNameDuplicate)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'A task with this name already exists',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                const SizedBox(height: 18),

                                const SizedBox(height: 24),
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable:
                                      controller.taskNameController,
                                  builder: (context, value, _) {
                                    final hasTaskName =
                                        value.text.trim().isNotEmpty;
                                    final isNameDuplicate =
                                        hasTaskName
                                            ? controller.isTaskNameExists(
                                              value.text.trim(),
                                            )
                                            : false;

                                    return ElevatedButton(
                                      onPressed:
                                          (hasTaskName &&
                                                  !isNameDuplicate &&
                                                  !controller.isSaving)
                                              ? () async {
                                                // Validate form
                                                if (!controller
                                                    .formKey
                                                    .currentState!
                                                    .validate())
                                                  return;

                                                String? fileBase64;
                                                String? fileName;

                                                if (dashboardController
                                                        .uploadedFile !=
                                                    null) {
                                                  fileBase64 =
                                                      await dashboardController
                                                          .getFileBase64();
                                                  fileName =
                                                      dashboardController
                                                          .uploadedFile!
                                                          .path
                                                          .split('/')
                                                          .last;
                                                }

                                                String? assignToUserId;
                                                if (taskDetails
                                                            .selectedAssignToUserId !=
                                                        null &&
                                                    taskDetails
                                                            .selectedAssignToUserId !=
                                                        'self') {
                                                  assignToUserId =
                                                      taskDetails
                                                          .selectedAssignToUserId;
                                                }

                                                String? assignDate;
                                                String? assignTime;
                                                String? estimatedHours;
                                                String? estStartDate;
                                                String? estEndDate;

                                                if (taskDetails
                                                    .dateTimeList
                                                    .isNotEmpty) {
                                                  final dateTimeModel =
                                                      taskDetails
                                                          .dateTimeList
                                                          .first;

                                                  if (dateTimeModel
                                                          .rangeStart !=
                                                      null) {
                                                    assignDate = DateFormat(
                                                      'yyyy-MM-dd',
                                                    ).format(
                                                      dateTimeModel.rangeStart!,
                                                    );
                                                    estStartDate = assignDate;
                                                  }
                                                  if (dateTimeModel.rangeEnd !=
                                                      null) {
                                                    estEndDate = DateFormat(
                                                      'yyyy-MM-dd',
                                                    ).format(
                                                      dateTimeModel.rangeEnd!,
                                                    );
                                                  }
                                                  if (dateTimeModel.time !=
                                                      null) {
                                                    assignTime =
                                                        '${dateTimeModel.time!.hour}:${dateTimeModel.time!.minute.toString().padLeft(2, '0')}';
                                                  }
                                                  estimatedHours =
                                                      dateTimeModel
                                                          .estimatedHours;
                                                }

                                                List<String>?
                                                notificationUserIds;
                                                if (taskDetails
                                                    .taggedUsers
                                                    .isNotEmpty) {
                                                  notificationUserIds =
                                                      taskDetails.taggedUsers;
                                                }

                                                String? projectId;
                                                if (dashboardController
                                                            .selectedProjectId !=
                                                        null &&
                                                    dashboardController
                                                        .selectedProjectId!
                                                        .isNotEmpty) {
                                                  projectId =
                                                      dashboardController
                                                          .selectedProjectId;
                                                }

                                                String? priorityId;
                                                if (dashboardController
                                                        .selectedPriority?['id'] !=
                                                    null) {
                                                  priorityId =
                                                      dashboardController
                                                          .selectedPriority?['id']
                                                          ?.toString();
                                                }

                                                String? description;
                                                if (dashboardController
                                                    .detailsController
                                                    .text
                                                    .isNotEmpty) {
                                                  description =
                                                      dashboardController
                                                          .detailsController
                                                          .text;
                                                }

                                                /// add new taskprint("==== 📦 ADD NEW TASK API BODY SENT FROM UI =====");
                                                print({
                                                  "token": token,
                                                  "user_id": _userId!,
                                                  "description":
                                                      description ?? '',
                                                  "project_id": projectId,
                                                  "priority_id": priorityId,
                                                  "file_name": fileName,
                                                  "file_base64":
                                                      fileBase64 != null
                                                          ? "BASE64_STRING_${fileBase64.length}_CHARS"
                                                          : null,
                                                  "assign_to_user_id":
                                                      assignToUserId,
                                                  "assign_date": assignDate,
                                                  "assign_time": assignTime,
                                                  "notification_user_ids":
                                                      notificationUserIds,
                                                  "estimated_hours":
                                                      estimatedHours,
                                                  "est_start_date":
                                                      estStartDate,
                                                  "est_end_date": estEndDate,
                                                });
                                                print(
                                                  "==================================================",
                                                );
                                                final success = await controller
                                                    .addNewTask(
                                                      token,
                                                      userId: _userId!,
                                                      description:
                                                          description ?? '',
                                                      projectId: projectId,
                                                      priorityId: priorityId,
                                                      fileBase64: fileBase64,
                                                      fileName: fileName,
                                                      assignToUserId:
                                                          assignToUserId,
                                                      assignDate: assignDate,
                                                      assignTime: assignTime,
                                                      notificationUserIds:
                                                          notificationUserIds,
                                                      estimatedHours:
                                                          estimatedHours,
                                                      estStartDate:
                                                          estStartDate,
                                                      estEndDate: estEndDate,
                                                    );
                                                setState(() {});
                                                if (success) {
                                                  Navigator.pop(context);
                                                  controller.taskNameController
                                                      .clear();
                                                  controller.resetForm();
                                                  dashboardController
                                                      .resetForm();
                                                  dashboardController
                                                      .detailsController
                                                      .clear();
                                                  dashboardController
                                                      .uploadedFile = null;
                                                  dashboardController
                                                      .selectedProjectId = null;
                                                  dashboardController
                                                      .selectedPriority = null;
                                                  dashboardController
                                                      .resetForm();

                                                  taskDetails.resetForm();
                                                  taskDetails
                                                          .selectedAssignToUserId =
                                                      null;
                                                  taskDetails.dateTimeList
                                                      .clear();
                                                  taskDetails.taggedUsers
                                                      .clear();

                                                  CustomSnackBar.successSnackBar(
                                                    context,
                                                    'Task created successfully',
                                                  );
                                                  Navigator.pushReplacementNamed(
                                                    context,
                                                    '/home',
                                                  );
                                                  await Provider.of<
                                                    OpenTaskController
                                                  >(
                                                    context,
                                                    listen: false,
                                                  ).fetchOpenTasks(
                                                    userId: _userId!,
                                                  );
                                                }
                                              }
                                              : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            controller.isSaving
                                                ? Colors.grey
                                                : AppColors.appBar,
                                        minimumSize: const Size(
                                          double.infinity,
                                          50,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                      ),
                                      child:
                                          controller.isSaving
                                              ? const Center(
                                                child: SizedBox(
                                                  height: 22,
                                                  width: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.5,
                                                      ),
                                                ),
                                              )
                                              : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: const [
                                                  Text(
                                                    'Save',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Icon(
                                                    Icons.arrow_forward,
                                                    color: Colors.white,
                                                  ),
                                                ],
                                              ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ).whenComplete(() async {
      if (_listener != null) {
        controller.taskNameController.removeListener(_listener!);
        _listener = null;
      }

      controller.taskNameController.clear();
      dashboardController.detailsController.clear();
      dashboardController.uploadedFile = null;
      dashboardController.selectedProjectId = null;
      dashboardController.selectedPriority = null;
      dashboardController.resetForm();
      taskDetails.resetForm();
      taskDetails.selectedAssignToUserId = null;
      taskDetails.dateTimeList.clear();
      taskDetails.taggedUsers.clear();
    });
  }

  void _showDescriptionBottomSheet(
    BuildContext parentContext,
    DashboardController dashboardController,
    TaskDetailController taskDetails,
  ) {
    bool isDetailsExpanded = true;
    File? _uploadedFile;

    Future<void> _pickFile() async {
      // Implement file picking logic
    }

    void _deleteFile() {
      setState(() {
        _uploadedFile = null;
      });
    }

    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: parentContext,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(sheetContext).unfocus();
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(top: 150),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Scaffold(
                backgroundColor: Colors.white,
                body: StatefulBuilder(
                  builder: (context, setModalState) {
                    return Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      'Add Task',
                                      style: GoogleFonts.lato(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                // IconButton(
                                //   onPressed: () {
                                //     Navigator.pop(context);
                                //   },
                                //   icon: const Icon(
                                //     Icons.close,
                                //     color: Colors.black,
                                //   ),
                                // ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                addDescriptionCollapse(
                                  selectedProject:
                                      dashboardController.selectedProjectName,
                                  projectList: dashboardController.projectList,
                                  onChange: (value) {
                                    final selected = dashboardController
                                        .projectList
                                        .firstWhere(
                                          (p) => p['name'] == value,
                                          orElse: () => {},
                                        );
                                    if (selected.isNotEmpty) {
                                      dashboardController.setSelectedProject(
                                        selected['id'],
                                        selected['name'],
                                      );
                                    }
                                  },
                                  onPress: () {
                                    setModalState(() {
                                      isDetailsExpanded = !isDetailsExpanded;
                                    });
                                  },
                                  isExpanded: isDetailsExpanded,
                                  title: 'Description',
                                  img: AppImages.descriptionSvg,
                                  hintText: 'Enter task description here',
                                  controller:
                                      dashboardController.detailsController,
                                  maxLines: 5,
                                  borderColor: Colors.grey.shade400,
                                  backgroundColor: Colors.white,
                                  titleColor: Colors.black,
                                  prefixIconColor: Colors.grey,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter description';
                                    }
                                    return null;
                                  },
                                  onUploadPress: () async {
                                    await showModalBottomSheet(
                                      context: context,
                                      builder:
                                          (context) => SafeArea(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ListTile(
                                                  leading: const Icon(
                                                    Icons.camera_alt,
                                                  ),
                                                  title: const Text(
                                                    'Take Photo',
                                                  ),
                                                  onTap: () async {
                                                    Navigator.pop(
                                                      context,
                                                    ); // close the sheet

                                                    final picker =
                                                        ImagePicker();
                                                    final XFile? photo =
                                                        await picker.pickImage(
                                                          source:
                                                              ImageSource
                                                                  .camera,
                                                          imageQuality: 80,
                                                        );

                                                    if (photo != null) {
                                                      final file = File(
                                                        photo.path,
                                                      );
                                                      final fileSizeMB =
                                                          file.lengthSync() /
                                                          (1024 * 1024);
                                                      if (fileSizeMB > 25) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'File size should not exceed 25 MB',
                                                            ),
                                                          ),
                                                        );
                                                        return;
                                                      }

                                                      setModalState(() {
                                                        dashboardController
                                                                .uploadedFile =
                                                            file;
                                                      });
                                                    }
                                                  },
                                                ),
                                                ListTile(
                                                  leading: const Icon(
                                                    Icons.photo_library,
                                                  ),
                                                  title: const Text(
                                                    'Choose from Gallery',
                                                  ),
                                                  onTap: () async {
                                                    Navigator.pop(context);
                                                    final file =
                                                        await dashboardController
                                                            .pickAndUploadFile(
                                                              context,
                                                            );
                                                    if (file != null) {
                                                      setModalState(() {
                                                        dashboardController
                                                                .uploadedFile =
                                                            file;
                                                      });
                                                    }
                                                  },
                                                ),
                                                ListTile(
                                                  leading: const Icon(
                                                    Icons.insert_drive_file,
                                                  ),
                                                  title: const Text(
                                                    'Choose File',
                                                  ),
                                                  onTap: () async {
                                                    Navigator.pop(context);
                                                    final file =
                                                        await dashboardController
                                                            .pickAndUploadFile(
                                                              context,
                                                            );
                                                    if (file != null) {
                                                      setModalState(() {
                                                        dashboardController
                                                                .uploadedFile =
                                                            file;
                                                      });
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                    );
                                  },
                                  uploadedFile:
                                      dashboardController.uploadedFile,
                                  onDeleteFile: () {
                                    dashboardController.deleteUploadedFile();
                                    setModalState(() {});
                                  },

                                  showCollapseIcon: false,

                                  selectedPriority:
                                      dashboardController
                                          .selectedPriority?['value'] ??
                                      '',
                                  onPriorityChange: (value) {
                                    dashboardController.selectPriority(value);
                                    setModalState(() {});
                                  },
                                  context: context,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  //
                                  final description =
                                      dashboardController
                                          .detailsController
                                          .text;
                                  final selectedProject =
                                      dashboardController.selectedProjectName;
                                  //  final selectedPriority = dashboardController.selectedPriority;
                                  final scaffoldContext = context;
                                  // Print the final selected priority before closing
                                  debugPrint(
                                    '📝 Description: ${dashboardController.detailsController.text}',
                                  );
                                  debugPrint(
                                    '🏗 Project: ${dashboardController.selectedProjectName}',
                                  );
                                  debugPrint(
                                    '❗ Priority: ${dashboardController.selectedPriority?['name']}',
                                  );
                                  if (dashboardController.uploadedFile !=
                                      null) {
                                    debugPrint(
                                      '📎 File: ${dashboardController.uploadedFile?.path}',
                                    );
                                  }
                                  if (dashboardController.selectedPriority !=
                                      null) {
                                    debugPrint('✅ Final Selected Priority:');
                                    debugPrint(
                                      '➡ ID: ${dashboardController.selectedPriority!['id']}',
                                    );
                                    debugPrint(
                                      '➡ Name: ${dashboardController.selectedPriority!['name']}',
                                    );
                                    debugPrint(
                                      '➡ Value: ${dashboardController.selectedPriority!['value']}',
                                    );
                                  }
                                  // ✅ Validation checks
                                  if (description.isEmpty) {
                                    CustomSnackBar.errorSnackBar(
                                      context,
                                      "Please enter description",
                                    );
                                    return;
                                  }

                                  if (selectedProject == null ||
                                      selectedProject.isEmpty) {
                                    CustomSnackBar.errorSnackBar(
                                      context,
                                      "Please select a project",
                                    );
                                    return;
                                  }
                                  // if (dashboardController.uploadedFile == null) {
                                  //   CustomSnackBar.errorSnackBar(context, "Please upload a file");
                                  //   return;
                                  // }

                                  if (dashboardController.selectedPriority == null) {
                                    CustomSnackBar.errorSnackBar(context, "Please select a priority");
                                    return;
                                  }
                                  Navigator.pop(context);
                                  _isDescriptionSheetOpen = false;
                                  _currentFormStep = 2;

                                  // Open the next bottom sheet after the current one is fully closed
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    _showProjectBottomSheetDate(parentContext);
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.appBar,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'Next',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    ).then((value) {
      _isDescriptionSheetOpen = false;
    });
  }

  void _showProjectBottomSheetDate(BuildContext parentContext) {
    DateTime? _rangeStart;
    DateTime? _rangeEnd;
    DateTime _focusedDay = DateTime.now();
    RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
    final _formKey = GlobalKey<FormState>();
    final taskDetail = Provider.of<TaskDetailController>(
      context,
      listen: false,
    );

    rangeEnd = null;
    selectedTime = null;
    repeatSummary = null;
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        // Initialize with existing values or defaults
        DateTime? selectedDate =
            taskDetail.dateTimeList.isNotEmpty
                ? taskDetail.dateTimeList[0].date
                : DateTime.now();

        Map<String, dynamic>? repeatData;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          behavior: HitTestBehavior.opaque,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, controller) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 8,
                  right: 8,
                  top: 16,
                  bottom:
                      MediaQuery.of(
                        context,
                      ).viewInsets.bottom, // ✅ already handling keyboard
                ),
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    void _updateRangeText() {
                      if (_rangeStart != null) {
                        if (_rangeEnd != null) {
                          // ✅ Range selection (Start + End dono select)
                          final startStr = DateFormat(
                            'MMM dd, yyyy',
                          ).format(_rangeStart!);
                          final endStr = DateFormat(
                            'MMM dd, yyyy',
                          ).format(_rangeEnd!);
                          dateRangeController.text = '$startStr - $endStr';
                          rangeStart = _rangeStart;
                          rangeEnd = _rangeEnd;
                        } else {
                          // ✅ Sirf Start Date select hui hai (End abhi null hai)
                          final dateStr = DateFormat(
                            'MMM dd, yyyy',
                          ).format(_rangeStart!);
                          dateRangeController.text = dateStr;
                          rangeStart = _rangeStart;
                          rangeEnd = null;
                        }
                      } else {
                        dateRangeController.clear();
                        rangeStart = null;
                        rangeEnd = null;
                      }
                    }

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: 50,
                        top: 16,
                        left: 16,
                        right: 16,
                      ),
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Align(
                              //   alignment: Alignment.topRight,
                              //   child: IconButton(
                              //     onPressed: () {
                              //       Navigator.pop(context);
                              //     },
                              //     icon: Icon(Icons.close),
                              //   ),
                              // ),
                              TableCalendar(
                                firstDay: DateTime(2000),
                                lastDay: DateTime(2100),
                                focusedDay: _focusedDay,
                                rangeStartDay: _rangeStart,
                                rangeEndDay: _rangeEnd,
                                rangeSelectionMode: _rangeSelectionMode,

                                onDaySelected: (selectedDay, focusedDay) {
                                  setModalState(() {
                                    _focusedDay = focusedDay;

                                    if (_rangeSelectionMode ==
                                            RangeSelectionMode.toggledOn &&
                                        _rangeStart != null &&
                                        _rangeEnd == null &&
                                        selectedDay.isAfter(_rangeStart!)) {
                                      _rangeEnd = selectedDay;
                                    } else if (_rangeStart != null &&
                                        _rangeEnd == null &&
                                        selectedDay == _rangeStart) {
                                      // 👇 User tapped same date again: treat as single-day selection
                                      _rangeEnd = selectedDay;
                                    } else {
                                      _rangeStart = selectedDay;
                                      _rangeEnd = null;
                                    }

                                    _rangeSelectionMode =
                                        RangeSelectionMode.toggledOn;
                                    _updateRangeText();
                                  });
                                },

                                headerStyle: HeaderStyle(
                                  formatButtonVisible: false,
                                  titleCentered: true,
                                ),
                                calendarStyle: CalendarStyle(
                                  selectedDecoration: BoxDecoration(
                                    color: AppColors.appBar,
                                    shape: BoxShape.circle,
                                  ),
                                  todayDecoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    shape: BoxShape.circle,
                                  ),
                                  rangeStartDecoration: BoxDecoration(
                                    color: AppColors.appBar,
                                    shape: BoxShape.circle,
                                  ),
                                  rangeEndDecoration: BoxDecoration(
                                    color: AppColors.appBar,
                                    shape: BoxShape.circle,
                                  ),
                                  withinRangeDecoration: BoxDecoration(
                                    color: AppColors.appBar.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              /// Text Field Showing Date Range
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      SvgPicture.asset(AppImages.calendarSvg),
                                      SizedBox(width: 11),
                                      Text(
                                        'Selected Range',
                                        style: GoogleFonts.lato(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: dateRangeController,
                                    readOnly: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select a date range';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      // labelText: 'Selected Range',
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          width: 0.8,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Column(
                                // task details screen
                                children: [
                                  Row(
                                    children: [
                                      SvgPicture.asset(AppImages.ClockSvg),
                                      SizedBox(width: 11),
                                      Text(
                                        'Estimated Hours',
                                        style: GoogleFonts.lato(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 7),
                                  TextFormField(
                                    controller: estimatedHoursController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 2,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter estimated hours';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      counterText: '',
                                      // suffix: Text(
                                      //   'Hours',
                                      //   style: GoogleFonts.lato(
                                      //     fontSize: 14,
                                      //     fontWeight: FontWeight.w500,
                                      //     color: Colors.black,
                                      //   ),
                                      // ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 16,
                                          ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.1),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
                                          width: 1.2,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: AppColors.appBar,
                                          width: 1.5,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                          width: 1.2,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    style: GoogleFonts.lato(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              /// Repeat field
                              // In TaskDetailsScreen.dart - Update the repeat field GestureDetector:
                              GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const RepeatsScreen(),
                                    ),
                                  );
                                  if (result != null &&
                                      result is Map<String, dynamic>) {
                                    setModalState(() {
                                      repeatData = result['data'];
                                      repeatSummary = result['summary'];
                                      print(
                                        '🌀 Repeat Data Received from RepeatsScreen:',
                                      );
                                      print(
                                        '➡ frequency: ${repeatData?['frequency']}',
                                      );
                                      print(
                                        '➡ selectedDays: ${repeatData?['selectedDays']}',
                                      );
                                      print(
                                        '➡ startsOn: ${repeatData?['startsOn']}',
                                      );
                                      print(
                                        '➡ endsOption: ${repeatData?['endsOption']}',
                                      );
                                      print(
                                        '➡ endsOnDate: ${repeatData?['endsOnDate']}',
                                      );
                                      print(
                                        '➡ occurrences: ${repeatData?['occurrences']}',
                                      );
                                      print(
                                        '📝 Repeat Summary: $repeatSummary',
                                      );
                                    });

                                    setState(() {
                                      repeatSummary = result['summary'];
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      width: 0.8,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.repeat, color: AppColors.gray),
                                      SizedBox(width: 12),
                                      if (repeatSummary != null)
                                        Text(
                                          repeatSummary ?? 'Repeat',
                                          style: GoogleFonts.lato(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      else
                                        Text(
                                          'Repeat',
                                          style: GoogleFonts.lato(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.gray,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              /// Done & Cancel buttons
                              bottomButton(
                                title: 'Next',
                                subtitle: 'Back',
                                icon: Icons.check,
                                icons: Icons.clear,

                                onPress: () {
                                  if (_formKey.currentState!.validate()) {
                                    // 🔹 Step 1: check Start Date
                                    if (rangeStart == null) {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: const Text(
                                                "Missing Information",
                                              ),
                                              content: const Text(
                                                "Please select a Start Date before proceeding.",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text("OK"),
                                                ),
                                              ],
                                            ),
                                      );
                                      return;
                                    }
                                    // 🔹 Step 2: check End Date
                                    if (rangeEnd == null) {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: const Text(
                                                "Missing Information",
                                              ),
                                              content: const Text(
                                                "Please select an End Date before proceeding.",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text("OK"),
                                                ),
                                              ],
                                            ),
                                      );
                                      return;
                                    }

                                    // ✅ Step 3: All validation passed → Save Data
                                    print("🔽 Submitted Data:");
                                    print(
                                      "📅 Start Range: ${rangeStart?.toIso8601String()}",
                                    );
                                    print(
                                      "📅 End Range: ${rangeEnd?.toIso8601String()}",
                                    );
                                    print(
                                      "⏱ Estimated Hours: ${estimatedHoursController.text}",
                                    );

                                    final dateTimeModel = TaskDateTimeModel(
                                      date: rangeStart ?? DateTime.now(),
                                      time: selectedTime,
                                      repeatText: repeatSummary,
                                      rangeStart: rangeStart,
                                      rangeEnd: rangeEnd,
                                      estimatedHours:
                                          estimatedHoursController.text,
                                    );

                                    if (taskDetail.dateTimeList.isEmpty) {
                                      taskDetail.addDateTime(dateTimeModel);
                                    } else {
                                      taskDetail.updateDateTime(
                                        0,
                                        dateTimeModel,
                                      );
                                    }
                                    //
                                    Navigator.pop(context);
                                    _isDateTimeSheetOpen = false;
                                    _currentFormStep = 3;

                                    // ✅ Open AssignTo bottom sheet after this sheet is closed
                                    Future.delayed(Duration.zero, () {
                                      _showAssignToBottomSheet(
                                        parentContext,
                                      ); // parentContext = the context of your screen
                                    });
                                  }
                                },

                                onTap: () {
                                  Navigator.pop(context);
                                  _isDateTimeSheetOpen = false;
                                  _currentFormStep = 1;
                                  _showDescriptionBottomSheet(
                                    context,
                                    dashboardController!,
                                    taskDetailController!,
                                  );
                                },
                              ),
                              SizedBox(height: 45),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    ).then((value) {
      _isDateTimeSheetOpen = false;
    });
  }

  Future<void> _showAssignToBottomSheet(BuildContext parentContext) async {
    final taskDetail = Provider.of<TaskDetailController>(
      context,
      listen: false,
    );
    final addTaskController = Provider.of<AddTaskController>(
      context,
      listen: false,
    );

    // Initialize with existing values from controller
    bool isAssignToSelf = taskDetail.selectedAssignToUserId == 'self';
    String? selectedAssignToId =
        taskDetail.selectedAssignToUserId == 'self'
            ? null
            : taskDetail.selectedAssignToUserId;
    String? selectedAssignToName =
        taskDetail.selectedAssignToUserId == 'self'
            ? null
            : taskDetail.taggedUserDetails.firstWhere(
              (user) =>
                  user['user_id'].toString() ==
                  taskDetail.selectedAssignToUserId,
              orElse: () => {},
            )['user_name'];

    List<Map<String, dynamic>> selectedTagUsers = List.from(
      taskDetail.taggedUserDetails,
    );
    List<String> selectedTagUserIds = List.from(taskDetail.taggedUsers);

    // Fetch user list
    List<Map<String, dynamic>> userList = [];
    try {
      userList = await addTaskController.fetchUserList();
    } catch (e) {
      CustomSnackBar.errorSnackBar(context, "Failed to load user list");
      return;
    }

    return showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: parentContext,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.2,
          maxChildSize: 0.8,
          builder: (_, controller) {
            return Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.1,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Scaffold(
                  body: StatefulBuilder(
                    builder: (context, setModalState) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                          top: 30,
                          left: 16,
                          right: 16,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        'Assign To',
                                        style: GoogleFonts.lato(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              CheckboxListTile(
                                value: isAssignToSelf,
                                onChanged: (value) {
                                  setModalState(() {
                                    isAssignToSelf = value ?? false;
                                    if (isAssignToSelf) {
                                      selectedAssignToId = null;
                                      selectedAssignToName = null;
                                    }
                                  });
                                },
                                title: Text(
                                  'Assign To Self',
                                  style: GoogleFonts.lato(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.black,
                                  ),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: const EdgeInsets.only(
                                  left: -30,
                                  right: 0,
                                ),
                                visualDensity: const VisualDensity(
                                  horizontal: -4,
                                  vertical: 0,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (!isAssignToSelf)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          SvgPicture.asset(
                                            AppImages.assignToSvg,
                                            color: AppColors.black,
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            'Assign To',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      DropdownSearch<Map<String, dynamic>>(
                                        items: (
                                          filter,
                                          infiniteScrollProps,
                                        ) async {
                                          return userList
                                              .where(
                                                (user) => user['user_name']
                                                    .toString()
                                                    .toLowerCase()
                                                    .contains(
                                                      filter?.toLowerCase() ??
                                                          '',
                                                    ),
                                              )
                                              .toList();
                                        },
                                        selectedItem:
                                            selectedAssignToId != null
                                                ? userList.firstWhere(
                                                  (user) =>
                                                      user['user_id']
                                                          .toString() ==
                                                      selectedAssignToId,
                                                  orElse: () => {},
                                                )
                                                : null,
                                        itemAsString:
                                            (user) => user['user_name'] ?? '',
                                        compareFn:
                                            (item, selectedItem) =>
                                                item['user_id'].toString() ==
                                                selectedItem['user_id']
                                                    .toString(),
                                        onChanged: (user) {
                                          if (user != null) {
                                            setModalState(() {
                                              selectedAssignToId =
                                                  user['user_id'].toString();
                                              selectedAssignToName =
                                                  user['user_name'];
                                            });
                                          }
                                        },
                                        key: assignedDropdownSearchKey,
                                        popupProps: PopupProps.modalBottomSheet(
                                          showSearchBox: true,
                                          constraints: BoxConstraints(
                                            maxHeight:
                                                MediaQuery.of(
                                                  context,
                                                ).size.height *
                                                0.95,
                                          ),
                                          itemBuilder: (
                                            context,
                                            item,
                                            isDisabled,
                                            isSelected,
                                          ) {
                                            final bool selected =
                                                selectedAssignToId ==
                                                item['user_id'].toString();

                                            return InkWell(
                                              onTap: () {
                                                setModalState(() {
                                                  selectedAssignToId =
                                                      item['user_id']
                                                          .toString();
                                                  selectedAssignToName =
                                                      item['user_name'];
                                                });

                                                assignedDropdownSearchKey
                                                    .currentState
                                                    ?.changeSelectedItem(item);
                                                Navigator.pop(
                                                  context,
                                                ); // Close the dropdown
                                              },
                                              child: ListTile(
                                                leading: Stack(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 22,
                                                      backgroundColor:
                                                          selected
                                                              ? Colors.blue
                                                              : Colors
                                                                  .grey
                                                                  .shade200,
                                                      child:
                                                          item['user_avatar'] ==
                                                                  null
                                                              ? Icon(
                                                                Icons.person,
                                                                color:
                                                                    selected
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .grey
                                                                            .shade400,
                                                                size: 27,
                                                              )
                                                              : null,
                                                      backgroundImage:
                                                          item['user_avatar'] !=
                                                                  null
                                                              ? NetworkImage(
                                                                item['user_avatar'],
                                                              )
                                                              : null,
                                                    ),
                                                    if (selected)
                                                      Positioned(
                                                        top: -2,
                                                        right: -2,
                                                        child: Container(
                                                          width: 16,
                                                          height: 16,
                                                          decoration:
                                                              const BoxDecoration(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
                                                              ),
                                                          child: const Icon(
                                                            Icons.check_circle,
                                                            color: Color(
                                                              0xFF1EC31A,
                                                            ),
                                                            size: 16,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                title: Text(
                                                  item['user_name'] ?? '',
                                                  style: TextStyle(
                                                    fontWeight:
                                                        selected
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                    color:
                                                        selected
                                                            ? Colors.blue
                                                            : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          searchFieldProps: TextFieldProps(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 30,
                                              horizontal: 17,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: "Search...",
                                              prefixIcon: Icon(Icons.search),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                        decoratorProps: DropDownDecoratorProps(
                                          decoration: InputDecoration(
                                            hintStyle: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w300,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            hintText: AppStrings.placeHolder,
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade400,
                                                width: 0.8,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade400,
                                                width: 0.8,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade500,
                                                width: 0.8,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 14,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 30),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          AppImages.tagUserSvg,
                                          color: AppColors.black,
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          "Tag User's for Notification",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    DropdownSearch<
                                      Map<String, dynamic>
                                    >.multiSelection(
                                      key: dropdownSearchKey,
                                      items: (filter, _) async {
                                        final filtered =
                                            userList
                                                .where(
                                                  (user) => user['user_name']
                                                      .toLowerCase()
                                                      .contains(
                                                        filter?.toLowerCase() ??
                                                            '',
                                                      ),
                                                )
                                                .toList();

                                        final selectedIds =
                                            selectedTagUsers
                                                .map(
                                                  (u) =>
                                                      u['user_id'].toString(),
                                                )
                                                .toSet();

                                        filtered.sort((a, b) {
                                          final aSelected =
                                              selectedIds.contains(
                                                    a['user_id'].toString(),
                                                  )
                                                  ? 0
                                                  : 1;
                                          final bSelected =
                                              selectedIds.contains(
                                                    b['user_id'].toString(),
                                                  )
                                                  ? 0
                                                  : 1;
                                          return aSelected.compareTo(bSelected);
                                        });

                                        return filtered;
                                      },
                                      selectedItems: selectedTagUsers,
                                      itemAsString: (user) => user['user_name'],
                                      dropdownBuilder: (
                                        context,
                                        selectedItems,
                                      ) {
                                        return Wrap(
                                          spacing: 6,
                                          children:
                                              selectedTagUsers.map((user) {
                                                return Chip(
                                                  label: Text(
                                                    user['user_name'],
                                                  ),
                                                  onDeleted: () {
                                                    setModalState(() {
                                                      selectedTagUsers.remove(
                                                        user,
                                                      );
                                                      selectedTagUserIds
                                                          .removeWhere(
                                                            (id) =>
                                                                id ==
                                                                user['user_id']
                                                                    .toString(),
                                                          );
                                                    });
                                                    dropdownSearchKey
                                                        .currentState
                                                        ?.changeSelectedItems(
                                                          selectedTagUsers,
                                                        );
                                                  },
                                                );
                                              }).toList(),
                                        );
                                      },
                                      onChanged: (
                                        List<Map<String, dynamic>> users,
                                      ) {
                                        setModalState(() {
                                          selectedTagUsers = users;
                                          selectedTagUserIds =
                                              users
                                                  .map(
                                                    (e) =>
                                                        e['user_id'].toString(),
                                                  )
                                                  .where((id) => id.isNotEmpty)
                                                  .toList();
                                        });
                                      },
                                      popupProps: PopupPropsMultiSelection.modalBottomSheet(
                                        showSearchBox: true,
                                        onItemRemoved: (
                                          selectedItems,
                                          removedItem,
                                        ) {
                                          setModalState(() {
                                            selectedTagUserIds.remove(
                                              removedItem['user_id'].toString(),
                                            );
                                            selectedTagUsers.removeWhere(
                                              (user) =>
                                                  user['user_id'].toString() ==
                                                  removedItem['user_id']
                                                      .toString(),
                                            );
                                          });
                                        },
                                        onItemAdded: (
                                          selectedItems,
                                          addedItem,
                                        ) {
                                          setModalState(() {
                                            selectedTagUserIds.add(
                                              addedItem['user_id'].toString(),
                                            );
                                            selectedTagUsers.add(addedItem);
                                          });
                                        },
                                        itemBuilder: (
                                          context,
                                          item,
                                          isDisabled,
                                          isSelected,
                                        ) {
                                          final bool selected =
                                              selectedTagUserIds.contains(
                                                item['user_id'].toString(),
                                              );

                                          return InkWell(
                                            onTap: () {
                                              setModalState(() {
                                                if (selected) {
                                                  selectedTagUsers.removeWhere(
                                                    (u) =>
                                                        u['user_id']
                                                            .toString() ==
                                                        item['user_id']
                                                            .toString(),
                                                  );
                                                  selectedTagUserIds
                                                      .removeWhere(
                                                        (id) =>
                                                            id ==
                                                            item['user_id']
                                                                .toString(),
                                                      );
                                                } else {
                                                  selectedTagUsers.add(item);
                                                  selectedTagUserIds.add(
                                                    item['user_id'].toString(),
                                                  );
                                                }
                                              });
                                              dropdownSearchKey.currentState
                                                  ?.changeSelectedItems(
                                                    selectedTagUsers,
                                                  );
                                            },
                                            child: ListTile(
                                              leading: Stack(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 22,
                                                    backgroundColor:
                                                        selected
                                                            ? Colors.blue
                                                            : Colors
                                                                .grey
                                                                .shade200,
                                                    child:
                                                        item['user_avatar'] ==
                                                                null
                                                            ? Icon(
                                                              Icons.person,
                                                              color:
                                                                  selected
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .grey
                                                                          .shade400,
                                                              size: 27,
                                                            )
                                                            : null,
                                                    backgroundImage:
                                                        item['user_avatar'] !=
                                                                null
                                                            ? NetworkImage(
                                                              item['user_avatar'],
                                                            )
                                                            : null,
                                                  ),
                                                  if (selected)
                                                    Positioned(
                                                      top: -2,
                                                      right: -2,
                                                      child: Container(
                                                        width: 16,
                                                        height: 16,
                                                        decoration:
                                                            const BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              shape:
                                                                  BoxShape
                                                                      .circle,
                                                            ),
                                                        child: const Icon(
                                                          Icons.check_circle,
                                                          color: Color(
                                                            0xFF1EC31A,
                                                          ),
                                                          size: 16,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              title: Text(
                                                item['user_name'],
                                                style: TextStyle(
                                                  fontWeight:
                                                      selected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        checkBoxBuilder:
                                            (
                                              context,
                                              item,
                                              isDisabled,
                                              isSelected,
                                            ) => const SizedBox.shrink(),
                                        containerBuilder: (
                                          context,
                                          popupWidget,
                                        ) {
                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (selectedTagUsers.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 18,
                                                      ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [],
                                                  ),
                                                ),
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 60,
                                                      ),
                                                  child: popupWidget,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                        constraints: BoxConstraints(
                                          maxHeight:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.95,
                                        ),
                                        searchFieldProps: TextFieldProps(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 30,
                                            horizontal: 17,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: "Search...",
                                            prefixIcon: const Icon(
                                              Icons.search,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                      compareFn:
                                          (item, selectedItem) =>
                                              item['user_id'].toString() ==
                                              selectedItem['user_id']
                                                  .toString(),
                                      decoratorProps: DropDownDecoratorProps(
                                        decoration: InputDecoration(
                                          hintStyle: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w300,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          hintText: AppStrings.placeHolder,
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade400,
                                              width: 0.8,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade400,
                                              width: 0.8,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade500,
                                              width: 0.8,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 14,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 35),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFFE6EEFB),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          setModalState(() {
                                            selectedTagUserIds.clear();
                                            selectedTagUsers.clear();
                                            isAssignToSelf = false;
                                            selectedAssignToId = null;
                                            selectedAssignToName = null;
                                          });
                                          dropdownSearchKey.currentState
                                              ?.changeSelectedItems([]);
                                          dropdownSearchKey.currentState
                                              ?.clear();
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Clear",
                                              style: GoogleFonts.lato(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: AppColors.gray,
                                              ),
                                            ),
                                            Icon(
                                              Icons.clear,
                                              size: 18,
                                              color: AppColors.gray,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.appBar,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                        ),
                                        onPressed: () async {
                                          final prefss = SharedPref();
                                          final userData = await prefss.read(
                                            SharedPrefConstant().kUserData,
                                          );
                                          final currentUserId =
                                              userData?['id']?.toString();

                                          // 🔹 Validation
                                          if (!isAssignToSelf &&
                                              (selectedAssignToId == null ||
                                                  selectedAssignToId!
                                                      .isEmpty)) {
                                            CustomSnackBar.errorSnackBar(
                                              context,
                                              "⚠️ Please select Assign To",
                                            );
                                            return;
                                          }
                                          // if (selectedTagUserIds.isEmpty) {
                                          //   CustomSnackBar.errorSnackBar(context, "⚠️ Please select at least one Tag User");
                                          //   return;
                                          // }

                                          // 🔹 Save to controller
                                          if (isAssignToSelf) {
                                            if (currentUserId != null) {
                                              taskDetail
                                                      .selectedAssignToUserId =
                                                  currentUserId;
                                            }
                                          } else {
                                            taskDetail.selectedAssignToUserId =
                                                selectedAssignToId;
                                          }

                                          taskDetail.taggedUsers =
                                              selectedTagUserIds;
                                          taskDetail.taggedUserDetails =
                                              selectedTagUsers;

                                          print("✅ Saved to controller:");
                                          print(
                                            "➡ Assign To: ${taskDetail.selectedAssignToUserId}",
                                          );
                                          print(
                                            "➡ Tagged Users: ${taskDetail.taggedUsers}",
                                          );
                                          print(
                                            "➡ Tagged User Details: ${taskDetail.taggedUserDetails.map((u) => u['user_name']).toList()}",
                                          );

                                          Navigator.pop(context);
                                          _isAssignToSheetOpen = false;
                                          _currentFormStep = 4;
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Apply",
                                              style: GoogleFonts.lato(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: AppColors.white,
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward,
                                              size: 18,
                                              color: AppColors.white,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((value) {
      _isAssignToSheetOpen = false;
    });
  }
}
