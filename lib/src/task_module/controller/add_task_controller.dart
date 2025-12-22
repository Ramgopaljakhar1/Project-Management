import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../open_tasks/model/add_task_response_model.dart';
import '../../services/api_service.dart';
import '../../common_widgets/custom_snackbar.dart';
import '../../services/constants/api_constants.dart';
import '../../utils/shared_pref_constants.dart';
import '../../utils/shared_preference.dart';
import '../models/task_model.dart';

class AddTaskController extends ChangeNotifier {
  final taskNameController = TextEditingController();
  final addTaskDetail = TextEditingController();
  String? assignDate;
  String? assignTime;
  final formKey = GlobalKey<FormState>();
  bool _isFavourite = false;
  bool get isFavourite => _isFavourite;
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  set isFavourite(bool value) {
    _isFavourite = value;
    notifyListeners();
  }
  void toggleFavouriteFlag() {
    _isFavourite = !isFavourite;
    notifyListeners(); // if needed
  }

  void resetFavouriteFlag() {
    _isFavourite = false;
  }

  final List<AddTaskModel> _tasks = [];
  bool _isLoading = false;
  BuildContext? _currentContext;

  List<AddTaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  List<AddTaskModel> get favouriteTasks =>
      _tasks.where((task) => task.favoriteFlag == 'N').toList();

  List<AddTaskModel> get sortedTasks =>  List.from(_tasks)
    ..sort((a, b) => (b.createdDate ?? '').compareTo(a.createdDate ?? ''));

  @override
  void dispose() {
    taskNameController.dispose();
    addTaskDetail.dispose();
    super.dispose();
  }

  List<String> get taskNames =>
      _tasks.map((e) => e.taskName).where((name) => name.isNotEmpty).toSet().toList();

  bool isTaskNameExists(String taskName) {
    return _tasks.any((task) => task.taskName.toLowerCase() == taskName.toLowerCase());
  }

  void setContext(BuildContext context) {
    _currentContext = context;
  }
  Future<void> UpdateTask(String? token,) async {}

