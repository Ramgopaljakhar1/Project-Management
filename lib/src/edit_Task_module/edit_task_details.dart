import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:project_management/src/edit_Task_module/widgets/build_rich_text.dart';
import 'package:project_management/src/edit_Task_module/widgets/edit_Details_collapse.dart';
import 'package:project_management/src/view_ticket_module/screen/view_ticket_id_details.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../assigned_to_team_module/screen/assigned_to_team_screen.dart';
import '../common_widgets/appbar.dart';
import '../common_widgets/common_bottom_button.dart';
import '../common_widgets/common_text_lable_field.dart';
import '../common_widgets/custom_snackbar.dart';
import '../common_widgets/lodar.dart';
import '../utils/colors.dart';
import '../utils/img.dart';
import '../utils/no_internet_connectivity.dart';
import '../utils/shared_pref_constants.dart';
import '../utils/shared_preference.dart';
import '../utils/string.dart';
import 'controller/controller.dart';

class EditTaskDetails extends StatefulWidget {
  final String taskId;
  const EditTaskDetails({super.key, required this.taskId});

  @override
  State<EditTaskDetails> createState() => _EditTaskDetailsState();
}

class _EditTaskDetailsState extends State<EditTaskDetails> {
  bool isDetailsExpanded = false;
  bool isLoading = true;
  bool isSaving = false;
  File? _uploadedFile;
  late TextEditingController taskNameController;
  late TextEditingController projectNameController;
  late TextEditingController detailsController;
  late TextEditingController assignDateController;
  late TextEditingController assignTimeController;
  late final TextEditingController estimatedHoursController;
  String? existingTaskDoc;
  final TextEditingController actualDaysController = TextEditingController();
  TextEditingController _dateRangeController =
      TextEditingController(); // ← this one
  TextEditingController _estimatedHoursController = TextEditingController();
  bool isUserSelectedDateAndHours = false;
  List<Map<String, dynamic>> selectedTagForUsers = [];

  final Connectivity _connectivity = Connectivity();
  bool _isNetworkAvailable = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  List<Map<String, dynamic>> _userList = [];
  String? _selectedUserId;
  String? _selectedUserName;
  String? uploadedFileUrl;
  File? uploadedFile;
  String? apiFileUrl;
  final EditTaskController _editTaskController = EditTaskController();

  final dropdownSearchKey =
      GlobalKey<DropdownSearchState<Map<String, dynamic>>>();

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    taskNameController = TextEditingController();
    projectNameController = TextEditingController();
    detailsController = TextEditingController();
    assignDateController = TextEditingController();
    assignTimeController = TextEditingController();
    estimatedHoursController = TextEditingController();
    estimatedHoursController.addListener(updateActualDays);
    _loadUsers();
    // Fetch task details
    _fetchTaskDetails();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  Future<void> _loadUsers() async {
    final users = await _editTaskController.fetchUserList();
    setState(() {
      _userList = users;
    });
  }

