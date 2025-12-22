import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common_widgets/custom_dropdown.dart';
import '../../common_widgets/custom_snackbar.dart';
import '../../services/api_service.dart';
import '../../services/constants/api_constants.dart';
import '../../utils/shared_pref_constants.dart';
import '../models/task_date_time_model.dart';
import '../models/task_details_model.dart';

class TaskDetailController extends ChangeNotifier {
  // --- Selected Data ---
  String? selectedUser;
  Map<String, dynamic>? selectedPriority;
  String? assignToUser;
  String? selectedAssignToUser;
  String? selectedTagUser;
  String? tagMemberUser;
  String? recurringTaskUser;
  TaskDateTimeModel? selectedDateTime;
  String? selectedProject;
  String? selectedProjectId;
  String? selectedProjectName;
  String? _currentUserId;
  TaskDetailsModel? taskDetails;








  // --- Booleans ---
  bool isDetailsExpanded = false;
  bool isAssignToExpanded = false;
  bool _isFavourite = false;
  bool _isLoading = false;
  bool isTagForNotificationExpanded = false;
  bool isTaggedExpanded = false;

  // --- Lists ---
  String? selectedAssignToUserId;

  String? selectedAssignToUserName;
  List<String> selectedTagUserIds = [];
  List<TaskDateTimeModel> dateTimeList = [];
  List<Map<String, dynamic>> priorityList = [];
  List<String> assignedUsers = [];
  List<Map<String, dynamic>> taggedUserDetails = [];
  List<String> taggedUsers = [];
  List<Map<String, dynamic>> projectList = [];
  List<Map<String, dynamic>> userList = [];
  List<Map<String, dynamic>> selectedTagUsers = [];
  Map<String, dynamic>? taskData;


  // --- Controllers ---
  final TextEditingController detailsController = TextEditingController();
  final TextEditingController assignTo = TextEditingController();
  final TextEditingController tagForNotification = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController duration = TextEditingController();


  // --- Getters ---
  bool get isLoading => _isLoading;
  bool get isFavourite => _isFavourite;
  String? get currentUserId => _currentUserId;