  Future<bool> addNewTask(
      String? token, {
        required String userId,
        required String description,
        required String? projectId,
        required String? priorityId,
        required String? fileBase64,
        required String? fileName,
        required String? assignToUserId,
        required String? assignDate,
        required String? assignTime,
        required List<String>? notificationUserIds,
        required String? estimatedHours,
        required String? estStartDate,
        required String? estEndDate,
      }) async {
    final prefs = SharedPref();
    final userData = await prefs.read(SharedPrefConstant().kUserData);

    // Validate date range
    if ((estStartDate != null && estStartDate.isNotEmpty) ||
        (estEndDate != null && estEndDate.isNotEmpty)) {
      if (estStartDate == null ||
          estStartDate.isEmpty ||
          estEndDate == null ||
          estEndDate.isEmpty) {
        CustomSnackBar.errorSnackBar(
          _currentContext!,
          "Both Start & End date required if you provide date range",
        );
        return false;
      }
    }

    // Validate file size (max 25MB)
    int _calcBase64SizeBytes(String b64) {
      final s = b64.replaceAll(RegExp(r'\s'), '');
      int padding = 0;
      if (s.endsWith('==')) padding = 2;
      else if (s.endsWith('=')) padding = 1;
      return ((s.length * 3) ~/ 4) - padding;
    }

    if (fileBase64 != null && fileBase64.isNotEmpty) {
      final bytes = _calcBase64SizeBytes(fileBase64);
      final mb = bytes / (1024 * 1024);
      if (mb > 25) {
        CustomSnackBar.errorSnackBar(
          _currentContext!,
          "File size must be ≤ 25 MB",
        );
        return false;
      }
    }

    final formState = formKey.currentState;
    if (formState != null && formState.validate() && _currentContext != null) {
      final taskName = taskNameController.text.trim();

      try {
        _isSaving = true;
        notifyListeners();

        // Create optimistic task with temporary ID
        final optimisticTask = AddTaskModel(
          id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
          taskName: taskName,
          taskDetail: description.isNotEmpty ? description : '',
          projectName: projectId?.isNotEmpty == true ? projectId : null,
          taskDocs: null, // Don't include file in UI initially
          priorityLookupdet: priorityId?.isNotEmpty == true ? priorityId : null,
          favoriteFlag: _isFavourite ? 'Y' : 'N',
          status: '1',
          createdBy: int.tryParse(userId),
          createdDate: DateTime.now().toIso8601String(),
          assignTo: assignToUserId?.isNotEmpty == true
              ? int.tryParse(assignToUserId!)
              : null,
          assignDate: assignDate?.isNotEmpty == true ? assignDate : null,
          assignTime: assignTime?.isNotEmpty == true
              ? assignTime
              : DateFormat("HH:mm:ss").format(DateTime.now()),
          notificationsNotifyTo: notificationUserIds?.isNotEmpty == true
              ? notificationUserIds!.map(int.parse).toList()
              : null,
          estHrs: estimatedHours?.isNotEmpty == true ? estimatedHours : null,
          estStartDate: estStartDate,
          estEndDate: estEndDate,
        );

        // Add to UI immediately
        _tasks.insert(0, optimisticTask);
        notifyListeners();

        // Clear form
        taskNameController.clear();
        resetFavouriteFlag();

        // Process API call in background
        Future(() async {
          try {
            final Map<String, dynamic> taskJson = optimisticTask.toJson();

            // Add file if exists
            if (fileBase64 != null && fileBase64.isNotEmpty) {
              taskJson['task_docs'] = fileBase64;
            } else {
              taskJson.remove('task_docs');
            }

            // Remove temporary ID
            taskJson.remove('id');

            // Log request data
            debugPrint("API REQUEST DATA:");
            taskJson.forEach((key, value) {
              debugPrint("$key : $value");
            });

            // Make API call
            final response = await ApiService.post(
              ApiConstants.addTask,
              taskJson..removeWhere((k, v) => v == null),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            );

            debugPrint('API response: $response');

            final responseData = (response is String) ? jsonDecode(response) : response;
            final responseModel = AddTaskResponseModel.fromJson(responseData);

            if (responseModel.taskId > 0) {
              // Update task with real ID from server
              final idx = _tasks.indexWhere((t) => t.id == optimisticTask.id);
              if (idx != -1) {
                _tasks[idx] = AddTaskModel(
                  id: responseModel.taskId,
                  taskName: responseModel.taskName,
                  taskDetail: optimisticTask.taskDetail,
                  projectName: optimisticTask.projectName,
                  taskDocs: (fileBase64 != null && fileBase64.isNotEmpty)
                      ? fileBase64
                      : optimisticTask.taskDocs,
                  priorityLookupdet: optimisticTask.priorityLookupdet,
                  favoriteFlag: optimisticTask.favoriteFlag,
                  status: optimisticTask.status,
                  createdBy: optimisticTask.createdBy,
                  createdDate: optimisticTask.createdDate,
                  updatedBy: optimisticTask.updatedBy,
                  updatedDate: DateTime.now().toIso8601String(),
                  assignTo: optimisticTask.assignTo,
                  assignDate: optimisticTask.assignDate,
                  assignTime: optimisticTask.assignTime,
                  notificationsNotifyTo: optimisticTask.notificationsNotifyTo,
                  estHrs: optimisticTask.estHrs,
                  estStartDate: optimisticTask.estStartDate,
                  estEndDate: optimisticTask.estEndDate,
                  actualEstHrs: optimisticTask.actualEstHrs,
                  actualEstStartDate: optimisticTask.actualEstStartDate,
                  actualEstEndDate: optimisticTask.actualEstEndDate,
                  assignToRemark: optimisticTask.assignToRemark,
                  priorityLookupdetDesc: optimisticTask.priorityLookupdetDesc,
                  projectLookupdetDesc: optimisticTask.projectLookupdetDesc,
                  ticketMasterLookupdetDesc: optimisticTask.ticketMasterLookupdetDesc,
                  assignToUserName: optimisticTask.assignToUserName,
                  ticketId: optimisticTask.ticketId,
                  ticketMasterStatus: optimisticTask.ticketMasterStatus,
                );
                notifyListeners();
              }

              if (responseModel.message != null) {
                CustomSnackBar.successSnackBar(
                  _currentContext!,
                  responseModel.message,
                );
              }
            } else {
              // Rollback if API call failed
              _tasks.removeWhere((t) => t.id == optimisticTask.id);
              notifyListeners();
              CustomSnackBar.errorSnackBar(
                _currentContext!,
                responseModel.message ?? "Task save failed",
              );
            }
          } catch (e) {
            // Rollback on error
            _tasks.removeWhere((t) => t.id == optimisticTask.id);
            notifyListeners();
            debugPrint("❌ API Error: $e");
            CustomSnackBar.errorSnackBar(
              _currentContext!,
              "Error: ${e.toString()}",
            );
          }
        });

        return true; // UI updates immediately
      } catch (e) {
        debugPrint('❌ Error adding task: $e');
        return false;
      } finally {
        _isSaving = false;
        notifyListeners();
      }
    }
    return false;
  }