  Future<void> _fetchTaskDetails() async {
    final controller = Provider.of<EditTaskController>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.fetchTaskDetailById(widget.taskId);

      if (controller.task != null) {
        debugPrint('Complete Api Response');
        debugPrint(jsonEncode(controller.task));
        existingTaskDoc = controller.task!['task_docs']?.toString() ?? "";
        debugPrint("Task ID-->: ${controller.task!['id']}");
        debugPrint("Task Docs: ${existingTaskDoc}");
        debugPrint("Ticket ID-->: ${controller.task!['ticket_id']}");

        _updateControllersFromData(controller.task!);

        if (controller.task!['notifications_notify_to'] != null) {
          final notifyTo = List<Map<String, dynamic>>.from(
            controller.task!['notifications_notify_to'],
          );
          final updatedList = notifyTo.map((user) {
            debugPrint("👤 User ID-->: ${user['id']}, Name-->: ${user['full_name']}");
            return {'user_id': user['id'], 'user_name': user['full_name']};
          }).toList();

          if (!mounted) return;
          setState(() {
            selectedTagForUsers = updatedList;
            print("notification user list--- : $updatedList");
          });

          print('✅ Final selectedTagForUsers : $selectedTagForUsers');
        }
      }

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    });
  }



  void _updateControllersFromData(Map<String, dynamic> data) {
    taskNameController.text = data['task_name']?.toString() ?? '';
    detailsController.text = data['task_detail']?.toString() ?? '';

    // Handle date range if available
    if (data['est_start_date'] != null && data['est_end_date'] != null) {
      try {
        final startDate = DateTime.parse(data['est_start_date'].toString());
        final endDate = DateTime.parse(data['est_end_date'].toString());
        _dateRangeController.text =
        '${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}';
        isUserSelectedDateAndHours = true;
      } catch (e) {
        print('Error parsing date range: $e');
      }
    }

    // Handle estimated hours
    _estimatedHoursController.text = data['est_hrs']?.toString() ?? '';

    assignTimeController.text = data['assign_time']?.toString() ?? '';
    projectNameController.text = data['project_lookupdet_desc']?.toString() ?? '';

    // Update the actual days display if we have both range and hours
    if (isUserSelectedDateAndHours && _estimatedHoursController.text.isNotEmpty) {
      actualDaysController.text =
      '${_dateRangeController.text} | ${_estimatedHoursController.text} Hours';
    }

    // Store the original assign_to values
    _selectedUserId = data['assign_to']?.toString();
    _selectedUserName = data['assign_to_user_name']?.toString();
  }
  Future<void> _pickFile() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _uploadedFile = File(pickedFile.path);
      });
    }
  }


  void _deleteFile() {
    setState(() {
      _uploadedFile = null;
      // Clear the existing file reference to indicate deletion
      existingTaskDoc = null;

      // Also update the controller's task data
      final controller = Provider.of<EditTaskController>(context, listen: false);
      if (controller.task != null) {
        controller.task!['task_docs'] = "";
      }
    });

    // Show confirmation message
    CustomSnackBar.successSnackBar(context, 'File removed successfully');
  }




