import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:project_management/src/open_tasks/screen/to_do_board.dart';
import 'package:project_management/src/open_tasks/widget/add%20_description_Collapse.dart';
import 'package:project_management/src/task_module/controller/task_detail_controller.dart';
import 'package:project_management/src/utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../assigned_to_team_module/screen/assigned_to_team_screen.dart';
import '../common_widgets/appbar.dart';
import '../common_widgets/common_bottom_button.dart';
import '../common_widgets/custom_drawer.dart';
import '../common_widgets/custom_snackbar.dart';
import '../completed_on_time_tasks_module/screen/completed_on_time_task.dart';
import '../deyaled_module/deyaled_screen.dart';
import '../my_task/screen/my_task_screen.dart';
import '../notifications/controller/notification_controller.dart';
import '../notifications/notifications.dart';
import '../open_tasks/controller/open_task_controller.dart';
import '../overdue_module/overdue_screen.dart';
import '../task_module/controller/add_task_controller.dart';
import '../task_module/models/task_date_time_model.dart';
import '../task_module/models/task_details_model.dart';
import '../task_module/widgets/repeats_screen.dart';
import '../utils/img.dart';
import '../utils/shared_pref_constants.dart';
import '../utils/shared_preference.dart';
import '../utils/string.dart';
import 'controller/controller.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final dropdownSearchKey =
  GlobalKey<DropdownSearchState<Map<String, dynamic>>>();
  final assignedDropdownSearchKey =
  GlobalKey<DropdownSearchState<Map<String, dynamic>>>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController dateRangeController = TextEditingController();
  final TextEditingController estimatedHoursController =
  TextEditingController();
  TextEditingController repeatDateTimeController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
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
  String? token;
  String? repeatSummary;
  Map<String, dynamic>? user;
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
    debugPrint(
      "DashboardController is ${dashboardController == null ? 'NULL' : 'NOT NULL'}",
    );
    dashboardController?.fetchProjectList();
    dashboardController?.priority();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 5, vsync: this);
    loadUserData().then((_) {
      if (user?['id'] != null) {
        // ✅ Home load hone pr hi API call
        final notificationController = Provider.of<NotificationController>(
          context,
          listen: false,
        );
        notificationController.fetchNotifications(
          userId: user!['id'].toString(),
        );
      }
    });
    _tabController.addListener(() {
      setState(() {});
    });
    _resetAllFormData();
  }

  Future<void> loadUserData() async {
    final prefs = SharedPref();
    final tokenVal = await prefs.read(SharedPrefConstant().kAuthToken);
    final userData = await prefs.read(SharedPrefConstant().kUserData);

    if (!mounted) return;  // Ensure widget is still part of the widget tree

    setState(() {
      token = tokenVal;
      user = userData;
    });

    if (taskDetailController != null) {
      userList = await taskDetailController!.userList;
      debugPrint("📌 Loaded userList: $userList");
    } else {
      debugPrint("⚠️ taskDetailController is null, cannot load userList");
    }

    debugPrint("🔑 Token----: $token");
    debugPrint("👤 Username---===: ${user?['username']}");
  }

  @override
  void dispose() {
    addTaskController?.taskNameController.clear();
    taskDetailController;
    taskDetailController;
    _projectController.dispose();
    dateRangeController.dispose();
    estimatedHoursController.dispose();
    repeatDateTimeController.dispose();

    // Then dispose of the tab controller
    _tabController.dispose();
    // Cancel any pending operations
    loadUserData();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    addTaskController?.clearDateTime();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 👇 App resume hone par yahan kaam karo
      debugPrint("📲 App resumed");
      loadUserData();
      if (user?['id'] != null) {
        final notificationController = Provider.of<NotificationController>(
          context,
          listen: false,
        );
        notificationController.fetchNotifications(
          userId: user!['id'].toString(),
        );
      }
      // setState(() {}) agar UI refresh chahiye to
    }
  }

  final List<Color> tabIndicatorColors = [
    Color(0xFF8A1DE4), // Tab 0 (Open Task)
    Color(0xFF1EBAFC), // Tab 1 (My Task)
    Color(0xFFFF1111), // Tab 2
    Color(0xFFF9A311), // Tab 3
    Color(0xFF26BC22), // Tab 4
  ];

  // Add this method to properly clear all form data
  void _resetAllFormData() {
    final dashboardController = Provider.of<DashboardController>(
      context,
      listen: false,
    );
    final taskDetails = Provider.of<TaskDetailController>(
      context,
      listen: false,
    );
    final addTaskController = Provider.of<AddTaskController>(
      context,
      listen: false,
    );

    // Clear all controllers and reset states
    addTaskController.taskNameController.clear();
    addTaskController.resetFavouriteFlag();

    dashboardController.detailsController.clear();
    dashboardController.uploadedFile = null;
    dashboardController.selectedProjectId = null;
    dashboardController.selectedProjectName = null;
    dashboardController.selectedPriority = null;

    taskDetails.selectedAssignToUserId = null;
    taskDetails.dateTimeList.clear();
    taskDetails.taggedUsers.clear();
    taskDetails.taggedUserDetails.clear();

    // Clear local controllers
    estimatedHoursController.clear();
    dateRangeController.clear();
    repeatDateTimeController.clear();

    // Reset local variables
    _rangeStart = null;
    _rangeEnd = null;
    _assignToId = null;
    _assignToName = null;
    _taggedUserIds.clear();
    _taggedUsers.clear();
    _repeatSummary = null;
    _repeatData = null;

    // Reset form step tracking
    _currentFormStep = 0;
    _isDescriptionSheetOpen = false;
    _isDateTimeSheetOpen = false;
    _isAssignToSheetOpen = false;

    debugPrint("✅ All form data reset successfully");
  }

  @override
  Widget build(BuildContext context) {
    final dashboardController = Provider.of<DashboardController>(context);
    final taskController = Provider.of<AddTaskController>(context);
    final taskDetailsController = Provider.of<TaskDetailController>(context);
    this.dashboardController ??= dashboardController;
    this.taskDetailController ??= taskDetailsController;

    if (dashboardController.projectList.isEmpty) {
      dashboardController.fetchProjectList();
    }
    if (dashboardController.priorityList.isEmpty) {
      dashboardController.priority();
    }

    return GestureDetector(
      onTap: () {
        // This will dismiss the keyboard when tapping anywhere on the screen
        FocusScope.of(context).unfocus();
      },

      child: Scaffold(
        backgroundColor: AppColors.backGroundColor,
        key: _scaffoldKey,
        drawer: CustomDrawer(),
        appBar: customAppBar(
          context,
          title: 'Home',
          scaffoldKey: _scaffoldKey,
          onAdd: () {
            debugPrint('onADDD');
            if (token != null && user?['id'] != null) {
              _showProjectBottomSheetTask(
                context,
                token,
                userId: user!['id'].toString(),
              );
            } else {
              debugPrint("❌ Token or userId is null.");
            }
            // ✅ No need to redefine token
          },
          onBell: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Notifications()),
            );
            debugPrint("Bell tapped");
          },
        ),
        body: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: AnimatedBuilder(
                animation: _tabController.animation!,
                builder: (context, _) {
                  return TabBar(
                    tabAlignment: TabAlignment.center,
                    controller: _tabController,
                    isScrollable: true,
                    padding: EdgeInsets.symmetric(
                      horizontal: 18,
                    ), // ✅ No external padding
                    labelPadding: const EdgeInsets.only(
                      right: 35,
                      bottom: 11,
                    ), // ✅ Only right padding
                    indicatorPadding: EdgeInsets.zero,
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                    dividerColor: Colors.grey.shade400,
                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(
                        width: 3,
                        color: tabIndicatorColors[_tabController.index],
                      ),
                      insets: const EdgeInsets.symmetric(horizontal: 1),
                    ),
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                    tabs: [
                      _buildTab(
                        AppImages.myTask,
                        "Open Task",
                        tabIndicatorColors[0],
                      ),
                      _buildTab(
                        AppImages.myTask,
                        "Assigned",
                        tabIndicatorColors[1],
                      ),
                      _buildTab(
                        AppImages.overdue,
                        "Overdue",
                        tabIndicatorColors[2],
                      ),
                      _buildTab(
                        AppImages.delayedSvg,
                        "Delayed",
                        tabIndicatorColors[3],
                      ),
                      _buildTab(
                        AppImages.completedSvg,
                        "Completed",
                        tabIndicatorColors[4],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TabBarView(
                controller: _tabController, // ✅ uses your controller
                children: [
                  ToDoBoard(),
                  AssignedToTeamScreen(showAppBar: false),
                  OverdueScreen(),
                  GetDelayedScreen(),
                  CompletedOnTimeTask(),
                ],
              ),
            ),
          ],
        ),
        //
      ),
    );
  }

  void showOverlayMessage(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder:
          (context) => Positioned(
        bottom: 80, // 👈 BottomSheet ke upar dikhane ke liye adjust karo
        left: 20,
        right: 20,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }

  void _showProjectBottomSheetTask(
      BuildContext context,
      String? token, {
        required String userId,
      }) {
    final rootContext = context;
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
    bool isfav = false;
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String taskName = '';
        return Consumer<AddTaskController>(
          builder: (context, controller, child) {
            bool isNameDuplicate = false;
            bool hasTaskName = false;
            return StatefulBuilder(
              builder: (context, setModalState) {
                _listener = () {
                  if (mounted) {
                    final taskName = controller.taskNameController.text;
                    setModalState(() {});
                    debugPrint("👂 Listener fired, value: $taskName");
                  }
                };
                bool isSaveEnabled = taskName.trim().isNotEmpty;

                controller.taskNameController.addListener(() {
                  taskName = controller.taskNameController.text;
                });
                return WillPopScope(
                  onWillPop: () async {
                    // Reset form when back button is pressed
                    _resetAllFormData();
                    return true;
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
                                      debugPrint("✏️ User typing: '$value'");
                                      setModalState(() {}); // 👈 force rebuild
                                    },

                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
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
                                        padding: const EdgeInsets.all(8.0),
                                        child: SvgPicture.asset(
                                          AppImages.addTaskSvg,
                                          height: 17,
                                          width: 24,
                                        ),
                                      ),
                                      contentPadding:
                                      const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 16,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        borderSide: BorderSide(
                                          color: Colors.white,
                                          width: 0.1,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  Padding(
                                    padding: const EdgeInsets.only(left: 17.0),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap:
                                          controller.taskNameController.text
                                              .trim()
                                              .length >=
                                              10
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
                                            controller
                                                .taskNameController
                                                .text
                                                .trim()
                                                .length >=
                                                10
                                                ? null
                                                : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 26),
                                        GestureDetector(
                                          onTap:
                                          controller.taskNameController.text
                                              .trim()
                                              .length >=
                                              10
                                              ? () {
                                            _currentFormStep = 2;
                                            _showProjectBottomSheetDate(
                                              context,
                                            );
                                            debugPrint('date Time...');
                                          }
                                              : null,
                                          child: SvgPicture.asset(
                                            AppImages.dateTimeSvg,
                                            width: 28,
                                            height: 28,
                                            color:
                                            controller
                                                .taskNameController
                                                .text
                                                .trim()
                                                .length >=
                                                10
                                                ? null
                                                : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 26),
                                        GestureDetector(
                                          onTap:
                                          controller.taskNameController.text
                                              .trim()
                                              .length >=
                                              10
                                              ? () {
                                            _currentFormStep = 3;
                                            _showAssignToBottomSheet(
                                              context,
                                            );
                                            debugPrint('Assign To...');
                                          }
                                              : null,
                                          child: SvgPicture.asset(
                                            AppImages.assignToSvg,
                                            width: 28,
                                            height: 28,
                                            color:
                                            controller
                                                .taskNameController
                                                .text
                                                .trim()
                                                .length >=
                                                10
                                                ? null
                                                : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 26),
                                        GestureDetector(
                                          onTap:
                                          controller.taskNameController.text
                                              .trim()
                                              .length >=
                                              10
                                              ? () {
                                            controller
                                                .toggleFavouriteFlag();
                                            setModalState(() {});
                                            debugPrint(
                                              'Favourite Value: ${controller.isFavourite ? 'Y' : 'N'}',
                                            );
                                          }
                                              : null,
                                          child: SvgPicture.asset(
                                            controller.isFavourite
                                                ? AppImages.favouriteSvg
                                                : AppImages.makeFavouriteSvg,
                                            height: 28,
                                            width: 28,
                                            color:
                                            controller
                                                .taskNameController
                                                .text
                                                .trim()
                                                .length >=
                                                10
                                                ? null
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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

                                          // Track which validation steps are needed
                                          bool
                                          needsDescriptionValidation =
                                              _isDescriptionSheetOpen ||
                                                  _currentFormStep >= 1;
                                          bool needsDateTimeValidation =
                                              _isDateTimeSheetOpen ||
                                                  _currentFormStep >= 2;
                                          bool needsAssignToValidation =
                                              _isAssignToSheetOpen ||
                                                  _currentFormStep >= 3;

                                          // ✅ Step 1: Validate Description Sheet if it was opened
                                          if (needsDescriptionValidation) {
                                            // Check if description is provided
                                            if (dashboardController
                                                .detailsController
                                                .text
                                                .trim()
                                                .isEmpty) {
                                              showOverlayMessage(
                                                rootContext,
                                                "Please enter task description",
                                              );
                                              debugPrint(
                                                "❌ Validation failed: Description is empty",
                                              );
                                              return;
                                            }
                                            // Check if project is selected
                                            if (dashboardController
                                                .selectedProjectId ==
                                                null ||
                                                dashboardController
                                                    .selectedProjectId!
                                                    .isEmpty) {
                                              showOverlayMessage(
                                                rootContext,
                                                "Please select a project",
                                              );
                                              debugPrint(
                                                "❌ Validation failed: Project not selected",
                                              );
                                              return;
                                            }
                                          }

                                          // ✅ Step 2: Validate Date/Time Sheet if it was opened
                                          if (needsDateTimeValidation) {
                                            if (taskDetails
                                                .dateTimeList
                                                .isEmpty) {
                                              showOverlayMessage(
                                                rootContext,
                                                "Please select date range and estimated hours",
                                              );
                                              debugPrint(
                                                "❌ Validation failed: Date range not selected",
                                              );
                                              return;
                                            }

                                            final dateTimeModel =
                                                taskDetails
                                                    .dateTimeList
                                                    .first;

                                            // Check if start date is selected
                                            if (dateTimeModel
                                                .rangeStart ==
                                                null) {
                                              showOverlayMessage(
                                                rootContext,
                                                "Please select start date",
                                              );
                                              debugPrint(
                                                "❌ Validation failed: Start date not selected",
                                              );
                                              return;
                                            }

                                            // Check if end date is selected
                                            if (dateTimeModel
                                                .rangeEnd ==
                                                null) {
                                              showOverlayMessage(
                                                rootContext,
                                                "Please select end date",
                                              );
                                              debugPrint(
                                                "❌ Validation failed: End date not selected",
                                              );
                                              return;
                                            }

                                            // Check if estimated hours is provided
                                            if (dateTimeModel
                                                .estimatedHours ==
                                                null ||
                                                dateTimeModel
                                                    .estimatedHours!
                                                    .trim()
                                                    .isEmpty) {
                                              showOverlayMessage(
                                                rootContext,
                                                "Please select end date",
                                              );
                                              debugPrint(
                                                "❌ Validation failed: Estimated hours not entered",
                                              );
                                              return;
                                            }
                                          }

                                          // ✅ Step 3: Validate AssignTo Sheet if it was opened
                                          if (needsAssignToValidation) {
                                            // Check if someone is assigned to the task
                                            if (taskDetails
                                                .selectedAssignToUserId ==
                                                null ||
                                                taskDetails
                                                    .selectedAssignToUserId!
                                                    .isEmpty) {
                                              showOverlayMessage(
                                                rootContext,
                                                "Please assign the task to someone",
                                              );
                                              debugPrint(
                                                "❌ Validation failed: Task not assigned to anyone",
                                              );
                                              return;
                                            }
                                          }

                                          // ✅ All validations passed, proceed with task creation
                                          debugPrint(
                                            "✅ All validations passed, creating task...",
                                          );

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
                                                dateTimeModel
                                                    .rangeStart!,
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

                                          final success = await controller.addNewTask(
                                            token,
                                            userId: userId,
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
                                            taskDetails
                                                .dateTimeList
                                                .isNotEmpty &&
                                                taskDetails
                                                    .dateTimeList
                                                    .first
                                                    .rangeStart !=
                                                    null
                                                ? DateFormat(
                                              'yyyy-MM-dd',
                                            ).format(
                                              taskDetails
                                                  .dateTimeList
                                                  .first
                                                  .rangeStart!,
                                            )
                                                : null,
                                            estEndDate:
                                            taskDetails
                                                .dateTimeList
                                                .isNotEmpty &&
                                                taskDetails
                                                    .dateTimeList
                                                    .first
                                                    .rangeEnd !=
                                                    null
                                                ? DateFormat(
                                              'yyyy-MM-dd',
                                            ).format(
                                              taskDetails
                                                  .dateTimeList
                                                  .first
                                                  .rangeEnd!,
                                            )
                                                : null,
                                          );

                                          if (success) {
                                            Navigator.pop(context);

                                            // Reset all form data after successful task creation
                                            _resetAllFormData();

                                            CustomSnackBar.successSnackBar(
                                              context,
                                              'Task created successfully',
                                            );

                                            await Provider.of<
                                                OpenTaskController
                                            >(
                                              context,
                                              listen: false,
                                            ).fetchOpenTasks(
                                              userId: userId!,
                                            );
                                            setState(() {});
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

                                  const SizedBox(height: 45),
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
            );
          },
        );
      },
    ).whenComplete(() {
      // Reset form when bottom sheet is closed
      _resetAllFormData();

      if (_listener != null) {
        controller.taskNameController.removeListener(_listener!);
        _listener = null;
      }
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                                              title: const Text('Take Photo'),
                                              onTap: () async {
                                                Navigator.pop(
                                                  context,
                                                ); // close the sheet

                                                final picker = ImagePicker();
                                                final XFile? photo =
                                                await picker.pickImage(
                                                  source:
                                                  ImageSource.camera,
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
                                                        .uploadedFile = file;
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
                                                        .uploadedFile = file;
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
                                                        .uploadedFile = file;
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  uploadedFile: dashboardController.uploadedFile,
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
                                      dashboardController.detailsController.text;
                                  final selectedProject =
                                      dashboardController.selectedProjectName;
                                  //  final selectedPriority = dashboardController.selectedPriority;
                                  final scaffoldContext = context;
                                  // debugPrint the final selected priority before closing
                                  debugPrint(
                                    '📝 Description: ${dashboardController.detailsController.text}',
                                  );
                                  debugPrint(
                                    '🏗 Project: ${dashboardController.selectedProjectName}',
                                  );
                                  debugPrint(
                                    '❗ Priority: ${dashboardController.selectedPriority?['name']}',
                                  );
                                  if (dashboardController.uploadedFile != null) {
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
                                      debugPrint(
                                        '🌀 Repeat Data Received from RepeatsScreen:',
                                      );
                                      debugPrint(
                                        '➡ frequency: ${repeatData?['frequency']}',
                                      );
                                      debugPrint(
                                        '➡ selectedDays: ${repeatData?['selectedDays']}',
                                      );
                                      debugPrint(
                                        '➡ startsOn: ${repeatData?['startsOn']}',
                                      );
                                      debugPrint(
                                        '➡ endsOption: ${repeatData?['endsOption']}',
                                      );
                                      debugPrint(
                                        '➡ endsOnDate: ${repeatData?['endsOnDate']}',
                                      );
                                      debugPrint(
                                        '➡ occurrences: ${repeatData?['occurrences']}',
                                      );
                                      debugPrint(
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
                                    debugPrint("🔽 Submitted Data:");
                                    debugPrint(
                                      "📅 Start Range: ${rangeStart?.toIso8601String()}",
                                    );
                                    debugPrint(
                                      "📅 End Range: ${rangeEnd?.toIso8601String()}",
                                    );
                                    debugPrint(
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
                                      _showAssignToBottomSheet(parentContext);
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
    String? selectedAssignToId = taskDetail.selectedAssignToUserId == 'self'
        ? null
        : taskDetail.selectedAssignToUserId;
    String? selectedAssignToName = taskDetail.selectedAssignToUserId == 'self'
        ? null
        : taskDetail.taggedUserDetails.firstWhere(
          (user) => user['user_id'].toString() == taskDetail.selectedAssignToUserId,
      orElse: () => {},
    )['user_name'];

    List<Map<String, dynamic>> selectedTagUsers = List.from(taskDetail.taggedUserDetails);
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
                                  controlAffinity: ListTileControlAffinity.leading,
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                          selectedItem: selectedAssignToId != null
                                              ? userList.firstWhere(
                                                (user) =>
                                            user['user_id'].toString() ==
                                                selectedAssignToId,
                                            orElse: () => {},
                                          )
                                              : null,
                                          itemAsString: (user) => user['user_name'] ?? '',
                                          compareFn: (item, selectedItem) =>
                                          item['user_id'].toString() ==
                                              selectedItem['user_id'].toString(),
                                          onChanged: (user) {
                                            if (user != null) {
                                              setModalState(() {
                                                selectedAssignToId = user['user_id'].toString();
                                                selectedAssignToName = user['user_name'];
                                              });
                                            }
                                          },
                                          key: assignedDropdownSearchKey,
                                          popupProps: PopupProps.modalBottomSheet(
                                            showSearchBox: true,
                                            constraints: BoxConstraints(
                                              maxHeight: MediaQuery.of(context).size.height * 0.95,
                                            ),
                                            itemBuilder: (
                                                context,
                                                item,
                                                isDisabled,
                                                isSelected,
                                                ) {
                                              final bool selected = selectedAssignToId == item['user_id'].toString();

                                              return InkWell(
                                                onTap: () {
                                                  setModalState(() {
                                                    selectedAssignToId = item['user_id'].toString();
                                                    selectedAssignToName = item['user_name'];
                                                  });

                                                  assignedDropdownSearchKey.currentState?.changeSelectedItem(item);
                                                  Navigator.pop(context); // Close the dropdown
                                                },
                                                child: ListTile(
                                                  leading: Stack(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 22,
                                                        backgroundColor: selected ? Colors.blue : Colors.grey.shade200,
                                                        child: item['user_avatar'] == null
                                                            ? Icon(
                                                          Icons.person,
                                                          color: selected ? Colors.white : Colors.grey.shade400,
                                                          size: 27,
                                                        )
                                                            : null,
                                                        backgroundImage: item['user_avatar'] != null
                                                            ? NetworkImage(item['user_avatar'])
                                                            : null,
                                                      ),
                                                      if (selected)
                                                        Positioned(
                                                          top: -2,
                                                          right: -2,
                                                          child: Container(
                                                            width: 16,
                                                            height: 16,
                                                            decoration: const BoxDecoration(
                                                              color: Colors.white,
                                                              shape: BoxShape.circle,
                                                            ),
                                                            child: const Icon(
                                                              Icons.check_circle,
                                                              color: Color(0xFF1EC31A),
                                                              size: 16,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  title: Text(
                                                    item['user_name'] ?? '',
                                                    style: TextStyle(
                                                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                                      color: selected ? Colors.blue : Colors.black,
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
                                                  borderRadius: BorderRadius.circular(10),
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
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade400,
                                                  width: 0.8,
                                                ),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade500,
                                                  width: 0.8,
                                                ),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(
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

                                      DropdownSearch<Map<String, dynamic>>.multiSelection(
                                        key: dropdownSearchKey,
                                        items: (filter, _) async {
                                          final filtered = userList
                                              .where(
                                                (user) => user['user_name']
                                                .toLowerCase()
                                                .contains(
                                              filter?.toLowerCase() ?? '',
                                            ),
                                          )
                                              .toList();

                                          final selectedIds = selectedTagUsers
                                              .map((u) => u['user_id'].toString())
                                              .toSet();

                                          filtered.sort((a, b) {
                                            final aSelected = selectedIds.contains(a['user_id'].toString()) ? 0 : 1;
                                            final bSelected = selectedIds.contains(b['user_id'].toString()) ? 0 : 1;
                                            return aSelected.compareTo(bSelected);
                                          });

                                          return filtered;
                                        },
                                        selectedItems: selectedTagUsers,
                                        itemAsString: (user) => user['user_name'],
                                        dropdownBuilder: (context, selectedItems) {
                                          return Wrap(
                                            spacing: 6,
                                            children: selectedTagUsers.map((user) {
                                              return Chip(
                                                label: Text(user['user_name']),
                                                onDeleted: () {
                                                  setModalState(() {
                                                    selectedTagUsers.remove(user);
                                                    selectedTagUserIds.removeWhere(
                                                          (id) => id == user['user_id'].toString(),
                                                    );
                                                  });
                                                  dropdownSearchKey.currentState?.changeSelectedItems(selectedTagUsers);
                                                },
                                              );
                                            }).toList(),
                                          );
                                        },
                                        onChanged: (List<Map<String, dynamic>> users) {
                                          setModalState(() {
                                            selectedTagUsers = users;
                                            selectedTagUserIds = users
                                                .map((e) => e['user_id'].toString())
                                                .where((id) => id.isNotEmpty)
                                                .toList();
                                          });
                                        },
                                        popupProps: PopupPropsMultiSelection.modalBottomSheet(
                                          showSearchBox: true,
                                          onItemRemoved: (selectedItems, removedItem) {
                                            setModalState(() {
                                              selectedTagUserIds.remove(removedItem['user_id'].toString());
                                              selectedTagUsers.removeWhere(
                                                    (user) => user['user_id'].toString() == removedItem['user_id'].toString(),
                                              );
                                            });
                                          },
                                          onItemAdded: (selectedItems, addedItem) {
                                            setModalState(() {
                                              selectedTagUserIds.add(addedItem['user_id'].toString());
                                              selectedTagUsers.add(addedItem);
                                            });
                                          },
                                          itemBuilder: (context, item, isDisabled, isSelected) {
                                            final bool selected = selectedTagUserIds.contains(item['user_id'].toString());

                                            return InkWell(
                                              onTap: () {
                                                setModalState(() {
                                                  if (selected) {
                                                    selectedTagUsers.removeWhere(
                                                          (u) => u['user_id'].toString() == item['user_id'].toString(),
                                                    );
                                                    selectedTagUserIds.removeWhere(
                                                          (id) => id == item['user_id'].toString(),
                                                    );
                                                  } else {
                                                    selectedTagUsers.add(item);
                                                    selectedTagUserIds.add(item['user_id'].toString());
                                                  }
                                                });
                                                dropdownSearchKey.currentState?.changeSelectedItems(selectedTagUsers);
                                              },
                                              child: ListTile(
                                                leading: Stack(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 22,
                                                      backgroundColor: selected ? Colors.blue : Colors.grey.shade200,
                                                      child: item['user_avatar'] == null
                                                          ? Icon(
                                                        Icons.person,
                                                        color: selected ? Colors.white : Colors.grey.shade400,
                                                        size: 27,
                                                      )
                                                          : null,
                                                      backgroundImage: item['user_avatar'] != null
                                                          ? NetworkImage(item['user_avatar'])
                                                          : null,
                                                    ),
                                                    if (selected)
                                                      Positioned(
                                                        top: -2,
                                                        right: -2,
                                                        child: Container(
                                                          width: 16,
                                                          height: 16,
                                                          decoration: const BoxDecoration(
                                                            color: Colors.white,
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: const Icon(
                                                            Icons.check_circle,
                                                            color: Color(0xFF1EC31A),
                                                            size: 16,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                title: Text(
                                                  item['user_name'],
                                                  style: TextStyle(
                                                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          checkBoxBuilder: (context, item, isDisabled, isSelected) => const SizedBox.shrink(),
                                          containerBuilder: (context, popupWidget) {
                                            return Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (selectedTagUsers.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 18,
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [],
                                                    ),
                                                  ),
                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(bottom: 60),
                                                    child: popupWidget,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                          constraints: BoxConstraints(
                                            maxHeight: MediaQuery.of(context).size.height * 0.95,
                                          ),
                                          searchFieldProps: TextFieldProps(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 30,
                                              horizontal: 17,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: "Search...",
                                              prefixIcon: const Icon(Icons.search),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                        compareFn: (item, selectedItem) =>
                                        item['user_id'].toString() == selectedItem['user_id'].toString(),
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
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade400,
                                                width: 0.8,
                                              ),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade500,
                                                width: 0.8,
                                              ),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
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
                                              borderRadius: BorderRadius.circular(30),
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
                                            dropdownSearchKey.currentState?.changeSelectedItems([]);
                                            dropdownSearchKey.currentState?.clear();
                                          },
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                          ),
                                          onPressed: () async {
                                            final prefss = SharedPref();
                                            final userData = await prefss.read(SharedPrefConstant().kUserData);
                                            final currentUserId = userData?['id']?.toString();

                                            // 🔹 Validation
                                            if (!isAssignToSelf && (selectedAssignToId == null || selectedAssignToId!.isEmpty)) {
                                              CustomSnackBar.errorSnackBar(context, "⚠️ Please select Assign To");
                                              return;
                                            }

                                            // 🔹 Save to controller
                                            if (isAssignToSelf) {
                                              if (currentUserId != null) {
                                                taskDetail.selectedAssignToUserId = currentUserId;
                                              }
                                            } else {
                                              taskDetail.selectedAssignToUserId = selectedAssignToId;
                                            }

                                            taskDetail.taggedUsers = selectedTagUserIds;
                                            taskDetail.taggedUserDetails = selectedTagUsers;

                                            debugPrint("✅ Saved to controller:");
                                            debugPrint("➡ Assign To: ${taskDetail.selectedAssignToUserId}");
                                            debugPrint("➡ Tagged Users: ${taskDetail.taggedUsers}");
                                            debugPrint("➡ Tagged User Details: ${taskDetail.taggedUserDetails.map((u) => u['user_name']).toList()}");

                                            Navigator.pop(context);
                                            _isAssignToSheetOpen = false;
                                            _currentFormStep = 4;
                                          },
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        }).then((value) {
      _isAssignToSheetOpen = false;
    });
  }
}

Widget _buildTab(String iconPath, String label, Color color) {
  return Tab(
    child: Builder(
      builder: (context) {
        final scale = MediaQuery.of(context).textScaleFactor;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(iconPath, height: 24, width: 24, color: color),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 80),
              child: AutoSizeText(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                minFontSize: 8,
                overflow: TextOverflow.ellipsis,
                stepGranularity: 1,
                group: AutoSizeGroup(),
              ),
            ),
          ],
        );
      },
    ),
  );
}