  // --- Setter for isFavourite ---
  set isFavourite(bool value) {
    _isFavourite = value;
    notifyListeners();
  }
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // --- Expand Toggles ---
  void toggleAssignToExpanded() {
    isAssignToExpanded = !isAssignToExpanded;
    notifyListeners();
  }
  void setSelectedProject(String? projectId, String? projectName) {
    selectedProjectId = projectId;
    selectedProjectName = projectName;
    notifyListeners();
  }
  Future<void> loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(SharedPrefConstant().kUserData);






    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      _currentUserId = userData['id']?.toString();
      debugPrint("✅ Loaded current user ID00888666: $_currentUserId");
    } else {
      debugPrint("❌ No user data found in SharedPreferences.");
    }
  }

  void setSelectedPriority(Map<String, dynamic>? priority) {
    debugPrint('🔄 Setting selected priority:');
    if (priority != null) {
      debugPrint('✅ New priority selected: ${priority['name']} (ID: ${priority['id']})');
      selectedPriority = priority;

      // Mark the selected priority in the list
      priorityList.forEach((p) {
        p['isSelected'] = p['id'] == priority['id'];
      });
    } else {
      debugPrint('ℹ️ Priority selection cleared');
      selectedPriority = null;

      // Clear all selections
      priorityList.forEach((p) {
        p['isSelected'] = false;
      });
    }
    notifyListeners();
  }
  void toggleTagForNotificationExpanded() {
    isTagForNotificationExpanded = !isTagForNotificationExpanded;
    notifyListeners();
  }
  void setAssignToUser(String? user) {
    selectedAssignToUser = user;
    notifyListeners();
  }

  void setTagUser(String? user) {
    selectedTagUser = user;
    notifyListeners();
  }
  void toggleTaggedExpanded() {
    isTaggedExpanded = !isTaggedExpanded;
    notifyListeners();
  }

  void addDateTime(TaskDateTimeModel dateTime) {
    dateTimeList.add(dateTime);
    notifyListeners();
  }

  // --- Assignment Logic ---
  void addAssignedUser(String user) {
    if (!assignedUsers.contains(user)) {
      assignedUsers.add(user);
      notifyListeners();
    }
  }

  void addAssignToFromController() {
    if (assignTo.text.trim().isNotEmpty) {
      addAssignedUser(assignTo.text.trim());
      assignTo.clear();
    }
  }

  void removeAssignedUser(String user) {
    assignedUsers.remove(user);
    notifyListeners();
  }

  // --- Tag Notification Logic ---
  void addTagForNotification(String user) {
    if (!taggedUsers.contains(user)) {
      taggedUsers.add(user);
      notifyListeners();
    }
  }

  void addTagForNotificationFromController() {
    if (tagForNotification.text.trim().isNotEmpty) {
      addTagForNotification(tagForNotification.text.trim());
      tagForNotification.clear();
    }
  }
  void removeTaggedUsers(String userId) {
    taggedUsers.remove(userId);
    taggedUserDetails.removeWhere((user) => user['user_id'].toString() == userId);
    notifyListeners();
  }
  void removeTaggedUser(String user) {
    taggedUsers.remove(user);
    notifyListeners();
  }

  // --- Clear Fields ---
  void clearAssignToInputs() {
    assignTo.clear();
    tagForNotification.clear();
    notifyListeners();
  }

  void clearAll() {
    assignToUser = null;
    tagMemberUser = null;
    recurringTaskUser = null;
    selectedPriority = null;
    assignTo.clear();
    tagForNotification.clear();
    duration.clear();
    dateTimeList.clear();
    assignedUsers.clear();
    taggedUsers.clear();
    selectedDateTime = null;
    notifyListeners();
  }




  void setTagMemberUser(String? value) {
    tagMemberUser = value;
    notifyListeners();
  }

  void setRecurringTaskUser(String? value) {
    recurringTaskUser = value;
    notifyListeners();
  }

  // --- Dispose ---
  @override
  void dispose() {
    detailsController.dispose();
    assignTo.dispose();
    tagForNotification.dispose();
    searchController.dispose();
    duration.dispose();
    super.dispose();
  }

  void updateDateTime(int index, TaskDateTimeModel updatedModel) {
    if (index >= 0 && index < dateTimeList.length) {
      dateTimeList[index] = updatedModel;
      notifyListeners();
    }
  }

  Future<TaskDetailsModel?> getTaskById(String token, int taskId) async {
    try {
      final response = await ApiService.get(
        '${ApiConstants.getTaskList}/$taskId/',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response is Map<String, dynamic>) {
        return TaskDetailsModel.fromJson(response);
      } else {
        debugPrint('Unexpected response format: $response');
      }
    } catch (e) {
      debugPrint('❌ Error fetching task by ID: $e');
    }
    return null;
  }

  Future<void> fetchTaskDetails(String taskId, String? token) async {
    try{
      _isLoading = true;
      notifyListeners();

      final response = await ApiService.get(
        '${ApiConstants.getTaskList}$taskId/',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response != null) {
        final taskDetails = TaskDetailsModel.fromJson(response);
        _updateControllersFromTaskDetails(taskDetails);
      }
    }catch(e){
      debugPrint('Error fetching task details: $e');
      rethrow;
    }finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  void _updateControllersFromTaskDetails(TaskDetailsModel taskDetails) {
    detailsController.text = taskDetails.taskDetail ?? '';
    Map<String, dynamic>? selectedPriority;

    selectedAssignToUser = taskDetails.createdBy;
    isFavourite = taskDetails.favoriteFlag == 'Y';
    if (taskDetails.priorityLookupdet != null) {
      final priorityId = taskDetails.priorityLookupdet.toString();
      final matchedPriority = priorityList.firstWhere(
            (element) => element['id'].toString() == priorityId,
        orElse: () => {},
      );
      if (matchedPriority.isNotEmpty) {
        selectedPriority = matchedPriority;
        debugPrint('Initialized priority from task: ${selectedPriority?['name']}');
      }

      //selectedPriority = matchedPriority.isNotEmpty ? matchedPriority : null;
    } else {
      selectedPriority = null;
    }
    if (taskDetails.createdDate != null) {
      try {
        final date = DateTime.parse(taskDetails.createdDate!);
        dateTimeList = [
          TaskDateTimeModel(
            date: date,
            time: TimeOfDay.fromDateTime(date),
          )
        ];
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }

    notifyListeners();

  }

  Future<List<Map<String, dynamic>>> fetchProjectList() async {
    try {
      final response = await ApiService.get(
        ApiConstants.ProjectList,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response != null && response['lookup'] != null) {
        final lookupDetails = response['lookup']['lookup_det_id'] as List;
        return lookupDetails
            .where((item) => item['status'] == 'Active' || item['status'] == 'active')
            .map<Map<String, dynamic>>((item) => {
          'id': item['lookup_det_id'].toString(),
          'name': item['lookup_det_desc_en'],
        })
            .toList();
        // final activeProjects = lookupDetails
        //     .where((item) =>
        // item['status'] == 'Active' || item['status'] == 'active')
        //     .map<String>((item) => item['lookup_det_desc_en'] as String)
        //     .toList();
        final activeProjects = lookupDetails
            .where((item) =>
        item['status'] == 'Active' || item['status'] == 'active')
            .map<Map<String, dynamic>>((item) => {
          "id": item['lookup_det_id'],
          "name": item['lookup_det_desc_en'],
        })
            .toList();
        debugPrint('✅ Project List---->>: $activeProjects');
        return activeProjects;
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching project list: $e');
      rethrow;
    }
  }


  Future<List<Map<String, dynamic>>> fetchUserList() async {
    try {
      final response = await ApiService.get(
        ApiConstants.user_list,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response != null && response['user_list'] != null) {
        final userList = (response['user_list'] as List)
            .cast<Map<String, dynamic>>();
        debugPrint('✅ User List--->: $userList');
        return userList;
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching user list: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> priority() async {
   // final Uri url = Uri.parse('http://210.89.42.219:8083/api/lookup-det/by-code/SEV/');
    final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.Priority}');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('🌐 Request URL----: $url');
      debugPrint('📥 Status Code: ${response.statusCode}');
      debugPrint('📥 Raw Response: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded['lookup'] != null && decoded['lookup']['lookup_det_id'] != null) {
          final List<dynamic> lookupDetails = decoded['lookup']['lookup_det_id'];

          final priorityList = lookupDetails
              .where((item) => item['status']?.toString().toLowerCase() == 'active')
              .map<Map<String, dynamic>>((item) => {
            'id': item['lookup_det_id'].toString(),
            'value': item['lookup_det_value'],
            'name': item['lookup_det_desc_en'],
            'isSelected': false, // Add selection state
          })
              .toList();

          debugPrint('✅ Parsed Priority List:');
          for (var p in priorityList) {
            debugPrint(
                '➡ ID: ${p['id']}, Name: ${p['name']}, Value: ${p['value']}, Status: Active');
          }
          return priorityList;
        } else {
          debugPrint('⚠️ Missing "lookup" or "lookup_det_id" in response');
        }
      } else {
        debugPrint('❌ HTTP Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Exception occurred: $e');
    }

    return [];
  }
  void selectPriority(Map<String, dynamic> priority) {
    // First reset all priorities to not selected
    for (var p in priorityList) {
      p['isSelected'] = false;
    }

    // Then set the selected priority
    final selectedIndex = priorityList.indexWhere((p) => p['id'] == priority['id']);
    if (selectedIndex != -1) {
      priorityList[selectedIndex]['isSelected'] = true;
      selectedPriority = priority;
      debugPrint('🔥 Selected Priority: ${priority['name']} (ID: ${priority['id']})');
    }

    notifyListeners();
  }
  Future<void> updateTaskDetails(String taskId, String token) async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await ApiService.get(
        '${ApiConstants.addTask}/$taskId',
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );
      if (response != null) {
        taskData = response;

        // Initialize form fields with API data
        detailsController.text = response['task_detail'] ?? '';

        // Set priority if available
        if (response['priority_lookupdet'] != null) {
          selectedPriority = {
            'id': response['priority_lookupdet'],
            'name': response['priority_lookupdet_desc'],
          };
        }

        // Set date/time if available
        if (response['assign_date'] != null) {
          final assignDate = DateTime.parse(response['assign_date']);
          TimeOfDay? assignTime;

          if (response['assign_time'] != null) {
            final timeParts = response['assign_time'].split(':');
            assignTime = TimeOfDay(
              hour: int.parse(timeParts[0]),
              minute: int.parse(timeParts[1]),
            );
          }

          dateTimeList = [
            TaskDateTimeModel(
              date: assignDate,
              time: assignTime,
            ),
          ];
        }

        // Set assigned users if available
        if (response['assigned_to'] != null) {
          selectedAssignToUserId = response['assigned_to']['id'].toString();
          selectedAssignToUserName = response['assigned_to']['name'];
        }

        // Set tagged users if available
        if (response['tagged_users'] != null && response['tagged_users'] is List) {
          taggedUsers = (response['tagged_users'] as List)
              .map((user) => user['id'].toString())
              .toList();
          taggedUserDetails = (response['tagged_users'] as List)
              .map((user) => {
            'user_id': user['id'],
            'user_name': user['name'],
          })
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch task details: $e');
      throw Exception('Failed to load task details');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatesTaskDetails(String taskId, String? token) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await ApiService.get(
        '${ApiConstants.addTask}/$taskId/',
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response != null) {
        taskData = response;
        debugPrint('✅ Task details fetched: ${jsonEncode(response)}');

        // Update all relevant fields from API response
        _updateFieldsFromResponse(response);
      }
    } catch (e) {
      debugPrint('❌ Error fetching task details: $e');
      throw Exception('Failed to load task details');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  void _updateFieldsFromResponse(Map<String, dynamic> response) {
    // Update basic fields
    detailsController.text = response['task_detail'] ?? '';

    // Update priority
    if (response['priority_lookupdet'] != null) {
      selectedPriority = {
        'id': response['priority_lookupdet'].toString(),
        'name': response['priority_lookupdet_desc'] ?? 'Unknown',
      };
    }

    // Update project
    if (response['project_name'] != null) {
      selectedProjectId = response['project_name'].toString();
      selectedProjectName = response['project_name_desc'] ?? 'Unknown';
    }

    // Update assigned user
    if (response['assigned_to'] != null) {
      selectedAssignToUserId = response['assigned_to'].toString();
      selectedAssignToUserName = response['assigned_to_name'] ?? 'Unknown';
    }

    // Update tagged users
    if (response['tagged_users'] != null && response['tagged_users'] is List) {
      taggedUsers = (response['tagged_users'] as List)
          .map((user) => user['id'].toString())
          .toList();
      taggedUserDetails = (response['tagged_users'] as List)
          .map((user) => {
        'user_id': user['id'],
        'user_name': user['name'] ?? 'Unknown',
      })
          .toList();
    }

    // Update dates
    if (response['assign_date'] != null) {
      try {
        final date = DateTime.parse(response['assign_date']);
        TimeOfDay? time;

        if (response['assign_time'] != null) {
          final parts = response['assign_time'].split(':');
          time = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }

        dateTimeList = [
          TaskDateTimeModel(
            date: date,
            time: time,
            repeatText: response['repeat_text'],
            repeatData: response['repeat_data'] is Map
                ? Map<String, dynamic>.from(response['repeat_data'])
                : null,
          )
        ];
      } catch (e) {
        debugPrint('Error parsing date/time: $e');
      }
    }
  }

  Future<void> updateTaskWithFile({
    required BuildContext context,
    required int taskId,
    required String taskName,
    required String taskDetail,
    required String? selectedProjectId,
    required String? selectedPriorityId,
    required bool isFavourite,
    required String? assignTo,
    required List<int> notifyUserIds,
    required File? uploadedFile,
    required DateTime assignDate,
    required TimeOfDay assignTime,
    required String estimatedHours,
    required DateTime? estStartDate,
    required DateTime? estEndDate,
  }) async {
    final uri = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.addTask}");
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(SharedPrefConstant().kUserData);

    String? userId;
    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      userId = userData['id']?.toString();
      print('✅ userId----===: $userId');
    } else {
      CustomSnackBar.errorSnackBar(context, "❌ User not logged in");
      return;
    }

    final userData = jsonDecode(userDataString);


    final Map<String, dynamic> body = {
      'task_id': taskId,
      'task_name': taskName,
      'task_detail': taskDetail,
      'favorite_flag': isFavourite ? "Y" : "N",
      'project_name': selectedProjectId,
      'priority_lookupdet': selectedPriorityId,
      'status': "1",
      'assign_to': assignTo,
      'assign_date': DateFormat('yyyy-MM-dd').format(assignDate),
      'assign_time':
      '${assignTime.hour.toString().padLeft(2, '0')}:${assignTime.minute.toString().padLeft(2, '0')}',
      'created_by': int.parse(userId!),
      'est_hrs': estimatedHours,
      'task_docs': "",
    };

    if (estStartDate != null) {
      body['est_start_date'] = DateFormat('yyyy-MM-dd').format(estStartDate);
    }

    if (estEndDate != null) {
      body['est_end_date'] = DateFormat('yyyy-MM-dd').format(estEndDate);
    }

    if (notifyUserIds.isNotEmpty) {
      body['notification_detail'] = notifyUserIds;
    }

    if (uploadedFile != null) {
      try {
        final fileBytes = await uploadedFile.readAsBytes();
        final base64File = base64Encode(fileBytes);
        final mimeType = lookupMimeType(uploadedFile.path) ?? 'application/octet-stream';

        body['task_docs'] = base64File;
        debugPrint("📁 File attached as base64 ($mimeType)");
      } catch (e) {
        debugPrint("❌ Error processing file: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$e")),
        );
        return;
      }
    }

    try {
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final decoded = jsonDecode(response.body);
      final status = decoded['status'];
      final message = decoded['message'];

      print("📤 Request Body -->: $body");
      print("🔁 Response Code -->: ${response.statusCode}");
      print("📥 Response Body -->: ${response.body}");

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(
            content: Text("$message"),
          backgroundColor:Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("❌ Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar( backgroundColor:Colors.red,
            content: Text("❌ Error: ${e.toString()}")),
      );
    }
  }


  // In TaskDetailController
  void clearAllData() {
    detailsController.clear();
    detailsController.clear();
    selectedPriority = null;
    selectedProjectId = null;
    selectedProjectName = null;
    selectedAssignToUserId = null;
    selectedAssignToUserName = null;
    selectedAssignToUser = null;
    taggedUsers.clear();
    taggedUserDetails.clear();
    assignedUsers.clear();
    dateTimeList.clear();

   // notifyListeners();
  }

  // In TaskDetailController
  void resetForm() {
    dateTimeList.clear();
    taggedUsers.clear();
    taggedUserDetails.clear();
    selectedAssignToUserId = null;
    notifyListeners();
  }
}