/// update function
  Future<void> updateTask() async {
    if (!mounted) return;

    setState(() {
      isSaving = true;
    });

    final controller = Provider.of<EditTaskController>(context, listen: false);
    final task = controller.task;

    if (task == null) {
      if (!mounted) return;
      setState(() {
        isSaving = false;
      });
      return;
    }

    String? estStartDate;
    String? estEndDate;

    if (isUserSelectedDateAndHours && _dateRangeController.text.contains(' - ')) {
      try {
        final dates = _dateRangeController.text.split(' - ');
        final startDate = DateFormat('MMM dd, yyyy').parse(dates[0]);
        final endDate = DateFormat('MMM dd, yyyy').parse(dates[1]);

        estStartDate = DateFormat('yyyy-MM-dd').format(startDate);
        estEndDate = DateFormat('yyyy-MM-dd').format(endDate);
      } catch (e) {
        print('Error parsing date range: $e');
      }
    }

    // Handle notification users
    List<int> notificationUserIds = [];
    if (selectedTagForUsers.isNotEmpty) {
      notificationUserIds = selectedTagForUsers
          .map((user) => int.tryParse(user['user_id']?.toString() ?? '0') ?? 0)
          .where((id) => id > 0)
          .toList();
    }

    // Handle time format
    String? assignTime = assignTimeController.text.trim();
    if (assignTime.isEmpty) {
      assignTime = null;
    } else {
      final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$');
      if (!timeRegex.hasMatch(assignTime)) {
        if (!mounted) return;
        setState(() {
          isSaving = false;
        });
        CustomSnackBar.errorSnackBar(
          context,
          'Please enter time in valid format (HH:MM)',
        );
        return;
      }
    }

    // Prepare the data according to API structure
    final updatedData = {
      'task_name': taskNameController.text,
      'task_detail': detailsController.text,
      'project_name': task['project_name']?.toString(),
      'priority_lookupdet': task['priority_lookupdet']?.toString(),
      'assign_to': _selectedUserId ?? task['assign_to']?.toString(),
      'favorite_flag': task['favorite_flag'] ?? 'N',
      'status': task['status']?.toString() ?? '1',
      'est_hrs': _estimatedHoursController.text.isNotEmpty
          ? _estimatedHoursController.text
          : task['est_hrs']?.toString(),
      'est_start_date': estStartDate ?? task['est_start_date']?.toString(),
      'est_end_date': estEndDate ?? task['est_end_date']?.toString(),
      'notification_detail': notificationUserIds,
    };

    // Handle assign_date and assign_time
    if (assignDateController.text.isNotEmpty) {
      updatedData['assign_date'] = assignDateController.text;
    }

    if (assignTime != null) {
      updatedData['assign_time'] = assignTime;
    }

    // Handle created_by and updated_by
    if (task['created_by'] != null) {
      updatedData['created_by'] = task['created_by'];
    }

    // Add updated_by with current user ID
    final prefs = SharedPref();
    final userData = await prefs.read(SharedPrefConstant().kUserData);
    if (userData != null && userData['id'] != null) {
      updatedData['updated_by'] = userData['id'];
    }

    // Handle file logic
    if (_uploadedFile != null) {
      // 1. User uploaded a new file → Base64 encode and send it
      try {
        final fileBytes = await _uploadedFile!.readAsBytes();
        updatedData['task_docs'] = base64Encode(fileBytes);
        print('📁 New file encoded to base64, size: ${fileBytes.length} bytes');
      } catch (e) {
        print('Error encoding new file: $e');
        if (!mounted) return;
        setState(() {
          isSaving = false;
        });
        CustomSnackBar.errorSnackBar(context, 'Error processing file: $e');
        return;
      }
    } else if (existingTaskDoc == null || existingTaskDoc!.isEmpty) {
      // 2. User deleted the file → Send empty string
      updatedData['task_docs'] = "";
      print('🗑️ File marked for deletion');
    } else {
      // 3. No new file uploaded, but existing file exists → Convert URL to base64
      try {
        final existingFileUrl = task['task_docs']?.toString();
        if (existingFileUrl != null && existingFileUrl.isNotEmpty) {
          print('🔄 Converting existing file URL to base64: $existingFileUrl');
          final fileBytes = await _downloadFileFromUrl(existingFileUrl);
          if (fileBytes != null) {
            updatedData['task_docs'] = base64Encode(fileBytes);
            print('✅ Existing file converted to base64, size: ${fileBytes.length} bytes');
          } else {
            updatedData['task_docs'] = "";
            print('⚠️ Failed to download existing file, setting to empty');
          }
        } else {
          updatedData['task_docs'] = "";
          print('📋 No existing file reference found');
        }
      } catch (e) {
        print('❌ Error processing existing file: $e');
        updatedData['task_docs'] = "";
      }
    }

    print('🔄 Updating task with data: $updatedData');
    try {
      final response = await controller.updateTask(
        taskId: widget.taskId,
        taskData: updatedData,
        file: _uploadedFile,
      );
      print("📡 API Response: ${jsonEncode(response)}");

      if (!mounted) return;
      setState(() {
        isSaving = false;
      });

      if (response['status']?.toString().toLowerCase() == 'success') {
        CustomSnackBar.successSnackBar(context, response['message']);

        // Refresh the task details to get updated data
        await _fetchTaskDetails();
        Navigator.pop(context);
      } else {
        if (response['message'] is Map) {
          final errorMap = Map<String, dynamic>.from(response['message']);
          final errorMessages = errorMap.entries
              .map((e) => '${e.key}: ${e.value is List ? e.value.join(', ') : e.value}')
              .join('\n');
          CustomSnackBar.errorSnackBar(context, errorMessages);
        } else {
          CustomSnackBar.errorSnackBar(context, response['message']);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSaving = false;
      });
      CustomSnackBar.errorSnackBar(context, 'Failed to update task: $e');
    }
  }

  void updateActualDays() {
    final date = _dateRangeController.text;
    final hours = _estimatedHoursController.text;
    if (date.isNotEmpty && hours.isNotEmpty) {
      actualDaysController.text = '$date | $hours Hours';
    } else {
      actualDaysController.text = '';
    }
    print('actual Days Controller : ${actualDaysController.text}');
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
  Future<Uint8List?> _downloadFileFromUrl(String url) async {
    try {
      print('📥 Downloading file from URL: $url');

      // Check if it's a valid URL
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.isAbsolute) {
        print('❌ Invalid URL: $url');
        return null;
      }

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        print('✅ File downloaded successfully, size: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        print('❌ Failed to download file, status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error downloading file: $e');
      return null;
    }
  }

  Future<void> _showFilePickerOptions() async {
    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('Files'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickFiles();
                },
              ),
            ],
          ),
        );
      },
    );
  }

