import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:project_management/src/view_ticket_module/screen/view_ticket_id_details.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common_widgets/add_details_collapse.dart';
import '../../common_widgets/appbar.dart';
import '../../common_widgets/common_bottom_button.dart';
import '../../common_widgets/common_shimmer_loader.dart';
import '../../common_widgets/common_text_lable_field.dart';
import '../../common_widgets/custom_snackbar.dart';
import '../../common_widgets/lodar.dart';
import '../../common_widgets/text_form_field.dart';
import '../../task_module/controller/task_detail_controller.dart';
import '../../task_module/widgets/assign_widget.dart';
import '../../utils/colors.dart';
import '../../utils/img.dart';
import '../controller/view_my_task_controller.dart';
import '../widgets/dotted_border.dart';
import '../widgets/view_details_collapse.dart';

class ViewMyTaskScreen extends StatefulWidget {
  final Map<String, dynamic> taskData;
  final String source;
  final bool showEditButton;

  const ViewMyTaskScreen({
    super.key,
    required this.taskData,
    required this.source,
    this.showEditButton = false,
  });

  @override
  State<ViewMyTaskScreen> createState() => _ViewMyTaskScreenState();
}

class _ViewMyTaskScreenState extends State<ViewMyTaskScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  bool isDetailsExpanded = false;
  final ImagePicker _picker = ImagePicker();
  File? _uploadedFile;
  String? _uploadedFileUrl;
  String? _uploadedFiles_re;
  String? selectedProject;
  final List<String> projectList = [];
  final TextEditingController projectNameController = TextEditingController();
  final TextEditingController actualDaysController = TextEditingController();
  final TextEditingController actualHoursController = TextEditingController();

  final TextEditingController _dateRangeController = TextEditingController();
  final TextEditingController remark = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime _focusedDay = DateTime.now();
  bool isLoading = false;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;

  final Connectivity _connectivity = Connectivity();
  bool _isNetworkAvailable = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    actualHoursController.addListener(updateActualDays);
    final taskId =
        widget.taskData['id']?.toString() ??
        widget.taskData['taskId']?.toString();
    projectNameController.text =
        widget.taskData['project_name'].toString() ?? '';
    debugPrint("Incoming project_name: ${widget.taskData['project_name']}");

    _initConnectivity();
    // ✅ If file comes from API
    if (widget.taskData['task_docs'] != null &&
        widget.taskData['task_docs'] != '') {
      _uploadedFileUrl = widget.taskData['task_docs'];

    }


    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ViewMyTaskController>(
        context,
        listen: false,
      ).initializeAndFetchTask(taskId!);
    });
    // Initialize actual dates and hours if they exist
    if (widget.taskData['actual_est_start_date'] != null &&
        widget.taskData['actual_est_end_date'] != null) {
      try {
        _rangeStart = DateTime.parse(widget.taskData['actual_est_start_date']);
        _rangeEnd = DateTime.parse(widget.taskData['actual_est_end_date']);
        _updateDateRangeText();
      } catch (e) {
        debugPrint("Error parsing actual dates: $e");
      }
    }

    if (widget.taskData['actual_est_hrs'] != null) {
      actualHoursController.text = widget.taskData['actual_est_hrs'].toString();
    }

    if (widget.taskData['assign_to_remark'] != null) {
      remark.text = widget.taskData['assign_to_remark'].toString();
    }
    _initializeDataFromTask();
  }

  void updateActualDays() {
    final date = _dateRangeController.text;
    final hours = actualHoursController.text;
    if (date.isNotEmpty && hours.isNotEmpty) {
      actualDaysController.text = '$date | $hours Hours';
    } else {
      actualDaysController.text = '';
    }
    debugPrint('actual Days Controller : ${actualDaysController.text}');
  }

  void _updateDateRangeText() {
    if (_rangeStart != null && _rangeEnd != null) {
      _dateRangeController.text =
          "${DateFormat('d MMMM yyyy').format(_rangeStart!)} - ${DateFormat('d MMMM yyyy').format(_rangeEnd!)}";
      actualDaysController.text =
          "${DateFormat('d MMMM yyyy').format(_rangeStart!)} - ${DateFormat('d MMMM yyyy').format(_rangeEnd!)} | ${actualHoursController.text} Hours";
    }
  }

  Future<void> _initConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }

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

  void _showPickOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Open Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile(ImageSource.camera); // ✅ use source
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile(ImageSource.gallery); // ✅ use source
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: const Text('Browse File'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile(); // ✅ file picker (pdf/zip etc.)
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickFile([ImageSource? source]) async {
    try {
      if (source != null) {
        // Camera or Gallery
        final XFile? image = await _picker.pickImage(source: source);

        if (image != null) {
          final file = File(image.path);
          final fileSize = await file.length();

          if (fileSize > 25 * 1024 * 1024) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("File size should not exceed 25 MB."),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          setState(() {
            _uploadedFile = file;
            _uploadedFileUrl = null;
          });
        }
      } else {
        // File Picker (for PDF, DWG, ZIP, etc.)
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'dwg', 'zip'],
          allowMultiple: false,
          withData: true,
        );

        if (result != null && result.files.single.bytes != null) {
          final file = result.files.single;
          final fileSize = file.size;

          if (fileSize > 25 * 1024 * 1024) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("File size should not exceed 25 MB."),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final path = file.path;
          if (path != null) {
            setState(() {
              _uploadedFile = File(path);
              _uploadedFileUrl = null;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateRangeController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  // Future<void> _selectTime(BuildContext context) async {
  //   final TimeOfDay? picked = await showTimePicker(
  //     context: context,
  //     initialTime: TimeOfDay.now(),
  //   );
  //   if (picked != null) {
  //     setState(() {
  //       _selectedTime = picked;
  //       actualHoursController.text = picked.format(context);
  //     });
  //   }
  // }
  Future<void> _saveTask() async {
    if (actualDaysController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.appBar,
          content: Text('Please enter actual days'),
        ),
      );
      return;
    }
    if (actualHoursController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.appBar,
          content: Text('Please enter actual hours'),
        ),
      );
      return;
    }
    if (remark.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.appBar,
          content: Text('Please enter remarks'),
        ),
      );
      return;
    }
    if (_rangeStart == null || _rangeEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.appBar,
          content: Text('Please select actual date range'),
        ),
      );
      return;
    }

    final taskId =
        widget.taskData['id']?.toString() ??
        widget.taskData['taskId']?.toString();
    final controller = Provider.of<ViewMyTaskController>(
      context,
      listen: false,
    );

    final formattedStartDate = DateFormat('yyyy-MM-dd').format(_rangeStart!);
    final formattedEndDate = DateFormat('yyyy-MM-dd').format(_rangeEnd!);

    final Map<String, dynamic> requestData = {
      "task_id": taskId,
      "actual_est_hrs": actualHoursController.text,
      "actual_est_start_date": formattedStartDate,
      "actual_est_end_date": formattedEndDate,
      "assign_to_remark": remark.text,
      if (widget.taskData['est_hrs'] != null)
        "est_hrs": widget.taskData['est_hrs'].toString(),
      if (widget.taskData['est_start_date'] != null)
        "est_start_date": widget.taskData['est_start_date'],
      if (widget.taskData['est_end_date'] != null)
        "est_end_date": widget.taskData['est_end_date'],
    };

    debugPrint('📤 Request data (before sending to API): $requestData');

    try {
      // Show loader
      setState(() => isLoading = true);

      // Handle existing file conversion if no new file is uploaded
      File? fileToSend = _uploadedFile;

      // If no new file but existing file URL exists, download and convert to base64
      if (_uploadedFile == null &&
          _uploadedFileUrl != null &&
          _uploadedFileUrl!.isNotEmpty) {
        try {
          debugPrint('🔄 Converting existing file URL to base64: $_uploadedFileUrl');
          final fileBytes = await _downloadFileFromUrl(_uploadedFileUrl!);
          if (fileBytes != null) {
            // Create a temporary file
            final tempDir = Directory.systemTemp;
            final fileName = _uploadedFileUrl!.split('/').last;
            final tempFile = File('${tempDir.path}/$fileName');
            await tempFile.writeAsBytes(fileBytes);
            fileToSend = tempFile;
            debugPrint('✅ Existing file downloaded and ready for upload');
          }
        } catch (e) {
          debugPrint('❌ Error processing existing file: $e');
        }
      }

      // Await API call properly
      final response = await controller.updateTask(
        taskId: taskId.toString(),
        existingTaskData: requestData,
        file: fileToSend, // file is included here
      );

      debugPrint('✅ API Response: $response');

      CustomSnackBar.successSnackBar(
        context,
        response['message'] ?? 'Task updated',
      );

      // Update local task data
      widget.taskData['actual_est_hrs'] = actualHoursController.text;
      widget.taskData['actual_est_start_date'] = formattedStartDate;
      widget.taskData['actual_est_end_date'] = formattedEndDate;
      widget.taskData['assign_to_remark'] = remark.text;

      setState(() {
        _initializeDataFromTask();
        _uploadedFile = null; // clear file after successful upload if needed
      });
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('❌ Error saving task: $e');
      CustomSnackBar.errorSnackBar(context, e.toString());
    } finally {
      // Hide loader in all cases
      setState(() => isLoading = false);
    }
  }

  void _initializeDataFromTask() {
   final taskcontroller = Provider.of<ViewMyTaskController>(
      context,
      listen: false,
    );

    if (widget.taskData['actual_est_start_date'] != null &&
        widget.taskData['actual_est_end_date'] != null) {
      try {
        _rangeStart = DateTime.parse(widget.taskData['actual_est_start_date']);
        _rangeEnd = DateTime.parse(widget.taskData['actual_est_end_date']);
        _updateDateRangeText();
      } catch (e) {
        debugPrint("Error parsing actual dates: $e");
      }
    }

    if (widget.taskData['actual_est_hrs'] != null) {
      actualHoursController.text = widget.taskData['actual_est_hrs'].toString();
    }

    // FIX: Always update the remark controller with current data
    if (widget.taskData['assign_to_remark'] != null &&
        widget.taskData['assign_to_remark'].toString().isNotEmpty) {

      // ✅ 1️⃣ Widget se remark mila → wahi show karo
      remark.text = widget.taskData['assign_to_remark'].toString();

    } else if (taskcontroller.task?['assign_to_remark'] != null &&
        taskcontroller.task!['assign_to_remark'].toString().isNotEmpty) {

      // ✅ 2️⃣ Widget se nahi mila → task list se show karo
      remark.text = taskcontroller.task!['assign_to_remark'].toString();

    } else {

      // ✅ 3️⃣ Dono jagah se nahi mila → clear
      remark.clear();
    }

  }

  Future<Uint8List?> _downloadFileFromUrl(String url) async {
    try {
      debugPrint('📥 Downloading file from URL: $url');

      // Check if it's a valid URL
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.isAbsolute) {
        debugPrint('❌ Invalid URL: $url');
        return null;
      }

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        debugPrint(
          '✅ File downloaded successfully, size: ${response.bodyBytes.length} bytes',
        );
        return response.bodyBytes;
      } else {
        debugPrint('❌ Failed to download file, status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error downloading file: $e');
      return null;
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
    actualHoursController.removeListener(updateActualDays);
    _dateRangeController.dispose();
    actualHoursController.dispose();
    actualDaysController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ViewMyTaskController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return Scaffold(
            appBar: customAppBar(context, title: 'Loading...', showBack: true),
            body: Center(child: buildShimmerLoader()),
          );
        }

        final task = controller.task;
      //  debugPrint('task docs re : ${task!["task_docs_re"]}');
        _uploadedFiles_re = task!["task_docs_re"];

        debugPrint('task docs re-- : ${_uploadedFiles_re}');
        debugPrint('assign_to_remark-- : ${ task["assign_to_remark"]}');
        if (task == null) {
          return Scaffold(
            backgroundColor: AppColors.white,
            appBar: customAppBar(
              context,
              title: 'Task Not Found',
              showBack: true,
            ),
            body: const Center(child: Text('Task details not available')),
          );
        }
        final bool hasActualDates =
            task['actual_est_start_date'] != null &&
            task['actual_est_end_date'] != null;
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          behavior: HitTestBehavior.opaque,
          child: Scaffold(
            appBar: customAppBar(
              showLogo: false,
              context,
              title: 'View My Task',
              showBack: true,
            ),
            body: Padding(
              padding: const EdgeInsets.all(13),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: ListView(
                    children: [
                      Row(
                        children: [
                          buildRichText('Task ID', '${task['id'] ?? '-'}'),
                          const SizedBox(width: 13),
                          GestureDetector(
                            onTap:() {
                              _navigateToTicketDetails(task['ticket_id'].toString(),task['id'].toString());
                             // debugPrint('object....');
                            },
                            child: buildRichText(
                              'Ticket ID',
                              '${task['ticket_id'] ?? '-'}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Task Name Field
                      textLabelFormField(
                        controller:TextEditingController(text: task['task_name'] ?? ''),
                        readOnly: true,
                        img: AppImages.addTaskSvg,
                        taskName: 'Task Name',
                        hintText: task['task_name'] ?? '',
                        onChanged: (_) {},
                        borderColor: Colors.grey,
                        prefixIconColor: Colors.black,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 16),

                      // Add Details Collapse
                      /// ✅ Add Details Collapse Section
                      ViewDetailsCollapse(
                        context: context,
                        // prefixIconImage: AppImages.descriptionSvg,
                        onPress: () {
                          setState(
                            () => isDetailsExpanded = !isDetailsExpanded,
                          );
                        },
                        isExpanded: isDetailsExpanded,
                        title: 'Add Details',
                        img: AppImages.descriptionSvg,
                        hintText: task['description'] ?? '',
                        showCollapseIcon: false,
                        controller: TextEditingController(
                          text: task['task_detail'],
                        ),
                        readOnly: true,
                        projectList: projectList,
                        selectedProject: task['project_lookupdet_desc'],
                        onChange: (_) {},
                        showDropdownForProjectName: false,
                        //uploadedFile: _uploadedFile,
                        uploadedFileUrl: task['task_docs'],
                        onDeleteFile: () {
                          setState(() {
                            _uploadedFile = null;
                            _uploadedFileUrl = null;
                          });
                        },
                        onUploadPress:
                            () {}, // leave empty or implement if needed
                        selectedPriority: task['priority_lookupdet_desc'] ?? '',
                        onPriorityChange: (_) {},
                      ),

                      const SizedBox(height: 18),

                      // Date & Time
                      Column(
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset(
                                AppImages.dateTimeSvg,
                                width: 22,
                                height: 22,
                                color: AppColors.black,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Estimated Dates & Hours',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 11),
                          Row(
                            children: [
                              // SvgPicture.asset(
                              //   AppImages.dateTimeSvg,
                              //   width: 22,
                              //   height: 22,
                              //   fit: BoxFit.cover,
                              //   color: AppColors.black,
                              // ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                      width: 0.8,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${task['est_start_date'] != null && task['est_start_date'].toString().isNotEmpty ? DateFormat('d MMMM yyyy').format(DateTime.parse(task['est_start_date'])) : '-'}'
                                    ' - '
                                    '${task['est_end_date'] != null && task['est_end_date'].toString().isNotEmpty ? DateFormat('d MMMM yyyy').format(DateTime.parse(task['est_end_date'])) : '-'}'
                                    '  |  '
                                    '${task['est_hrs'] != null ? task['est_hrs'].toString() : '-'} Hours',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Replace your existing "Actual Days Taken" and "Actual Hours Taken" Row widgets with:

                      /// Actual Days Taken
                      // Row(
                      //   children: [
                      //     SvgPicture.asset(AppImages.calendarSvg, width: 22, height: 22, color: AppColors.black),
                      //     const SizedBox(width: 8),
                      //     Expanded(
                      //       child: GestureDetector(
                      //         onTap: () => _selectDate(context),
                      //         child: AbsorbPointer(
                      //           child: TextFormField(
                      //             controller: actualDaysController,
                      //             decoration: InputDecoration(
                      //               hintText: 'Select Actual Days Taken',
                      //               border: OutlineInputBorder(
                      //                 borderRadius: BorderRadius.circular(12),
                      //                 borderSide: const BorderSide(
                      //                   color: Colors.grey,
                      //                   width: 0.8,
                      //                 ),
                      //               ),
                      //               enabledBorder: OutlineInputBorder(
                      //                 borderRadius: BorderRadius.circular(12),
                      //                 borderSide: const BorderSide(
                      //                   color: Colors.grey,
                      //                   width: 0.8,
                      //                 ),
                      //               ),
                      //               focusedBorder: OutlineInputBorder(
                      //                 borderRadius: BorderRadius.circular(12),
                      //                 borderSide: const BorderSide(
                      //                   color: Colors.grey,
                      //                   width: 0.8,
                      //                 ),
                      //               ),
                      //               filled: true,
                      //               fillColor: AppColors.white,
                      //               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      //               // prefixIcon: Padding(
                      //               //   padding: const EdgeInsets.all(12.0),
                      //               //   child: SvgPicture.asset(AppImages.calendarSvg, width: 22, height: 22),
                      //               // ),
                      //             ),
                      //           ),
                      //         ),
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      const SizedBox(height: 18),

                      ///Actual Days Taken
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset(
                                AppImages.calendarSvg,
                                width: 22,
                                height: 22,
                                color: AppColors.black,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Actual Dates & Hours',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 11),

                          // Display existing actual dates or allow selection
                          if (hasActualDates)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 0.8,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${DateFormat('d MMMM yyyy').format(DateTime.parse(task['actual_est_start_date']))}'
                                ' - '
                                '${DateFormat('d MMMM yyyy').format(DateTime.parse(task['actual_est_end_date']))}'
                                '  |  '
                                '${task['actual_est_hrs'] ?? '-'} Hours',
                                style: const TextStyle(fontSize: 14,),
                              ),
                            )
                          else
                            textLabelFormField(
                              controller: actualDaysController,
                              readOnly: true,
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                _showCalendarBottomSheet(context);
                              },
                              hintText: 'Select Actual Days Taken',
                              borderColor: Colors.grey.shade400,
                              backgroundColor: AppColors.white,
                              titleColor: AppColors.black.withOpacity(0.67),
                              img: AppImages.calendarSvg,
                              prefixIconColor: AppColors.black,
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      //                     ///Actual Hours Taken
                      //                     Row(
                      //                       children: [
                      //                         SvgPicture.asset(AppImages.ClockSvg,width: 22,height: 22,color:AppColors.black,),
                      //                         SizedBox(width: 8,),
                      //                         Expanded(
                      //                           child: textLabelFormField(
                      // onTap: () {
                      //
                      // },
                      //                             //   padding:EdgeInsets.symmetric(vertical: 21),
                      //                             //context: context,
                      //                             hintText: 'Select Actual Hours Taken',
                      //                             borderColor: Colors.grey.shade400,
                      //                             backgroundColor: AppColors.white,
                      //                             titleColor: AppColors.black,
                      //                             img: AppImages.calendarSvg,
                      //                             prefixIconColor: AppColors.black,
                      //                             //   prefixIconPadding: EdgeInsets.symmetric(vertical: 11),
                      //                           ),
                      //                         ),
                      //                       ],
                      //                     ),
                      //                     const SizedBox(height: 18),
                      // assignToUser(
                      //   context,
                      //   showAssignToSection: false,
                      //   showTagSection: true,
                      //   taskDetail: context.read<TaskDetailController>(),
                      //   onAssignToTap: () {},
                      //   onTagUserUpdated: () => setState(() {}),
                      //   showCollapseIcon: false,
                      // ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset(
                                AppImages.tagUserSvg,
                                color: AppColors.black,
                                width: 22,
                                height: 22,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'Users Tagged for Notification:',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Show the list of tagged users
                          if (task['notifications_notify_to'] != null &&
                              task['notifications_notify_to'].isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(10),
                                //  border: Border.all(color: Colors.grey.shade400, width: 0.8),
                              ),
                              child: Wrap(
                                // Wrap ka use taake gap ke sath multiple lines me aaye
                                spacing: 8, // Horizontal gap between containers
                                runSpacing: 8, // Vertical gap between lines
                                children: [
                                  for (var user
                                      in task['notifications_notify_to'])
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                          width: 0.8,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey.shade100,
                                      ),
                                      child: Text(
                                        user['full_name'] ?? 'Unknown',
                                        style: GoogleFonts.lato(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              AppImages.descriptionSvg,
                              color: Colors.black,
                              width: 22,
                              height: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Assignee Remark',
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 11),
                      TextFormField(
                        controller: remark,
                        maxLines: 3,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.grey, // 👈 Border color
                              width: 0.8, // 👈 Border thickness
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 0.8,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 0.8,
                            ),
                          ),
                        ),
                      ),

                      // const SizedBox(height: 18),
                      // Divider(),
                      const SizedBox(height: 22),

                      dottedBorder(onPress: () => _showPickOptions(context)),

                      const SizedBox(height: 22),

                      if (_uploadedFile != null || _uploadedFiles_re != null)
                          Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: Colors.grey.shade400,
                  width: 0.8,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    _uploadedFile != null
                        ? Image.asset(AppImages.pdf, width: 22, height: 22)
                        : (_uploadedFiles_re != null
                        ? Image.network(
                      _uploadedFiles_re!,
                      width: 22,
                      height: 22,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.broken_image, size: 22),
                    )
                        : Icon(Icons.insert_drive_file, size: 22)),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Uploaded File",
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.gray,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          FutureBuilder<int>(
                            future: _uploadedFile != null
                                ? _getFileSize()
                                : Future.value(0),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && _uploadedFile != null) {
                                final sizeMB =
                                (snapshot.data! / (1024 * 1024)).toStringAsFixed(2);
                                return Text(
                                  'Size: $sizeMB MB',
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.gray,
                                  ),
                                );
                              } else if (_uploadedFiles_re != null) {
                                return const Text(
                                  'Remote file',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                );
                              } else {
                                return const Text('Size: --');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async {
                        if (_uploadedFile != null) {
                          final result = await OpenFile.open(_uploadedFile!.path);
                          debugPrint("Open result: ${result.message}");
                        } else if (_uploadedFiles_re != null) {
                          _showImageFullScreen(context, _uploadedFiles_re!);
                        }
                      },
                      child: SvgPicture.asset(AppImages.viewSvg),
                    ),




                  ],
                ),
              ),
            ),


              const SizedBox(height: 22),
                      //
                      isLoading
                          ? commonLoader(color: AppColors.blue, size: 28)
                          : bottomButton(
                            title: 'Save',
                            subtitle: 'Cancel',
                            icon: Icons.done,
                            icons: Icons.close,
                            onPress: _saveTask,
                            onTap: () {
                              Navigator.pop(context);
                              debugPrint('Cancel...');
                            },
                          ),

                      // Row(
                      //   children: [
                      //     _actionButton(
                      //       label: 'Close Ticket',
                      //       color: AppColors.appBar,
                      //       onPressed: () => _showSuccessDialog(context),
                      //     ),
                      //     const SizedBox(width: 12),
                      //     _actionButton(
                      //       label: 'Cancel',
                      //       color: Colors.orange,
                      //       onPressed: () => Navigator.pop(context),
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: Colors.white)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget buildRichText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600),
        children: [
          TextSpan(text: '# ', style: GoogleFonts.lato(color: Colors.grey)),
          TextSpan(
            text: '$label: ',
            style: GoogleFonts.lato(color: Colors.black),
          ),
          TextSpan(text: value, style: GoogleFonts.lato(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
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
                  'Data Saved Successfully.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Ok', style: TextStyle(color: Colors.white)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _showCalendarBottomSheet(BuildContext context) async {
    // Get estimated start date from task data
    DateTime? estimatedStartDate;
    try {
      if (widget.taskData['est_start_date'] != null &&
          widget.taskData['est_start_date'].toString().isNotEmpty) {
        estimatedStartDate = DateTime.parse(widget.taskData['est_start_date']);
      }
    } catch (e) {
      debugPrint("Error parsing estimated start date: $e");
    }

    // Set focused day to estimated start date if available, otherwise current date
    DateTime _focusedDay = estimatedStartDate ?? DateTime.now();
    RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
    DateTime? tempRangeStart = _rangeStart;
    DateTime? tempRangeEnd = _rangeEnd;

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
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    void _updateRangeText() {
                      if (tempRangeStart != null && tempRangeEnd != null) {
                        final startStr = DateFormat('MMM dd, yyyy').format(tempRangeStart!);
                        final endStr = DateFormat('MMM dd, yyyy').format(tempRangeEnd!);
                        _dateRangeController.text = '$startStr - $endStr';
                      } else {
                        _dateRangeController.clear();
                      }
                    }

                    // Determine the first selectable day
                    DateTime getFirstSelectableDay() {
                      if (estimatedStartDate != null) {
                        // Use estimated start date as minimum selectable date
                        return DateTime(
                          estimatedStartDate!.year,
                          estimatedStartDate!.month,
                          estimatedStartDate!.day,
                        );
                      }
                      return DateTime.now(); // Default to today if no estimated date
                    }

                    final firstSelectableDay = getFirstSelectableDay();

                    // Check if a date is selectable (must be on or after estimated start date)
                    bool isDateSelectable(DateTime date) {
                      // Remove time part for comparison
                      final dateOnly = DateTime(date.year, date.month, date.day);
                      final firstDayOnly = DateTime(
                        firstSelectableDay.year,
                        firstSelectableDay.month,
                        firstSelectableDay.day,
                      );

                      // Date should be on or after the estimated start date
                      return !dateOnly.isBefore(firstDayOnly);
                    }

                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),

                          /// Header with validation info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Select Date Range',
                                      style: GoogleFonts.lato(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (estimatedStartDate != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Available from: ${DateFormat('d MMMM yyyy').format(estimatedStartDate!)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          /// Calendar with date restrictions
                          TableCalendar(
                            // Show dates starting from estimated start date
                            firstDay: estimatedStartDate ?? DateTime.now(),
                            lastDay: DateTime(2100),
                            focusedDay: _focusedDay,
                            rangeStartDay: tempRangeStart,
                            rangeEndDay: tempRangeEnd,
                            rangeSelectionMode: _rangeSelectionMode,

                            onDaySelected: (selectedDay, focusedDay) {
                              setModalState(() {
                                _focusedDay = focusedDay;

                                // Check if date is selectable (must be on or after estimated start date)
                                if (!isDateSelectable(selectedDay)) {
                                  final formattedDate = DateFormat('d MMMM yyyy').format(firstSelectableDay);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Please select a date on or after $formattedDate'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                if (_rangeSelectionMode == RangeSelectionMode.toggledOn &&
                                    tempRangeStart != null &&
                                    tempRangeEnd == null) {

                                  // Check if selected end date is selectable
                                  if (!isDateSelectable(selectedDay)) {
                                    final formattedDate = DateFormat('d MMMM yyyy').format(firstSelectableDay);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('End date must be on or after $formattedDate'),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }

                                  if (selectedDay.isAfter(tempRangeStart!)) {
                                    tempRangeEnd = selectedDay;
                                  } else if (selectedDay == tempRangeStart) {
                                    // Same date selected for start and end
                                    tempRangeEnd = selectedDay;
                                  } else {
                                    // End date is before start date - swap them
                                    tempRangeEnd = tempRangeStart;
                                    tempRangeStart = selectedDay;
                                  }
                                } else if (tempRangeStart != null &&
                                    tempRangeEnd == null &&
                                    selectedDay == tempRangeStart) {
                                  // Same date clicked twice
                                  tempRangeEnd = selectedDay;
                                } else {
                                  // Start new selection
                                  tempRangeStart = selectedDay;
                                  tempRangeEnd = null;
                                }

                                _rangeSelectionMode = RangeSelectionMode.toggledOn;
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
                              // Disable dates before estimated start date
                              disabledDecoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                            ),

                            // Disable dates before the estimated start date
                            enabledDayPredicate: (day) {
                              return isDateSelectable(day);
                            },
                          ),

                          const SizedBox(height: 16),

                          /// Selected Date Range
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
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                width:double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[50],
                                ),
                                child: Text(
                                  tempRangeStart != null && tempRangeEnd != null
                                      ? '${DateFormat('d MMMM yyyy').format(tempRangeStart!)} - ${DateFormat('d MMMM yyyy').format(tempRangeEnd!)}'
                                      : 'No date range selected',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: tempRangeStart != null && tempRangeEnd != null
                                        ? Colors.black87
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 11),

                          /// Actual Hours Taken (no validation)
                          Column(
                            children: [
                              Row(
                                children: [
                                  SvgPicture.asset(AppImages.ClockSvg),
                                  SizedBox(width: 11),
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
                              SizedBox(height: 8),
                              TextFormField(
                                controller: actualHoursController,
                                keyboardType: TextInputType.number,
                                maxLength: 2,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  counterText: '',
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
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
                                  hintText: 'Enter hours',
                                ),
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          /// Bottom Buttons
                          Row(
                            children: [
                              // Cancel Button
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[200],
                                    foregroundColor: Colors.grey[800],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.close, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Cancel',
                                        style: GoogleFonts.lato(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Done Button
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.appBar,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () {
                                    // Validate before closing
                                    if (tempRangeStart == null || tempRangeEnd == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please select a date range'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    // Validate dates are on or after estimated start date
                                    if (!isDateSelectable(tempRangeStart!) || !isDateSelectable(tempRangeEnd!)) {
                                      final formattedDate = DateFormat('d MMMM yyyy').format(firstSelectableDay);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Selected dates must be on or after $formattedDate'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    // Save the selected dates
                                    setState(() {
                                      _rangeStart = tempRangeStart;
                                      _rangeEnd = tempRangeEnd;
                                      _updateDateRangeText();
                                      updateActualDays(); // Update the combined text
                                    });

                                    Navigator.pop(context);
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.done, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Done',
                                        style: GoogleFonts.lato(
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
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showImageFullScreen(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                const Center(
                  child: Icon(Icons.broken_image, size: 50, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Future<int> _getFileSize() async {
    if (_uploadedFile != null) {
      return await _uploadedFile!.length();
    } else {
      // For remote file, assume size is unknown
      return 0;
    }
  }
}
