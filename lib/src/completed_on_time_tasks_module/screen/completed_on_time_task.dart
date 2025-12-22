import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:project_management/src/completed_on_time_tasks_module/screen/task_completed_screen.dart';
import 'package:project_management/src/utils/img.dart';
import 'package:provider/provider.dart';
import 'package:project_management/src/completed_on_time_tasks_module/controller/completed_on_time%20_controller.dart';
import '../../common_widgets/app_state_screen.dart';
import '../../common_widgets/appbar.dart';
import '../../common_widgets/common_shimmer_loader.dart';
import '../../common_widgets/searching_field.dart';
import '../../utils/colors.dart';
import '../../utils/no_internet_connectivity.dart';
import '../../utils/shared_pref_constants.dart';
import '../../utils/shared_preference.dart';
import '../task_model/model.dart';
import '../widgets/completed_on_time_task_card.dart';



//
class CompletedOnTimeTask extends StatefulWidget {
  final bool showAppBar;
  final String? userId;
  final String? assignTo;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? taskId;
  const CompletedOnTimeTask({super.key,this.showAppBar = false, this.userId, this.fromDate, this.toDate, this.taskId, this.assignTo});

  @override
  State<CompletedOnTimeTask> createState() => _CompletedOnTimeTaskState();
}

class _CompletedOnTimeTaskState extends State<CompletedOnTimeTask> {
  TextEditingController searchController = TextEditingController();
  String? token;
  dynamic user;
  String? _userId;
  String searchQuery = '';
  bool isTimedOut = false;
  bool isInitialized = false; // NEW FLAG
  late final CompletedOnTimeTaskModel taskData;

  final Connectivity _connectivity = Connectivity();
  bool _isNetworkAvailable = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    Future.microtask(() async {
      final controller = Provider.of<CompletedOnTimeController>(
        context,
        listen: false,
      );

      await controller.loadUserDataAndFetchTasks(
        taskId: widget.taskId,
        assignedUser: widget.userId,
        fromDate: widget.fromDate?.toIso8601String(),
        toDate: widget.toDate?.toIso8601String(),
      );

      // await controller.fetchCompletedOnTimeTasks(
      //   userId: _userId!,
      //   taskId: widget.taskId,
      //   fromDate: widget.fromDate?.toIso8601String().split('T')[0], // Format date
      //   toDate: widget.toDate?.toIso8601String().split('T')[0],
      // );

      // Mark as initialized after loading starts
      if (mounted) {
        setState(() {
          isInitialized = true;
        });
      }
    });

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && Provider.of<CompletedOnTimeController>(context, listen: false).isLoading) {
        setState(() {
          isTimedOut = true;
        });
      }
    });
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
      final controller = Provider.of<CompletedOnTimeController>(context, listen: false);
      debugPrint("🆔 _userId: $_userId");
      debugPrint("👤 AssignedUserId: ${widget.assignTo}");
      controller.fetchCompletedOnTimeTasks(
        userId: _userId!,
        taskId: widget.taskId,
        assignTo: widget.assignTo,
        fromDate: widget.fromDate?.toIso8601String().split('T')[0], // Format date
        toDate: widget.toDate?.toIso8601String().split('T')[0],
      ); // ✅ Use dynamic userId
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
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completedOnTime = Provider.of<CompletedOnTimeController>(context);
    final filteredTasks = (List.from(completedOnTime.completedTasks)
      ..sort((a, b) {
        final idA = int.tryParse(a.id?.toString() ?? '0') ?? 0;
        final idB = int.tryParse(b.id?.toString() ?? '0') ?? 0;
        return idB.compareTo(idA); // Descending order by id
      }))
        .where((task) {
      final name = task.taskName.toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();



    return _isNetworkAvailable ? Scaffold(
      backgroundColor: AppColors.white,
      appBar: widget.showAppBar
          ? customAppBar(
        context,
        title: 'Completed On Time Task Screen',
        showBack: true,showLogo: false
        // filter: () {
        //
        // },
      )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: completedOnTime.isLoading
            ? isTimedOut
            ? AppStateScreen(
          showAppBar: false,
          imagePath: AppImages.dataNotFound,
          title: 'Data Not Found !',
          subtitle1: 'We are unable to find the data that',
          subtitle2: 'you are looking for.',
          buttonText: 'Retry',
          onButtonPressed: () {
            setState(() {
              isTimedOut = false;
            });
            _fetchDashboardData();
          },
        )
            : Center(child: buildShimmerLoader())

        // ✅ API se data empty mila
            : completedOnTime.completedTasks.isEmpty
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


            : filteredTasks.isEmpty
            ? AppStateScreen(
          showAppBar: false,
          imagePath: AppImages.dataNotFound,
          title: 'No Match Found !',
          subtitle1: 'No tasks match your search query.',
          subtitle2: 'Try a different keyword.',
          buttonText: 'Clear Search',
          onButtonPressed: () {
            setState(() {
              searchController.clear();
              searchQuery = '';
            });
          },
        )

        // ✅ Normal data + search results
            : Column(
          children: [
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
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return completedOnTimeTaskCard(
                    title: task.taskName,
                    completedOn: task.actualEstEndDate,
                    svgImage: AppImages.addTaskSvg,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskCompletedScreen(
                            taskData: {
                              'id': task.id,
                              'task_name': task.taskName,
                              'description': task.taskDetail,
                              'project_name': task.project,
                              'est_start_date': task.estStartDate,
                              'est_end_date': task.estEndDate,
                              'est_hrs': task.estHrs,
                              'priority_lookupdet_desc': task.priority,
                              'task_docs': task.taskDocs,
                            },
                            previousScreenTitle: 'Completed On Time Tasks',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ) : InternetIssue(
    onRetryPressed: () async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
    },
    showAppBar: false,
    );
  }}