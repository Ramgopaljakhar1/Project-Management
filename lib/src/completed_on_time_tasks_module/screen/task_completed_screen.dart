import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
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

import '../../common_widgets/appbar.dart';
import '../../common_widgets/common_bottom_button.dart';
import '../../common_widgets/common_shimmer_loader.dart';
import '../../common_widgets/common_text_lable_field.dart';
import '../../common_widgets/custom_snackbar.dart';
import '../../task_module/controller/task_detail_controller.dart';
import '../../task_module/widgets/assign_widget.dart';
import '../../utils/colors.dart';
import '../../utils/img.dart';
import '../../utils/no_internet_connectivity.dart';
import '../../view_my_task/controller/view_my_task_controller.dart';
import '../widgets/completed_view_collapse.dart';

class TaskCompletedScreen extends StatefulWidget {
  final Map<String, dynamic> taskData;
  final String? previousScreenTitle;

  const TaskCompletedScreen({
    super.key,
    required this.taskData,
    required this.previousScreenTitle,
  });

  @override
  State<TaskCompletedScreen> createState() => _TaskCompletedScreenState();
}

class _TaskCompletedScreenState extends State<TaskCompletedScreen> {
  bool isDetailsExpanded = false;
  final ImagePicker _picker = ImagePicker();
  File? _uploadedFile;
  String? _uploadedFileUrl;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ViewMyTaskController>(
        context,
        listen: false,
      ).initializeAndFetchTask(taskId.toString());
    });

    projectNameController.text =
        widget.taskData['project_name'].toString() ?? '';
    print("Incoming project_name: ${widget.taskData['project_name']}");
    print("Incoming Task Id: ${widget.taskData['id']}");
    _initConnectivity();
    // ✅ If file comes from API
    if (widget.taskData['task_docs'] != null &&
        widget.taskData['task_docs'] != '') {
      _uploadedFileUrl = widget.taskData['task_docs'];
    }
    if (widget.taskData['assign_to_remark'] != null) {
      remark.text = widget.taskData['assign_to_remark'];
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
  }

  void updateActualDays() {
    final date = _dateRangeController.text;
    final hours = actualHoursController.text;
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
            appBar: customAppBar(context, title: 'Loading...', showBack: true,showLogo: false),
            body: Center(child: buildShimmerLoader()),
          );
        }

        final task = controller.task ?? widget.taskData;
        final taskId = task['id']?.toString() ?? 'N/A';
        final ticketId = task['ticket_id']?.toString() ?? 'N/A';
        if (task == null || task.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.white,
            appBar: customAppBar(
              context,
              title: 'Task Not Found',
              showBack: true,showLogo: false
            ),
            body: const Center(child: Text('Task details not available')),
          );
        }
        if (remark.text.isEmpty && task['assign_to_remark'] != null) {
          remark.text = task['assign_to_remark'];
          print('remark Data : ${remark.text}');
        }
        return _isNetworkAvailable
            ? Scaffold(
              appBar: customAppBar(
                context,
                title: widget.previousScreenTitle ?? 'Task Details',
                showBack: true,
                showLogo: false
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
                                // print('object....');
                              },
                              child: buildRichText(
                                'Ticket ID',
                                '${task['ticket_id'] ?? '-'}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        //Task Name Field
                        textLabelFormField(
                          controller:TextEditingController(text:task['task_name']),
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

                        /// ✅ Add Details Collapse Section
                        CompletedViewCollapse(
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
                          selectedPriority:
                              task['priority_lookupdet_desc'] ?? '',
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
                        //Assign To section
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // Align texts left
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(AppImages.assignToSvg),
                                const SizedBox(
                                  width: 8,
                                ), // Add spacing between icon and text
                                const Text('Assign To'),
                              ],
                            ),
                            SizedBox(
                              height: 11,
                            ), // Spacing between label and value
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11.0,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                    width: 0.8,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    task['assign_to_user_name'] ??
                                        'No Assignee',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // assignToUser(
                        //   context,
                        //   showAssignToSection: true,
                        //   showTagSection: true,
                        //   taskDetail: context.read<TaskDetailController>(),
                        //   onAssignToTap: () {},
                        //   onTagUserUpdated: () => setState(() {}),
                        //   showCollapseIcon: false,
                        // ),
                        SizedBox(height: 11),
                        Padding(
                          padding: const EdgeInsets.only(left: 11.0),
                          child: Column(
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
                                    'Users Tagged for Notification :',
                                    style: GoogleFonts.lato(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF333333),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // ✅ Show each username in its own container
                              if (task['notifications_notify_to'] != null &&
                                  task['notifications_notify_to'] is List &&
                                  (task['notifications_notify_to'] as List)
                                      .isNotEmpty)
                                Wrap(
                                  spacing: 8, // space between chips
                                  runSpacing:
                                      8, // space between lines if wrapped
                                  children:
                                      (task['notifications_notify_to'] as List)
                                          .map((user) {
                                            final username =
                                                user['full_name']?.toString() ??
                                                '';
                                            if (username.isEmpty)
                                              return const SizedBox();
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Colors.grey.shade400,
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Text(
                                                username,
                                                style: GoogleFonts.lato(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            );
                                          })
                                          .toList(),
                                ),
                              // else
                              //   Text(
                              //     'No users tagged',
                              //     style: GoogleFonts.lato(
                              //       fontSize: 13,
                              //       fontWeight: FontWeight.w400,
                              //       color: Colors.grey[700],
                              //     ),
                              //   ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),
                        Divider(),
                        const SizedBox(height: 22),
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
                                  'Actual Date & Hours',
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
                                      '${task['actual_est_start_date'] != null && task['actual_est_start_date'].toString().isNotEmpty ? DateFormat('d MMMM yyyy').format(DateTime.parse(task['actual_est_start_date'])) : '-'}'
                                      ' - '
                                      '${task['actual_est_end_date'] != null && task['actual_est_end_date'].toString().isNotEmpty ? DateFormat('d MMMM yyyy').format(DateTime.parse(task['actual_est_end_date'])) : '-'}'
                                      '  |  '
                                      '${task['actual_est_hrs'] != null ? task['actual_est_hrs'].toString() : '-'} Hours',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const SizedBox(height: 18),
                            Column(
                              children: [
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
                                SizedBox(height: 11),
                                Padding(
                                  padding: const EdgeInsets.only(left: 6.0),
                                  child: TextFormField(
                                    controller: remark,
                                    readOnly: true, // ✅ User cannot edit
                                    maxLines:
                                        null, // ✅ Auto-expand depending on content
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.grey,
                                          width: 0.8,
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
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            if (task['task_docs_re'] != null &&
                                task['task_docs_re'].toString().isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 13),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Image.asset(AppImages.pdf),

                                    SizedBox(width: 12),

                                    // File Name + Size
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "File",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            "Size: 1.5 MB",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // View Button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_red_eye,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () async {
                                        final url = task['task_docs_re'];
                                        if (url != null &&
                                            url.toString().isNotEmpty) {
                                          final extension =
                                              url.split('.').last.toLowerCase();

                                          if ([
                                            "png",
                                            "jpg",
                                            "jpeg",
                                          ].contains(extension)) {
                                            // ✅ Image files -> show inside app
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => Scaffold(
                                                      appBar: AppBar(
                                                        title: Text("Preview"),
                                                      ),
                                                      body: Center(
                                                        child:
                                                            InteractiveViewer(
                                                              child:
                                                                  Image.network(
                                                                    url,
                                                                  ),
                                                            ),
                                                      ),
                                                    ),
                                              ),
                                            );
                                          } else {
                                            // ✅ Other files (PDF, DOC, etc) -> download + open with OpenFile
                                            try {
                                              final uri = Uri.parse(url);
                                              final response = await http.get(
                                                uri,
                                              );

                                              if (response.statusCode == 200) {
                                                final tempDir =
                                                    Directory.systemTemp;
                                                final filePath =
                                                    '${tempDir.path}/${uri.pathSegments.last}';
                                                final file = File(filePath);
                                                await file.writeAsBytes(
                                                  response.bodyBytes,
                                                );

                                                await OpenFile.open(file.path);
                                              } else {
                                                throw Exception(
                                                  "Failed to download file",
                                                );
                                              }
                                            } catch (e) {
                                              debugPrint(
                                                'Error opening file: $e',
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Could not open file',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                      ],
                    ),
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
      },
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

  Future<void> _showCalendarBottomSheet(BuildContext context) async {
    DateTime _focusedDay = DateTime.now();
    RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void _updateRangeText() {
              if (_rangeStart != null && _rangeEnd != null) {
                final startStr = DateFormat(
                  'MMM dd, yyyy',
                ).format(_rangeStart!);
                final endStr = DateFormat('MMM dd, yyyy').format(_rangeEnd!);
                _dateRangeController.text = '$startStr - $endStr';
              } else {
                _dateRangeController.clear();
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
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
                      // onDaySelected: (selectedDay, focusedDay) {
                      //   setModalState(() {
                      //     _focusedDay = focusedDay;
                      //
                      //     if (_rangeSelectionMode ==
                      //             RangeSelectionMode.toggledOn &&
                      //         _rangeStart != null &&
                      //         _rangeEnd == null &&
                      //         selectedDay.isAfter(_rangeStart!)) {
                      //       _rangeEnd = selectedDay;
                      //     } else {
                      //       _rangeStart = selectedDay;
                      //       _rangeEnd = null;
                      //     }
                      //
                      //     _rangeSelectionMode = RangeSelectionMode.toggledOn;
                      //     _updateRangeText(); // 👈 update field
                      //   });
                      // },
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
                          controller: _dateRangeController,
                          readOnly: true,
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
                    SizedBox(height: 11),

                    /// Text Field Showing Estimated Hours
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
                        SizedBox(height: 11),
                        TextFormField(
                          controller: actualHoursController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            // suffix: Text(
                            //   'Hours',
                            //   style: GoogleFonts.lato(
                            //     fontSize: 14,
                            //     fontWeight: FontWeight.w500,
                            //     color: Colors.black,
                            //   ),
                            // ),
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
                    //   const Spacer(),

                    /// Bottom Buttons
                    bottomButton(
                      title: 'Done',
                      subtitle: 'Cancel',
                      icon: Icons.done,
                      icons: Icons.cancel_outlined,
                      onPress: () {
                        print("Start: $_rangeStart");
                        print("End: $_rangeEnd");
                        print(
                          'date Range Controller : ${_dateRangeController.text}',
                        );
                        Navigator.pop(context);
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
        );
      },
    );
  }

  Widget _buildFileIcon(String url) {
    final extension = url.split('.').last.toLowerCase();

    if (["png", "jpg", "jpeg"].contains(extension)) {
      return const Icon(Icons.image, size: 40, color: Colors.orange);
    } else if (extension == "pdf") {
      return const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red);
    } else if (["doc", "docx"].contains(extension)) {
      return const Icon(Icons.description, size: 40, color: Colors.blue);
    } else {
      return const Icon(Icons.insert_drive_file, size: 40, color: Colors.grey);
    }
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
