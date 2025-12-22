import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../common_widgets/add_details_collapse.dart';
import '../../common_widgets/appbar.dart';
import '../../common_widgets/common_bottom_button.dart';
import '../../common_widgets/common_text_lable_field.dart';
import '../../common_widgets/custom_snackbar.dart';
import '../../common_widgets/lodar.dart';
import '../../utils/colors.dart';
import '../../utils/img.dart';
import '../../utils/no_internet_connectivity.dart';
import '../../utils/shared_pref_constants.dart';
import '../../utils/shared_preference.dart';
import '../../utils/string.dart';
import '../controller/task_detail_controller.dart';
import '../models/task_date_time_model.dart';
import '../models/task_details_model.dart';
import '../widgets/assign_widget.dart';
import '../widgets/repeats_screen.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskName;
  final String taskId;
  final TaskDetailsModel? task;

  const TaskDetailsScreen({
    Key? key,
    required this.taskName,
    required this.taskId,
    this.task,
  }) : super(key: key);

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late TextEditingController taskNameController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isFavourite = false;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? repeatText;
  DateTime? fromDate;
  DateTime? toDate;
  bool isDetailsExpanded = false;
  final Connectivity _connectivity = Connectivity();
  bool _isNetworkAvailable = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool isLoading = false;
  DateTime? rangeStart;
  DateTime? rangeEnd;
  DateTime focusedDay = DateTime.now();
  bool isAssignToSelf = false;
  String? selectedAssignToId;
  String? selectedAssignToName;
  // String? selectedTagUserIds;

  // 🔧 Old single user tagging
  String? selectedTagUserId;
  String? selectedTagUserName;

  // ✅ Add these for multi-tag support
  List<Map<String, dynamic>> selectedTagUsers = [];
  List<String> selectedTagUserIds = [];
  final TextEditingController dateRangeController = TextEditingController();
  final TextEditingController estimatedHoursController =
  TextEditingController();
  TextEditingController repeatDateTimeController = TextEditingController();

  File? _uploadedFile;
  bool? isAssignToExpanded = false;

  List<Map<String, dynamic>> userList = [];
  List<Map<String, dynamic>> projectList = [];

  var filtered = [];

  List<String> projectNames = [];
  List<String> userNames = [];
  String? selectedProject;
  String? repeatSummary;
  bool _isProjectSelected = false;
  bool _isPrioritySelected = false;
  bool _hasDateTime = false;
  bool _isAssignedToSelected = false;
  bool _hasEstimatedHours = false;
  // TaskDetailController? taskDetailController;
  late final TaskDetailController taskDetailController;

  bool isUserSelected = false;

  bool isExpanded = false;
  String? filter;
  final TextEditingController _searchController = TextEditingController();
  Set<String> selectedUserIds = {};

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final prefss = SharedPref();
    final tokenVal = await prefss.read(SharedPrefConstant().kAuthToken);
    final userData = await prefss.read(SharedPrefConstant().kUserData);
    // debugPrint('user token : $tokenVal');
    return prefs.getString('auth_token'); // Use the same key used during saving
  }

  Future<void> _pickFile() async {
    final result = await showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take Photo'),
              onTap: () {
                Navigator.pop(context, 'camera');
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context, 'gallery');
              },
            ),
            ListTile(
              leading: Icon(Icons.insert_drive_file),
              title: Text('Choose File'),
              onTap: () {
                Navigator.pop(context, 'file');
              },
            ),
          ],
        ),
      ),
    );

    if (result == 'camera') {
      await _takePhoto();
    } else if (result == 'gallery') {
      await _pickFromGallery();
    } else if (result == 'file') {
      await _pickDocument();
    }
  }

  Future<void> _takePhoto() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (pickedFile != null) {
        await _validateAndSetFile(File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      CustomSnackBar.errorSnackBar(context, 'Failed to take photo');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (pickedFile != null) {
        await _validateAndSetFile(File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      CustomSnackBar.errorSnackBar(
        context,
        'Failed to pick image from gallery',
      );
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowCompression: true,
      );

      if (result != null && result.files.single.path != null) {
        await _validateAndSetFile(File(result.files.single.path!));
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
      CustomSnackBar.errorSnackBar(context, 'Failed to pick file');
    }
  }

  Future<void> _validateAndSetFile(File file) async {
    try {
      // Check file size (25MB limit)
      final fileSize = await file.length();
      const maxSize = 25 * 1024 * 1024; // 25MB in bytes

      if (fileSize > maxSize) {
        CustomSnackBar.errorSnackBar(
          context,
          'File size exceeds 25MB limit. Please choose a smaller file.',
        );
        return;
      }

      // If file is within size limit, set it
      setState(() {
        _uploadedFile = file;
      });
    } catch (e) {
      debugPrint('Error validating file: $e');
      CustomSnackBar.errorSnackBar(context, 'Error processing file');
    }
  }

  void _deleteFile() {
    setState(() {
      _uploadedFile = null;
    });
  }

  @override
  void initState() {
    super.initState();
    taskDetailController = Provider.of<TaskDetailController>(
      context,
      listen: false,
    );
    taskNameController = TextEditingController(text: widget.taskName);
    taskDetailController.loadCurrentUserId();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    // Initialize with task data if available
    if (widget.task != null) {
      isFavourite = widget.task?.favoriteFlag == "Y";
      taskDetailController.detailsController.text =
          widget.task?.taskDetail ?? '';
      taskDetailController.selectedProjectId =
          widget.task?.projectName?.toString();
      taskDetailController.selectedPriority =
      widget.task?.priorityLookupdet != null
          ? {
        'id': widget.task?.priorityLookupdet,
        'name': widget.task?.priorityLookupdet,
      }
          : null;

      // Initialize date/time if available
      _updateValidationFlags();
    }
    if (widget.task != null) {
      _initializeWithTaskData(widget.task!);
    }
    _initializeData();
    _printPriorityDetails();
    _loadData();
    taskDetailController.loadCurrentUserId();
  }

  void _updateValidationFlags() {
    final taskDetails = Provider.of<TaskDetailController>(
      context,
      listen: false,
    );

    setState(() {
      _isProjectSelected = taskDetails.selectedProjectId != null;
      _isPrioritySelected = taskDetails.selectedPriority != null;
      _hasDateTime = taskDetails.dateTimeList.isNotEmpty;
      _isAssignedToSelected = taskDetails.selectedAssignToUserId != null;
      _hasEstimatedHours = estimatedHoursController.text.isNotEmpty;
    });
  }

  void _initializeWithTaskData(TaskDetailsModel task) {
    final taskDetails = Provider.of<TaskDetailController>(
      context,
      listen: false,
    );

    setState(() {
      // Basic fields
      isFavourite = task.favoriteFlag == "Y";
      taskDetails.detailsController.text = task.taskDetail ?? '';
      // Estimated hours
      if (task.estHrs != null) {
        estimatedHoursController.text = task.estHrs.toString();
      }

      // Date range
      if (task.estStartDate != null) {
        rangeStart = DateTime.parse(task.estStartDate!);
      }
      if (task.estEndDate != null) {
        rangeEnd = DateTime.parse(task.estEndDate!);
      }
      // Project
      if (task.projectName != null) {
        final project = taskDetails.projectList.firstWhere(
              (p) => p['id'].toString() == task.projectName.toString(),
          orElse: () => {},
        );
        if (project.isNotEmpty) {
          taskDetails.setSelectedProject(
            project['id']?.toString(),
            project['name'],
          );
        }
      }

      // Priority
      if (task.priorityLookupdet != null) {
        final priority = taskDetails.priorityList.firstWhere(
              (p) => p['id'].toString() == task.priorityLookupdet.toString(),
          orElse: () => {},
        );
        if (priority.isNotEmpty) {
          taskDetails.setSelectedPriority(priority);
        }
      }

      // Date/Time
      if (task.assignDate != null) {
        try {
          final date = DateTime.parse(task.assignDate!);
          TimeOfDay? time;

          if (task.assignTime != null) {
            final parts = task.assignTime!.split(':');
            time = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }

          taskDetails.dateTimeList = [
            TaskDateTimeModel(
              date: date,
              time: time,
              repeatText: task.repeatText,
              repeatData: task.repeatData,
            ),
          ];
        } catch (e) {
          debugPrint('Error parsing date/time: $e');
        }
      }

      // Assigned user
      if (task.assignedTo != null) {
        final user = taskDetails.userList.firstWhere(
              (u) => u['user_id'].toString() == task.assignedTo.toString(),
          orElse: () => {},
        );
        if (user.isNotEmpty) {
          taskDetails.setAssignToUser(user['user_id'].toString());
          taskDetails.selectedAssignToUserName = user['user_name'];
        }
      }

      // Tagged users
      if (task.taggedUsers != null && task.taggedUsers!.isNotEmpty) {
        taskDetails.taggedUsers =
            task.taggedUsers!.map((user) => user.id.toString()).toList();

        taskDetails.taggedUserDetails =
            task.taggedUsers!
                .map(
                  (user) => {
                'user_id': user.id,
                'user_name': user.name ?? 'Unknown',
              },
            )
                .toList();
      }

      // File attachment
      if (task.taskDocs != null && task.taskDocs!.isNotEmpty) {
        // You would need to implement file download logic here
        // This is just a placeholder
        // _uploadedFile = File(task.taskDocs!);
      }
    });
  }

  Future<void> _loadData() async {
    try {
      await taskDetailController!.fetchProjectList();
      await taskDetailController!.fetchUserList();
      await taskDetailController!.priority();
      // Fetching data
      final projects = await taskDetailController!.fetchProjectList();
      final users = await taskDetailController!.fetchUserList();
      final priorities = await taskDetailController!.priority();

      if (widget.task != null) {
        _initializeWithTaskData(widget.task!);
      }
      debugPrint('ℹ️ Priority Details from API:');
      priorities.forEach((priority) {
        debugPrint(
          '➡ ID: ${priority['id']}, Name: ${priority['name']}, Value: ${priority['value']}',
        );
      });
      // Updating the controller state
      setState(() {
        taskDetailController!.projectList =
            projects; // Corrected from projectData
        taskDetailController!.priorityList = priorities;

        userList = users;

        // Map to string lists for dropdowns etc.
        projectNames = projects.map((p) => p['name'].toString() ?? '').toList();
        userNames = users.map((u) => u['user_name']?.toString() ?? '').toList();
      });

      filtered =
          userList.where((user) {
            final name = user['user_name']?.toLowerCase() ?? '';
            return name.contains(filter?.toLowerCase() ?? '');
          }).toList();

      debugPrint('📦 Project Names: $projectNames');
      debugPrint('👥 User Names: $userNames');
      debugPrint('🧪 Raw Users List: $users');
    } catch (e) {
      debugPrint('❌ Failed to load project or user data: $e');
    }
  }

  Future<void> _initializeData() async {
    final prefss = SharedPref();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = await prefss.read(SharedPrefConstant().kAuthToken);
    final userData = await prefss.read(SharedPrefConstant().kAuthToken);

    if (userData != null && userData is Map) {
      final userId = userData['id']?.toString();
      debugPrint('user ID---====--> : $userId');
    }

    debugPrint('user token-- : $token');
    var _userId = userData['id']?.toString();

    debugPrint('user ID---====--> : $_userId');
    try {
      final controller = Provider.of<TaskDetailController>(
        context,
        listen: false,
      );
      // Load initial data if editing existing task
      if (widget.task != null && token != null) {
        await controller.fetchTaskDetails(widget.taskId, token);
      }

      // Fetch dropdown options
      await Future.wait([
        controller.fetchProjectList(),
        controller.fetchUserList(),
      ]);
    } catch (e) {
      debugPrint('Initialization error: $e');
      CustomSnackBar.errorSnackBar(context, 'Failed to load task data');
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

  void _toggleFavourite() {
    setState(() {
      isFavourite = !isFavourite;
    });
  }

  Future<void> _printPriorityDetails() async {
    try {
      final priorities = await taskDetailController!.priority();
      debugPrint('ℹ️ Priority Details from API:');
      priorities.forEach((priority) {
        debugPrint(
          '➡ ID: ${priority['id']}, Name: ${priority['name']}, Value: ${priority['value']}',
        );
      });
    } catch (e) {
      debugPrint('❌ Error printing priority details: $e');
    }
  }

  @override
  void dispose() {
    taskNameController.dispose();
    _connectivitySubscription?.cancel();
    taskDetailController.clearAllData();
    super.dispose();
  }

  void _clearFormData() {
    final taskDetails = Provider.of<TaskDetailController>(
      context,
      listen: false,
    );

    // Clear controllers
    taskDetails.detailsController.clear();
    estimatedHoursController.clear();
    dateRangeController.clear();

    // Reset dropdown selections
    taskDetails.selectedProjectId = null;
    taskDetails.selectedProjectName = null;
    taskDetails.selectedPriority = null;
    taskDetails.selectedAssignToUserId = null;
    taskDetails.selectedAssignToUserName = null;
    taskDetails.taggedUsers.clear();
    taskDetails.taggedUserDetails.clear();
    taskDetails.dateTimeList.clear();
    // Reset date range
    setState(() {
      rangeStart = null;
      rangeEnd = null;
    });
    // Reset file upload
    setState(() {
      _uploadedFile = null;
      isFavourite = false;
      selectedTime = null;
      selectedDate = null;
      repeatText = null;
      isDetailsExpanded = false;
    });

    // Reset form state
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Task Details Screen ---:');
    final taskDetails = Provider.of<TaskDetailController>(context);
    debugPrint('Task Id ---: ${widget.taskId.toString()}');
    debugPrint('Task Name ---: ${widget.taskName.toString()}');
    return _isNetworkAvailable
        ? GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: customAppBar(context, title: 'Task Details', showBack: true),
        body: Stack(
          children: [
            SingleChildScrollView(
              // padding: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Container(
                      width:
                      MediaQuery.of(
                        context,
                      ).size.width, // ✅ ensures full screen width
                      decoration: BoxDecoration(
                        color: Color(0xffffffff),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11.0,
                          vertical: 17,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      AppImages.addTaskSvg,
                                      width: 23,
                                      height: 23,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppStrings.taskName,
                                      style: GoogleFonts.lato(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              textLabelFormField(
                                readOnly: true,
                                controller: taskNameController,
                                // img: AppImages.addTaskSvg,
                                taskName: 'Task Name',
                                hintText: 'Enter task here',
                                onChanged: (value) {
                                  debugPrint('Task changed: $value');
                                },
                                borderColor: Colors.grey.shade400,
                                prefixIconColor: Colors.black,
                                backgroundColor: Colors.white,
                              ),
                              SizedBox(height: 26),
                              addDetailsCollapse(
                                selectedProject:
                                taskDetails.selectedProjectName,
                                //selectedProject: selectedProject,
                                projectList:
                                taskDetails.projectList
                                    .map((p) => p['name'] as String)
                                    .toList(),
                                onChange: (value) {
                                  final selected = taskDetails.projectList
                                      .firstWhere(
                                        (p) => p['name'] == value,
                                    orElse: () => {},
                                  );
                                  if (selected.isNotEmpty) {
                                    taskDetails.setSelectedProject(
                                      selected['id']?.toString(),
                                      selected['name'],
                                    );
                                  }
                                },
                                onPress: () {
                                  setState(() {
                                    isDetailsExpanded = !isDetailsExpanded;
                                  });
                                },
                                prefixIconImage: AppImages.descriptionSvg,
                                isExpanded: isDetailsExpanded,
                                title: 'Add Details',
                                img: AppImages.descriptionSvg,
                                hintText: 'Add details here',
                                controller: taskDetails.detailsController,
                                maxLines: 3,
                                borderColor: Colors.grey,
                                backgroundColor: Colors.white,
                                titleColor: Colors.black,
                                prefixIconColor: Colors.grey,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter details';
                                  }
                                  // final wordCount = RegExp(r'\b\w+\b').allMatches(value.trim()).length;
                                  //
                                  // if (wordCount < 10) {
                                  //   return 'Please enter at least 10 words';
                                  // }
                                  return null;
                                },
                                projectNameController: taskNameController,
                                onUploadPress: _pickFile,
                                uploadedFile: _uploadedFile,
                                onDeleteFile: _deleteFile,
                                showCollapseIcon: false,
                                // Update the addDetailsCollapse widget's onPriorityChange:
                                selectedPriority:
                                taskDetails.selectedPriority?['name'] ??
                                    '',
                                onPriorityChange: (value) {
                                  final selected = taskDetails.priorityList
                                      .firstWhere(
                                        (p) => p['name'] == value,
                                    orElse: () => {},
                                  );
                                  if (selected.isNotEmpty) {
                                    taskDetails.setSelectedPriority(selected);
                                  }
                                },
                              ),
                              // Divider(),
                              SizedBox(height: 11),

                              ///Add Date/Time
                              GestureDetector(
                                onTap:() {
                                  _showProjectBottomSheet(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        AppImages.dateTimeSvg,
                                        width: 22,
                                        height: 22,
                                        fit: BoxFit.cover,
                                        color: AppColors.black,
                                      ),
                                      SizedBox(width: 12),
                                      if (taskDetails.dateTimeList.isEmpty)
                                        Text(
                                          AppStrings.addDateTime,
                                          style: GoogleFonts.lato(
                                            color: AppColors.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )
                                      else
                                        Expanded(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              // spacing: 9, runSpacing: 8,
                                              children:
                                              taskDetails.dateTimeList.map((
                                                  data,
                                                  ) {
                                                return Container(
                                                  padding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 11,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.white,
                                                    border: Border.all(
                                                      color: AppColors.gray
                                                          .withOpacity(0.7),
                                                    ),
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                      16,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                    MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        data.formattedDateTime(
                                                          context,
                                                        ),
                                                        style:GoogleFonts.lato(
                                                          color:
                                                          AppColors
                                                              .black,
                                                          fontSize: 14,
                                                          fontWeight:
                                                          FontWeight
                                                              .w500,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      GestureDetector(
                                                        onTap: () {
                                                          setState((){
                                                            taskDetails
                                                                .dateTimeList
                                                                .remove(data);
                                                          });
                                                        },
                                                        child: Icon(
                                                          Icons.close,
                                                          size: 16,
                                                          color:
                                                          AppColors.gray,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              // SizedBox(height: 11),
                              // Divider(),
                              SizedBox(height: 18),

                              /// Assign To
                              assignToUser(
                                context,
                                taskDetail: taskDetails,
                                showCollapseIcon: false,
                                onAssignToTap: () {
                                  _showAssignToBottomSheet(
                                    context,
                                    taskDetails,
                                  );
                                  setState(
                                        () {},
                                  );
                                },
                                onTagUserUpdated:() {
                                  setState(
                                        () {},
                                  ); // or any custom logic to refresh UI
                                },
                              ),
                              SizedBox(height: 20),

                              /// Add to Favorite
                              GestureDetector(
                                onTap: _toggleFavourite,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isFavourite
                                            ? Icons.star
                                            : Icons.star_border,
                                        color:
                                        isFavourite
                                            ? Colors.red
                                            : Colors.black,
                                        size: 22,
                                      ),

                                      SizedBox(width: 12),
                                      Text(
                                        AppStrings.addToFavorite,
                                        style: GoogleFonts.lato(
                                          color: AppColors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 18.0),
                      child: bottomButton(
                        padding: 18,
                        width: 40,
                        title: 'Save',
                        subtitle: 'Cancel',
                        icon: Icons.arrow_forward,
                        icons: Icons.arrow_forward,
                        onPress: () async {
                          if (!_formKey.currentState!.validate()) return;

                          final taskDetails =
                          Provider.of<TaskDetailController>(
                            context,
                            listen: false,
                          );

                          final taskText =
                          taskDetails.detailsController.text.trim();

                          // 1️⃣ Check if completely empty
                          if (taskText.isEmpty) {
                            CustomSnackBar.errorSnackBar(
                              context,
                              'Please enter valid task details',
                            );
                            return;
                          }

                          // Then manually check project selection
                          if (taskDetails.selectedProjectId == null) {
                            CustomSnackBar.errorSnackBar(
                              context,
                              'Please select a project',
                            );
                            return;
                          }
                          // 4. File upload validation (MANDATORY)
                         //   if (_uploadedFile == null) {
                         //    CustomSnackBar.errorSnackBar(
                         //      context,
                         //      'Please upload a file',
                         //    );
                         //
                         //  }
                         //
                         //  // 5. File size validation (max 25 MB)
                         // if (_uploadedFile != null) {
                         //    try {
                         //      final fileSize = await _uploadedFile!.length();
                         //      const maxSize = 25 * 1024 * 1024; // 25 MB in bytes
                         //
                         //      if (fileSize > maxSize) {
                         //        CustomSnackBar.errorSnackBar(
                         //          context,
                         //          'File size should not exceed 25 MB',
                         //        );
                         //
                         //      }
                         //    } catch (e) {
                         //      CustomSnackBar.errorSnackBar(
                         //        context,
                         //        'Error checking file size',
                         //      );
                         //
                         //    }
                         //  }
                          // 3. Priority/Severity validation (MANDATORY)
                          if (taskDetails.selectedPriority == null ||
                              taskDetails.selectedPriority?['id'] == null) {
                            CustomSnackBar.errorSnackBar(
                              context,
                              'Please select a priority/severity',
                            );
                          }
                          if (taskDetails.dateTimeList.isEmpty) {
                            CustomSnackBar.errorSnackBar(
                              context,
                              'Please select date & time',
                            );
                            return;
                          }
                          if (estimatedHoursController.text.trim().isEmpty) {
                            CustomSnackBar.errorSnackBar(
                              context,
                              'Please enter estimated hours',
                            );
                            return;
                          }
                          // String estimatedHoursValue = estimatedHoursController.text.trim();
                          if (estimatedHoursController.text.trim().isEmpty ||
                              estimatedHoursController.text.trim() == "0") {
                            CustomSnackBar.errorSnackBar(
                              context,
                              'Please enter estimated hours',
                            );
                            return;
                          }
                          if (taskDetails.selectedAssignToUserId == null) {
                            CustomSnackBar.errorSnackBar(
                              context,
                              'Please select a AssignTo User',
                            );
                            return;
                          }
                          // if (taskDetails.taggedUsers.isEmpty) {
                          //   CustomSnackBar.errorSnackBar(
                          //     context,
                          //     'Please select tagged users',
                          //   );
                          //   return;
                          // }

                          setState(() => isLoading = true);
                          try {
                            await taskDetails.updateTaskWithFile(
                              context: context,
                              taskId: int.tryParse(widget.taskId ?? '') ?? 0,
                              taskName: widget.taskName,
                              taskDetail: taskDetails.detailsController.text,
                              selectedProjectId:
                              taskDetails.selectedProjectId,
                              selectedPriorityId:
                              taskDetails.selectedPriority?['id']
                                  ?.toString(),
                              isFavourite: isFavourite,
                              assignTo: taskDetails.selectedAssignToUserId,
                              notifyUserIds:
                              taskDetails.taggedUsers
                                  .map((e) => int.tryParse(e) ?? 0)
                                  .toList(),
                              uploadedFile: _uploadedFile,
                              assignDate:
                              taskDetails.dateTimeList.isNotEmpty
                                  ? taskDetails.dateTimeList.first.date ??
                                  DateTime.now()
                                  : DateTime.now(),
                              assignTime:
                              taskDetails.dateTimeList.isNotEmpty
                                  ? taskDetails.dateTimeList.first.time ??
                                  TimeOfDay.now()
                                  : TimeOfDay.now(),
                              estimatedHours: estimatedHoursController.text,
                              // Add this
                              estStartDate:rangeStart,
                              // Add this
                              estEndDate: rangeEnd,
                            );
                            _clearFormData();
                            //showSuccessDialog(context);
                            if (!mounted) return;
                            // showSuccessDialog(context);
                            //  setState(() {

                            //  });
                            Navigator.pop(context, true);
                          } catch (e) {
                            debugPrint('Save task error: $e');
                            CustomSnackBar.errorSnackBar(
                              context,
                              'Save task error: $e',
                            );
                          } finally {
                            if (mounted) setState(() =>  isLoading = false);
                          }
                        },
                        onTap: () {
                          Navigator.pop(context);
                          debugPrint('Cancel button...');
                        },
                      ),
                    ),
                    SizedBox(height: 50),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (isLoading)
                          Positioned(
                            bottom: 100,
                            height: 100,
                            child: Center(
                              child: commonLoader(
                                color: AppColors.appBar,
                                size: 40,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
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
      showAppBar: true,
    );
  }

  final dropdownSearchKey =
  GlobalKey<DropdownSearchState<Map<String, dynamic>>>();
  // ✅ Add these for multi-tag support
  Future<void> _showAssignToBottomSheet(
      BuildContext context,
      TaskDetailController taskDetail,
      ) async {


    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return SafeArea(

          child: StatefulBuilder(
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
                      Center(
                        child: Text(
                          'Assign To',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
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
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                        // controlAffinity: ListTileControlAffinity.leading,
                        // contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.only(
                          left: -30,
                          right: 0,
                        ),
                        // ✅ Remove horizontal padding
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
                                items: (filter, infiniteScrollProps) async {
                                  return userList
                                      .where(
                                        (user) => user['user_name']
                                        .toString()
                                        .toLowerCase()
                                        .contains(
                                      filter?.toLowerCase() ?? '',
                                    ),
                                  )
                                      .toList();
                                },
                                selectedItem:
                                selectedAssignToId != null
                                    ? userList.firstWhere(
                                      (user) =>
                                  user['user_id'].toString() ==
                                      selectedAssignToId,
                                  orElse: () => {},
                                )
                                    : null,
                                itemAsString: (user) => user['user_name'] ?? '',
                                compareFn:
                                    (item, selectedItem) =>
                                item['user_id'].toString() ==
                                    selectedItem['user_id'].toString(),
                                onChanged: (user) {
                                  if (user != null) {
                                    setModalState(() {
                                      selectedAssignToId =
                                          user['user_id'].toString();
                                      selectedAssignToName = user['user_name'];
                                    });
                                  }
                                },
                                popupProps: PopupProps.modalBottomSheet(
                                  showSearchBox: true, // ✅ Enable search
                                  constraints: BoxConstraints(
                                    maxHeight:
                                    MediaQueryData.fromWindow(
                                      WidgetsBinding.instance.window,
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
                                        width: 0.8, // ✅ thinner border
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade400,
                                        width: 0.8, // ✅ thinner border
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                        Colors
                                            .grey
                                            .shade500, // Slightly darker when focused
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
                                debugPrint("🔍 Searching for: $filter");

                                final filtered =
                                userList
                                    .where(
                                      (user) => user['user_name']
                                      .toLowerCase()
                                      .contains(
                                    filter?.toLowerCase() ?? '',
                                  ),
                                )
                                    .toList();

                                final selectedIds =
                                selectedTagUsers
                                    .map((u) => u['user_id'].toString())
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

                                debugPrint(
                                  "📦 Filtered list count: ${filtered.length}",
                                );
                                return filtered;
                              },

                              selectedItems: selectedTagUsers,
                              itemAsString: (user) => user['user_name'],

                              dropdownBuilder: (context, selectedItems) {
                                return Wrap(
                                  spacing: 6,
                                  children:
                                  selectedTagUsers.map((user) {
                                    return Chip(
                                      label: Text(user['user_name']),
                                      onDeleted: () {
                                        debugPrint(
                                          "❌ Removed user from modal sheet ${user['user_name']}",
                                        );
                                        setModalState(() {
                                          selectedTagUsers.remove(user);
                                          selectedTagUserIds.removeWhere(
                                                (id) =>
                                            id ==
                                                user['user_id'].toString(),
                                          );
                                          taskDetail.taggedUsers =
                                              selectedTagUserIds;
                                          taskDetail.taggedUserDetails =
                                              selectedTagUsers;
                                        });

                                        // Trigger UI update for DropdownSearch
                                        dropdownSearchKey.currentState
                                            ?.changeSelectedItems(
                                          selectedTagUsers,
                                        );
                                      },
                                    );
                                  }).toList(),
                                );
                              },

                              onChanged: (List<Map<String, dynamic>> users) {
                                debugPrint("✅ Selected users:");

                                setModalState(() {
                                  selectedTagUsers = users;
                                  selectedTagUserIds =
                                      users
                                          .map((e) => e['user_id'].toString())
                                          .where((id) => id.isNotEmpty)
                                          .toList();
                                  taskDetail.taggedUsers = selectedTagUserIds;
                                  taskDetail.taggedUserDetails = users;
                                }); //current (rg)
                              },

                              popupProps: PopupPropsMultiSelection.modalBottomSheet(
                                showSearchBox: true,

                                onItemRemoved: (selectedItems, removedItem) {
                                  setModalState(() {
                                    selectedTagUserIds.remove(
                                      removedItem['user_id'].toString(),
                                    );
                                    selectedTagUsers.removeWhere(
                                          (user) =>
                                      user['user_id'].toString() ==
                                          removedItem['user_id'].toString(),
                                    );
                                  });
                                  debugPrint(
                                    "🔴 Item removed: ${removedItem['user_name']}",
                                  );
                                },

                                onItemAdded: (selectedItems, addedItem) {
                                  setModalState(() {
                                    selectedTagUserIds.add(
                                      addedItem['user_id'].toString(),
                                    );
                                    selectedTagUsers.add(addedItem);
                                  });
                                  debugPrint(
                                    "🟢 Item added: ${addedItem['user_name']}",
                                  );
                                },

                                itemBuilder: (
                                    context,
                                    item,
                                    isDisabled,
                                    isSelected,
                                    ) {
                                  // Always calculate selected dynamically
                                  final bool selected = selectedTagUserIds
                                      .contains(item['user_id'].toString());

                                  return InkWell(

                                    onTap: () {


                                      if (selected) {

                                        setModalState(() {
                                          selectedTagUsers.removeWhere(
                                                (u) =>
                                            u['user_id'].toString() ==
                                                item['user_id'].toString(),
                                          );
                                          selectedTagUserIds.removeWhere(
                                                (id) =>
                                            id == item['user_id'].toString(),
                                          );

                                          taskDetail.taggedUsers =
                                              selectedTagUserIds;
                                          taskDetail.taggedUserDetails =
                                              selectedTagUsers;
                                          dropdownSearchKey.currentState
                                              ?.changeSelectedItems(
                                            selectedTagUsers,
                                          );
                                        });
                                        // updatedUsers.remove(item);
                                        // updatedUserIds.remove(item['user_id'].toString());
                                      } else {
                                        setModalState(() {
                                          selectedTagUsers.add(item);
                                          selectedTagUserIds.add(
                                            item['user_id'].toString(),
                                          );
                                          taskDetail.taggedUsers =
                                              selectedTagUserIds;
                                          taskDetail.taggedUserDetails =
                                              selectedTagUsers;
                                          dropdownSearchKey.currentState
                                              ?.changeSelectedItems(
                                            selectedTagUsers,
                                          );
                                        });
                                      }

                                      /*   setModalState(() {
                                        selectedTagUsers = updatedUsers;
                                        selectedTagUserIds = updatedUserIds;

                                        taskDetail.taggedUsers = updatedUserIds;
                                        taskDetail.taggedUserDetails = updatedUsers;
                                      });*/

                                      // This forces DropdownSearch to repaint itemBuilder UI
                                      dropdownSearchKey.currentState
                                          ?.changeSelectedItems(selectedTagUsers);
                                    },

                                    child: ListTile(
                                      leading: Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor:
                                            selected
                                                ? Colors.blue
                                                : Colors.grey.shade200,
                                            child:
                                            item['user_avatar'] == null
                                                ? Icon(
                                              Icons.person,
                                              color:
                                              selected
                                                  ? Colors.white
                                                  : Colors
                                                  .grey
                                                  .shade400,
                                              size: 27,
                                            )
                                                : null,
                                            backgroundImage:
                                            item['user_avatar'] != null
                                                ? NetworkImage(
                                              item['user_avatar'],
                                            )
                                                : null,
                                          ),

                                          if (selected)
                                            Positioned(
                                              top: 0,
                                              right: 0,
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
                                    (context, item, isDisabled, isSelected) =>
                                const SizedBox.shrink(),

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
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              // Optional: show selected user count, etc.
                                            ],
                                          ),
                                        ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 60,
                                          ), // ✅ Added bottom padding
                                          child: popupWidget,
                                        ),
                                      ),
                                    ],
                                  );
                                },

                                constraints: BoxConstraints(
                                  maxHeight:
                                  MediaQuery.of(context).size.height * 0.95,
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

                              compareFn:
                                  (item, selectedItem) =>
                              item['user_id'].toString() ==
                                  selectedItem['user_id'].toString(),

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
                                    debugPrint("clear button pressed");
                                    selectedTagUserIds.clear();
                                    selectedTagUsers.clear();

                                    isAssignToSelf = false;
                                    selectedAssignToId = null;
                                    selectedAssignToName = null;
                                    selectedTagUserId = null;
                                    selectedTagUserName = null;
                                  });
                                  dropdownSearchKey.currentState
                                      ?.changeSelectedItems([]);
                                  dropdownSearchKey.currentState?.clear();
                                  // Navigator.pop(context);
                                },
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Clear",
                                      style: TextStyle(
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
                                  final userData = await prefss.read(
                                    SharedPrefConstant().kUserData,
                                  );
                                  final currentUserId =
                                  userData?['id']?.toString();
                                  debugPrint('currentUserId :--> $currentUserId');
                                  if (isAssignToSelf) {
                                    if (currentUserId != null) {
                                      taskDetail.setAssignToUser(currentUserId);
                                      taskDetail.selectedAssignToUserId =
                                          currentUserId;
                                    }
                                    // taskDetail.setAssignToUser('self');
                                    // taskDetail.selectedAssignToUserId = 'self';
                                  } else if (selectedAssignToId != null &&
                                      selectedAssignToName != null) {
                                    taskDetail.setAssignToUser(
                                      selectedAssignToName!,
                                    );
                                    taskDetail.selectedAssignToUserId =
                                        selectedAssignToId;
                                  }

                                  if (selectedTagUserId != null &&
                                      selectedTagUserName != null) {
                                    taskDetail.setTagUser(selectedTagUserName!);
                                    if (!taskDetail.taggedUsers.contains(
                                      selectedTagUserId,
                                    )) {
                                      taskDetail.taggedUsers.add(
                                        selectedTagUserId!,
                                      );
                                    }
                                  }

                                  Navigator.pop(context);
                                },
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Apply",
                                      style:TextStyle(
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

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showProjectBottomSheet(BuildContext context) {
    DateTime? _rangeStart;
    DateTime? _rangeEnd;
    DateTime _focusedDay = DateTime.now();
    RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
    final taskDetail = Provider.of<TaskDetailController>(
      context,
      listen: false,
    );
    final _bottomSheetFormKey = GlobalKey<FormState>();
    rangeStart = null;
    rangeEnd = null;
    selectedTime = null;
    repeatSummary = null;
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      isScrollControlled: true,
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
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                void _updateRangeText() {
                  if (_rangeStart != null && _rangeEnd != null) {
                    final startStr = DateFormat(
                      'MMM dd, yyyy',
                    ).format(_rangeStart!);
                    final endStr = DateFormat('MMM dd, yyyy').format(_rangeEnd!);
                    dateRangeController.text = '$startStr - $endStr';
                    rangeStart = _rangeStart; // Set global values
                    rangeEnd = _rangeEnd;
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
                      key: _bottomSheetFormKey,
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
                                    style:TextStyle(
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
                            children: [
                              Row(
                                children: [
                                  SvgPicture.asset(AppImages.ClockSvg),
                                  SizedBox(width: 11),
                                  Text(
                                    'Estimated Hours',
                                    style:TextStyle(
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

                                decoration: InputDecoration(

                                  contentPadding: const EdgeInsets.symmetric(
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
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter estimated hours';
                                  }
                                  return null;
                                },
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
                                  builder: (context) => const RepeatsScreen(),
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
                                  debugPrint('➡ startsOn: ${repeatData?['startsOn']}');
                                  debugPrint(
                                    '➡ endsOption: ${repeatData?['endsOption']}',
                                  );
                                  debugPrint(
                                    '➡ endsOnDate: ${repeatData?['endsOnDate']}',
                                  );
                                  debugPrint(
                                    '➡ occurrences: ${repeatData?['occurrences']}',
                                  );
                                  debugPrint('📝 Repeat Summary: $repeatSummary');
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
                                      style:TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  else
                                    Text(
                                      'Repeat',
                                      style: TextStyle(
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
                            title: 'Done',
                            subtitle: 'Cancel',
                            icon: Icons.check,
                            icons: Icons.clear,

                            onPress: () {
                              if (_bottomSheetFormKey.currentState!.validate()) {
                                if (rangeStart != null ||
                                    estimatedHoursController.text.isNotEmpty ||
                                    repeatSummary != null) {
                                  /// 🔹 PRINT STATEMENTS HERE
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
                                    estimatedHours: estimatedHoursController.text,
                                  );

                                  if (taskDetail.dateTimeList.isEmpty) {
                                    taskDetail.addDateTime(dateTimeModel);
                                  } else {
                                    taskDetail.updateDateTime(0, dateTimeModel);
                                  }

                                  Navigator.pop(context);
                                } else {
                                  // Validation failed
                                  String missingFields = '';
                                  if (rangeStart == null || rangeEnd == null)
                                    missingFields += 'Date Range';
                                  if (estimatedHoursController.text.isEmpty) {
                                    if (missingFields.isNotEmpty)
                                      missingFields += ' and ';
                                    missingFields += 'Estimated Hours';
                                  }
                                  if (repeatSummary == null) {
                                    if (missingFields.isNotEmpty)
                                      missingFields += ' and ';
                                    missingFields += 'Repeat';
                                  }

                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                      title: const Text(
                                        "Missing Information",
                                      ),
                                      content: Text(
                                        "Please select $missingFields before proceeding.",
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
                                }
                              }
                            },

                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showSelectTimeBottomSheet(
      BuildContext context,
      StateSetter setModalState,
      ) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: child,
              ),
            ],
          ),
        );
      },
    );

    if (pickedTime != null) {
      setModalState(() {
        selectedTime = pickedTime;
      });
    }
  }

  void showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppImages.taskAddedSuccessfully,
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'Task Assigned Successfully.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  Navigator.of(context).pop(); // go back
                },
                icon: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text('Ok', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRepeatSubtitle(Map<String, dynamic> repeatData) {
    String subtitle = 'Repeats: ${repeatData['frequency']}';

    if (repeatData['frequency'] == 'Week') {
      int index = repeatData['selectedDays'].indexWhere((e) => e);
      String weekDay =
      [
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
      ][index];
      subtitle += ' on $weekDay';
    }

    if (repeatData['endsOption'] == 'On') {
      subtitle +=
      ', until ${DateFormat('MMM d, y').format(repeatData['endsOnDate'])}';
    } else if (repeatData['endsOption'] == 'After') {
      subtitle += ', ${repeatData['occurrences']} times';
    }

    return Text(subtitle);
  }

  void showUserSelectionBottomSheet(
      BuildContext context,
      List<Map<String, dynamic>> userList,
      ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(
            top: 16.0,
            left: 16,
            right: 16,
            bottom: 32,
          ),
          child: _UserSelectionSheet(userList: userList),
        );
      },
    );
  }
}

class _UserSelectionSheet extends StatefulWidget {
  final List<Map<String, dynamic>> userList;

  const _UserSelectionSheet({required this.userList});

  @override
  State<_UserSelectionSheet> createState() => _UserSelectionSheetState();
}

class _UserSelectionSheetState extends State<_UserSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  String? filter;
  Set<String> selectedUserIds = {};

  @override
  Widget build(BuildContext context) {
    final filtered =
    widget.userList.where((user) {
      final name = user['user_name']?.toLowerCase() ?? '';
      return name.contains(filter?.toLowerCase() ?? '');
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Tag Users for Notification',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search user...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon:
            filter?.isNotEmpty == true
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  filter = '';
                });
              },
            )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) {
            setState(() {
              filter = value.trim();
            });
          },
        ),
        const SizedBox(height: 16),
        ...filtered.map((user) {
          final userId = user['user_id'];
          final userName = user['user_name'];
          final isSelected = selectedUserIds.contains(userId);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
            leading: CircleAvatar(
              backgroundColor: isSelected ? Colors.blue[100] : Colors.grey[300],
              child:
              isSelected
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.person, color: Colors.grey),
            ),
            title: Text(
              userName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.grey[700],
              ),
            ),
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedUserIds.remove(userId);
                } else {
                  selectedUserIds.add(userId);
                }
              }
              );
            },
          );
        }),
      ],
    );
  }
}