  Future<void> getTaskList(String? token) async {
    if (token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('📦 Headers Sent: {Content-Type: application/json, Accept: application/json, Authorization: Bearer $token}');

      final response = await ApiService.get(
        ApiConstants.getTaskList,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Raw Response from getTaskList:');
      debugPrint('🔹 Type: ${response.runtimeType}');
      debugPrint('🔹 Content: ${jsonEncode(response)}');

      if (response is List) {
        _tasks.clear();

        for (var item in response) {
          try {
            debugPrint('🔸 Parsing Task Item: ${jsonEncode(item)}');
            final task = AddTaskModel.fromJson(item);
            _tasks.add(task);
            debugPrint('✅ Added task: ${task.taskName} (ID: ${task.id})');
          } catch (e) {
            debugPrint('❌ Error parsing task item: $e');
            debugPrint('🔸 Problematic item: $item');
          }
        }

        debugPrint('✅ Total Tasks Fetched: ${_tasks.length}');
        if (_tasks.isNotEmpty) {
          debugPrint('🔹 First task: ${_tasks.first.taskName} (ID: ${_tasks.first.id})');
        }

        if (_currentContext != null && _tasks.isNotEmpty) {
          CustomSnackBar.successSnackBar(_currentContext!, 'Loaded ${_tasks.length} tasks');
        }
      } else {
        debugPrint('❌ Unexpected response format: Expected List but got ${response.runtimeType}');
        if (_currentContext != null) {
          CustomSnackBar.errorSnackBar(_currentContext!, 'Unexpected response format');
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching tasks: $e');
      if (_currentContext != null) {
        CustomSnackBar.errorSnackBar(_currentContext!, 'Failed to load tasks: ${e.toString()}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> updateTaskFavoriteFlag({
    required String token,
    required int taskId,
    required String favoriteFlag,
    required String userId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final body = {
        'task_id': taskId,
        'favorite_flag': favoriteFlag,
        'user_id': userId,
      };

      var url = ApiConstants.addTask; // ✅ Ensure this is the correct endpoint

      debugPrint('📤 Sending Favorite Update Data: $body');
      debugPrint('📤 Sending Favorite Update Data URL: $url');

      final response = await ApiService.post(
        url,
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      debugPrint('📤 Sending Favorite Update Data: $body');
      debugPrint('📤 Sending Favorite Update Data URL: $url');

      // Safely extract message from response
      final msg = response?['message']?.toString() ?? "No message returned";

      debugPrint('📥 Response Message: $msg');

      if (msg.toLowerCase().contains('success')) {
        CustomSnackBar.successSnackBar(_currentContext!, msg);
        // await getTaskList(token);
      } else {
        CustomSnackBar.errorSnackBar(_currentContext!, msg);
      }

    } catch (e) {
      debugPrint('❌ Exception occurred: $e');
      if (_currentContext != null) {
        CustomSnackBar.errorSnackBar(_currentContext!, "Error: $e");
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }



  void toggleFavourite(AddTaskModel task) {
    final index = _tasks.indexWhere((t) => t.taskName == task.taskName);
    if (index != -1) {
      _tasks[index] = AddTaskModel(
        taskName: _tasks[index].taskName,
        id: _tasks[index].id,
        taskDetail: _tasks[index].taskDetail,
        projectName: _tasks[index].projectName,
        taskDocs: _tasks[index].taskDocs,
        priorityLookupdet: _tasks[index].priorityLookupdet,
        favoriteFlag: _tasks[index].favoriteFlag == 'Y' ? 'N' : 'Y',
        status: _tasks[index].status,
        createdBy: _tasks[index].createdBy,
        createdDate: _tasks[index].createdDate,
        updatedBy: _tasks[index].updatedBy,
        updatedDate: _tasks[index].updatedDate,
      );
      notifyListeners();
    }
  }

  void addTask(newTask) {}


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
            .cast<Map<String, dynamic>>().where((user) => user['user_name'] != null) // Filter out null names
            .toList();
        debugPrint('✅ User List--->: $userList');
        return userList;
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching user list: $e');
      rethrow;
    }
  }

  void updateTask(updatedTask) {}
  void resetForm() {
    print("🛠️ resetForm() called");
    taskNameController.clear();
    addTaskDetail.clear();
    isFavourite = false;
    formKey.currentState?.reset();
    notifyListeners();
  }
  void clearDateTime() {
    assignDate = null;
    notifyListeners();
  }

}