// Pick from camera
  Future<void> _pickFromCamera() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        const maxSize = 25 * 1024 * 1024; // 25 MB in bytes

        if (fileSize > maxSize) {
          CustomSnackBar.errorSnackBar(
              context,
              'File size exceeds 25 MB limit. Please choose a smaller file.'
          );
          return;
        }

        setState(() {
          _uploadedFile = file;
        });
      }
    } catch (e) {
      CustomSnackBar.errorSnackBar(context, 'Failed to capture image: $e');
    }
  }

// Pick from gallery
  Future<void> _pickFromGallery() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        const maxSize = 25 * 1024 * 1024; // 25 MB in bytes

        if (fileSize > maxSize) {
          CustomSnackBar.errorSnackBar(
              context,
              'File size exceeds 25 MB limit. Please choose a smaller file.'
          );
          return;
        }

        setState(() {
          _uploadedFile = file;
        });
      }
    } catch (e) {
      CustomSnackBar.errorSnackBar(context, 'Failed to pick image: $e');
    }
  }

// Pick files (documents, PDFs, etc.)
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx', 'jpg', 'jpeg', 'png', 'gif'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();
        const maxSize = 25 * 1024 * 1024; // 25 MB in bytes

        if (fileSize > maxSize) {
          CustomSnackBar.errorSnackBar(
              context,
              'File size exceeds 25 MB limit. Please choose a smaller file.'
          );
          return;
        }

        setState(() {
          _uploadedFile = file;
          existingTaskDoc = null;
        });
      }
    } catch (e) {
      CustomSnackBar.errorSnackBar(context, 'Failed to pick file: $e');
    }
  }

  void _navigateToTicketDetails(String? ticketId,String taskId){
    if(ticketId == null || ticketId == '-' || ticketId.isEmpty){
      CustomSnackBar.errorSnackBar(context, "'Ticket ID not available");
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewTicketIdDetails(ticketId:ticketId,taskId:taskId,),
      ),
    );
  }
  @override
  void dispose() {
    taskNameController.dispose();
    projectNameController.dispose();
    detailsController.dispose();
    assignDateController.dispose();
    assignTimeController.dispose();
    estimatedHoursController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final editTaskController = Provider.of<EditTaskController>(context);
    final task = editTaskController.task;
    print('......,,,,Task List : $task');

    if (isLoading || task == null) {
      return Scaffold(
        appBar: customAppBar(
          context,
          title: 'Edit Task Details',
          showBack: true,
        ),
        body: Center(child: commonLoader(color: AppColors.black, size: 35)),
      );
    }

    return _isNetworkAvailable
        ? GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Scaffold(
                appBar: customAppBar(
                  context,
                  title: 'Edit Task Details',
                  showBack: true,
                  showLogo: false
                ),
                body: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.white,
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13.0,
                        vertical: 11,
                      ),
                      child: Form(
                        child: ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 11.0),
                              child:  Row(
                                children: [
                                  buildRichText('Task ID', '${task['id'] ?? '-'}'),
                                  const SizedBox(width: 25),
                                  GestureDetector(
                                    onTap: () {
                                      _navigateToTicketDetails(task['ticket_id'].toString(),task['id'].toString());
                                    },
                                    child: buildRichText(
                                      'Ticket ID',
                                      '${task['ticket_id'] ?? '-'}',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Task Name Section
                            const SizedBox(height: 15),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 10,
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
                            const SizedBox(height: 8),
                            textLabelFormField(
                              readOnly: false,
                              controller: taskNameController,
                              taskName: 'Task Name',
                              hintText: 'Enter task here',
                              onChanged: (value) {},
                              borderColor: Colors.grey.shade400,
                              prefixIconColor: Colors.black,
                              backgroundColor: Colors.white,
                            ),

                            const SizedBox(height: 15),

                            // Details Section
                            EditDetailsCollapse(
                              context: context,
                              apiFileUrl: task['task_docs'],
                              subtitle: "${task['priority_lookupdet_desc']}",
                              showSubtitle: true,
                              showPrioritySection: false,
                              showCollapseIcon: false,
                              onPress: () {
                                setState(() {
                                  isDetailsExpanded = !isDetailsExpanded;
                                });
                              },
                              viewFile: () async {
                                try {
                                  String? filePath;

                                  // Check if there's a newly uploaded file first
                                  if (_uploadedFile != null) {
                                    filePath = _uploadedFile!.path;
                                  }
                                  // If no new file, check if there's an existing file from the API
                                  else if (task['task_docs'] != null && task['task_docs'].toString().isNotEmpty) {
                                    final apiFileUrl = task['task_docs'].toString();
                                    final uri = Uri.parse(apiFileUrl);
                                    final tempDir = Directory.systemTemp;
                                    final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'downloaded_file';
                                    final file = File('${tempDir.path}/$fileName');
                                      print("file url : ${apiFileUrl}");
                                    // Download file if it doesn't exist locally
                                    if (!file.existsSync()) {
                                      final response = await http.get(uri);
                                      if (response.statusCode == 200) {
                                        await file.writeAsBytes(response.bodyBytes);
                                      } else {

                                        if (context.mounted) {
                                          CustomSnackBar.errorSnackBar(context,
                                              'Failed to download file, status: ${response.statusCode}');
                                        }
                                        return;
                                      }
                                    }
                                    filePath = file.path;
                                  }

                                  // If we have a file path, try to open the file
                                  if (filePath != null) {
                                    final result = await OpenFile.open(filePath);
                                    debugPrint('Open result: ${result.message}');
                                  } else {
                                    if (context.mounted) {
                                      CustomSnackBar.errorSnackBar(context, 'No file available to open');
                                    }
                                  }
                                } catch (e) {
                                  debugPrint('Error opening file: $e');
                                  if (context.mounted) {
                                    CustomSnackBar.errorSnackBar(context, 'Could not open file: $e');
                                  }
                                }
                              },
                              isExpanded: isDetailsExpanded,
                              title: 'Add Details',
                              img: AppImages.descriptionSvg,
                              hintText: 'Add details here',
                              prefixIconImage: AppImages.description,
                              controller: detailsController,
                              maxLines: 3,
                              backgroundColor: Colors.white,
                              borderColor: Colors.grey,
                              prefixIconColor: Colors.black,
                              titleColor: Colors.black,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter details';
                                }
                                return null;
                              },
                              readOnly: false,
                              projectList: const [], // No static projects
                              selectedProject: projectNameController.text,
                              onChange: (value) {},
                              showDropdownForProjectName: false,
                              projectNameController: projectNameController,
                              uploadedFile: _uploadedFile,
                              onDeleteFile: _deleteFile,
                              onUploadPress: _showFilePickerOptions,
                              selectedPriority:
                                  task['priority_lookupdet_desc'] ?? '',
                              onPriorityChange: (value) {
                                // Handle priority change if needed
                              },
                            ),
                            const SizedBox(height: 15),
                            Padding(
                              padding: const EdgeInsets.only(left: 11.0),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    AppImages.dateTimeSvg,
                                    width: 22,
                                    height: 22,
                                    fit: BoxFit.cover,
                                    color: AppColors.black,
                                  ),
                                  SizedBox(width: 11),
                                  Text(
                                    'Estimated Dates & Hours',
                                    style: GoogleFonts.lato(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Date & Time Section
                            GestureDetector(
                              onTap: () {
                                _showCalendarBottomSheet(context);
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: 11.0),
                                child: Row(
                                  children: [
                                    // SvgPicture.asset(
                                    //   AppImages.dateTimeSvg,
                                    //   width: 22,
                                    //   height: 22,
                                    //   fit: BoxFit.cover,
                                    //   color: AppColors.black,
                                    // ),
                                   Expanded(
                                     child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 11.0),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey.shade400,
                                                width: 0.8,
                                              ),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  isUserSelectedDateAndHours
                                                      ? actualDaysController.text
                                                      : assignDateController
                                                              .text
                                                              .isNotEmpty &&
                                                          assignTimeController
                                                              .text
                                                              .isNotEmpty
                                                      ? '${assignDateController.text} ${_estimatedHoursController.text}'
                                                      : 'No date/time set',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                                const SizedBox(width: 7),
                                                const Icon(
                                                  Icons.close,
                                                  color: Colors.black45,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                   ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),

                            // Assign To Section
                            GestureDetector(
                              onTap: () {
                                _showAssignToBottomSheet(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          AppImages.assignToSvg,
                                          width: 22,
                                          height: 22,
                                          color: Colors.black,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Assign To',
                                          style: GoogleFonts.lato(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 11.0),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade400,
                                            width: 0.8,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            //
                                            Text(
                                              _selectedUserName?.isNotEmpty ==
                                                      true
                                                  ? _selectedUserName!
                                                  : task['assign_to_user_name'] ??
                                                      'User ${task['assign_to_user_name']}' ??
                                                      'Select User',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            const SizedBox(width: 11),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedUserName = null;
                                                  _selectedUserId = null;
                                                });
                                              },
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.black45,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            SvgPicture.asset(
                                              AppImages.tagUserSvg,
                                              width: 22,
                                              height: 22,
                                              color: Colors.black,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Tagged for Notification',
                                              style: GoogleFonts.lato(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        if (selectedTagForUsers.isNotEmpty) ...[
                                          Wrap(
                                            spacing: 6,
                                            children:
                                                selectedTagForUsers.map((user) {
                                                  final userName =
                                                      user['user_name']
                                                          ?.toString() ??
                                                      "Unknown";
                                                  return Chip(
                                                    backgroundColor: Colors.white,
                                                    label: Text(userName),
                                                    deleteIcon: const Icon(
                                                      Icons.close,
                                                    ),
                                                    onDeleted: () {
                                                      setState(() {
                                                        selectedTagForUsers
                                                            .remove(user);
                                                      });
                                                    },
                                                  );
                                                }).toList(),
                                          ),
                                        ] else ...[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 34.0,
                                            ),
                                            child: const Text(
                                              'No tagged users',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Favorite Section
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  // Toggle favorite_flag strictly based on current API value
                                  if (task.containsKey('favorite_flag')) {
                                    task['favorite_flag'] =
                                        task['favorite_flag'] == 'Y' ? 'N' : 'Y';
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: 11.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      task['favorite_flag'] == 'Y'
                                          ? Icons.star
                                          : Icons.star_outline,
                                      color:
                                          task['favorite_flag'] == 'Y'
                                              ? Colors.red
                                              : Colors.black,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 17),
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

                            const SizedBox(height: 25),

                            bottomButton(
                              title: 'Update',
                              subtitle: 'Cancel',
                              icon: Icons.check,
                              icons: Icons.close,
                              onPress: () async {
                                await updateTask();

                              },
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (isLoading)
                Container(
                  // color: Colors.black.withOpacity(0.2),
                  child: Center(
                    child: commonLoader(color: AppColors.black, size: 35),
                  ),
                ),

              // Saving overlay (shows when update button is pressed)
              if (isSaving)
                Container(
                  //   color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: commonLoader(color: AppColors.black, size: 40),
                  ),
                ),
            ],
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

  Future<void> _showAssignToBottomSheet(BuildContext context) async {
    String? selectedAssignToId;
    String? selectedAssignToName;
    List<Map<String, dynamic>> tempSelectedTagUsers = List.from(
      selectedTagForUsers,
    );
    List<String> tempSelectedTagUserIds =
        tempSelectedTagUsers.map((e) => e['user_id'].toString()).toList();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        List<Map<String, dynamic>> tempSelectedUsers = List.from(
          selectedTagForUsers,
        );

        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.3,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  height: 400,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Text(
                          'Assign To',
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
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
                        items: (filter, _) async {
                          return _userList
                              .where(
                                (user) => user['user_name']
                                    .toString()
                                    .toLowerCase()
                                    .contains(filter?.toLowerCase() ?? ''),
                              )
                              .toList();
                        },
                        selectedItem:
                            selectedAssignToId != null
                                ? _userList.firstWhere(
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
                              selectedAssignToId = user['user_id'].toString();
                              selectedAssignToName = user['user_name'];
                            });

                            //  Navigator.pop(context);

                            // 🔽 ADD THIS to reflect changes in parent widget
                            setState(() {
                              _selectedUserId = selectedAssignToId;
                              _selectedUserName = selectedAssignToName;
                            });
                          }
                        },

                        popupProps: PopupProps.modalBottomSheet(
                          showSearchBox: true,
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
                            hintText: "Select user",
                            hintStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w300,
                              fontStyle: FontStyle.italic,
                            ),
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          SvgPicture.asset(
                            AppImages.tagUserSvg, // your icon
                            color: AppColors.black,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Tag For',
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
                          final filtered =
                              _userList.where((user) {
                                final userName =
                                    user['user_name'] ??
                                    user['full_name'] ??
                                    '';
                                return userName
                                    .toString()
                                    .toLowerCase()
                                    .contains(filter?.toLowerCase() ?? '');
                              }).toList();

                          final selectedIds =
                              tempSelectedTagUsers
                                  .map((u) => u['user_id'].toString())
                                  .toSet();

                          filtered.sort((a, b) {
                            final aSelected =
                                selectedIds.contains(a['user_id'].toString())
                                    ? 0
                                    : 1;
                            final bSelected =
                                selectedIds.contains(b['user_id'].toString())
                                    ? 0
                                    : 1;
                            return aSelected.compareTo(bSelected);
                          });

                          return filtered;
                        },
                        selectedItems: tempSelectedTagUsers,
                        itemAsString:
                            (user) =>
                                user['user_name'] ??
                                user['full_name'] ??
                                'Unknown',
                        dropdownBuilder: (context, selectedItems) {
                          return Wrap(
                            spacing: 6,
                            children:
                                tempSelectedTagUsers.map((user) {
                                  final userName =
                                      user['user_name'] ??
                                      user['full_name'] ??
                                      'Unknown';
                                  return Chip(
                                    label: Text(userName),
                                    onDeleted: () {
                                      setModalState(() {
                                        tempSelectedTagUsers.remove(user);
                                        tempSelectedTagUserIds.remove(
                                          user['user_id'].toString(),
                                        );
                                        dropdownSearchKey.currentState
                                            ?.changeSelectedItems(
                                              tempSelectedTagUsers,
                                            );
                                      });
                                    },
                                  );
                                }).toList(),
                          );
                        },
                        onChanged: (List<Map<String, dynamic>> users) {
                          setModalState(() {
                            tempSelectedTagUsers = users;
                            tempSelectedTagUserIds =
                                users
                                    .map((e) => e['user_id'].toString())
                                    .where((id) => id.isNotEmpty)
                                    .toList();
                          });
                        },
                        popupProps: PopupPropsMultiSelection.modalBottomSheet(
                          showSearchBox: true,
                          onItemRemoved: (selectedItems, removedItem) {
                            setModalState(() {
                              tempSelectedTagUserIds.remove(
                                removedItem['user_id'].toString(),
                              );
                              tempSelectedTagUsers.removeWhere(
                                (user) =>
                                    user['user_id'].toString() ==
                                    removedItem['user_id'].toString(),
                              );
                            });
                          },
                          onItemAdded: (selectedItems, addedItem) {
                            setModalState(() {
                              tempSelectedTagUserIds.add(
                                addedItem['user_id'].toString(),
                              );
                              tempSelectedTagUsers.add(addedItem);
                            });
                          },
                          itemBuilder: (context, item, isDisabled, isSelected) {
                            final bool selected = tempSelectedTagUserIds
                                .contains(item['user_id'].toString());
                            final userName =
                                item['user_name'] ??
                                item['full_name'] ??
                                'Unknown';

                            return InkWell(
                              onTap: () {
                                setModalState(() {
                                  if (selected) {
                                    tempSelectedTagUsers.removeWhere(
                                      (u) =>
                                          u['user_id'].toString() ==
                                          item['user_id'].toString(),
                                    );
                                    tempSelectedTagUserIds.remove(
                                      item['user_id'].toString(),
                                    );
                                  } else {
                                    tempSelectedTagUsers.add(item);
                                    tempSelectedTagUserIds.add(
                                      item['user_id'].toString(),
                                    );
                                  }
                                  dropdownSearchKey.currentState
                                      ?.changeSelectedItems(
                                        tempSelectedTagUsers,
                                      );
                                });
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
                                                        : Colors.grey.shade400,
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
                                  userName,
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
                                if (tempSelectedTagUsers.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 18,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFE6EEFB),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  selectedAssignToId = null;
                                  selectedAssignToName = null;
                                  tempSelectedTagUsers.clear();
                                  tempSelectedTagUserIds.clear();
                                  dropdownSearchKey.currentState
                                      ?.changeSelectedItems([]);
                                });
                              },
                              child: Text(
                                "Clear",
                                style: TextStyle(color: AppColors.gray),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.appBar,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                // Update the parent widget's state with the selected values
                                setState(() {
                                  if (selectedAssignToId != null &&
                                      selectedAssignToName != null) {
                                    _selectedUserId = selectedAssignToId;
                                    _selectedUserName = selectedAssignToName;
                                  }
                                  selectedTagForUsers = List.from(
                                    tempSelectedTagUsers,
                                  );
                                });
                                Navigator.pop(context);
                              },
                              child: Text("Apply"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showCalendarBottomSheet(BuildContext context) async {
    DateTime? _rangeStart;
    DateTime? _rangeEnd;
    DateTime _focusedDay = DateTime.now();
    RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
    if (assignDateController.text.isNotEmpty) {
      try {
        _rangeStart = DateFormat('yyyy-MM-dd').parse(assignDateController.text);
        _focusedDay = _rangeStart!;
      } catch (e) {
        print('Error parsing existing date: $e');
      }
    }
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
              builder: (context, scrollController) {
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
                      if (_rangeStart != null && _rangeEnd != null) {
                        final startStr = DateFormat(
                          'MMM dd, yyyy',
                        ).format(_rangeStart!);
                        final endStr = DateFormat('MMM dd, yyyy').format(_rangeEnd!);
                        final rangeStr = '$startStr - $endStr';

                        setModalState(() {
                          assignDateController.text = rangeStr;
                          _dateRangeController.text = rangeStr;
                        });
                      } else {
                        assignDateController.clear();
                        _dateRangeController.clear();
                      }
                    }

                    return Container(
                      height: MediaQuery.of(context).size.height * 0.9,
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),

                            /// Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Select Date Range',
                                  style: GoogleFonts.lato(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            /// Calendar
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
                                    _rangeEnd = selectedDay;
                                  } else {
                                    _rangeStart = selectedDay;
                                    _rangeEnd = null;
                                  }

                                  _rangeSelectionMode = RangeSelectionMode.toggledOn;
                                  _updateRangeText(); // 👈 updates both controllers
                                });
                              },
                              headerStyle: const HeaderStyle(
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

                            /// Selected Range Field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SvgPicture.asset(AppImages.calendarSvg),
                                    const SizedBox(width: 11),
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
                                  controller: _dateRangeController,
                                  readOnly: true,
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

                            const SizedBox(height: 11),

                            /// Estimated Hours Field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SvgPicture.asset(AppImages.ClockSvg),
                                    const SizedBox(width: 11),
                                    Text(
                                      'Actual Hours Taken',
                                      style: GoogleFonts.lato(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 11),
                                TextFormField(
                                  controller: _estimatedHoursController,
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
                                        width: 0.8,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: AppColors.appBar,
                                        width: 0.8,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 0.8,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 0.8,
                                      ),
                                    ),
                                  ),
                                  style: GoogleFonts.lato(
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

                            /// Done/Cancel Button
                            bottomButton(
                              title: 'Done',
                              subtitle: 'Cancel',
                              icon: Icons.done,
                              icons: Icons.cancel_outlined,
                              onPress: () {
                                if (_rangeStart != null &&
                                    _rangeEnd != null &&
                                    _estimatedHoursController.text.isNotEmpty) {
                                  setState(() {
                                    isUserSelectedDateAndHours = true;
                                    actualDaysController.text =
                                        '${DateFormat('MMM dd, yyyy').format(_rangeStart!)} - ${DateFormat('MMM dd, yyyy').format(_rangeEnd!)} | ${_estimatedHoursController.text} Hours';

                                    // Store the dates in API format
                                    assignDateController.text = DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(_rangeStart!);
                                    _estimatedHoursController.text =
                                        _estimatedHoursController.text;
                                  });
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Please select both date range and hours',
                                      ),
                                    ),
                                  );
                                }
                              },
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }
          ),
        );
      },
    );
  }
}
