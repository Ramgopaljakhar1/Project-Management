import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:project_management/src/utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:project_management/src/common_widgets/task_card.dart';
import 'package:project_management/src/common_widgets/searching_field.dart';
import '../common_widgets/app_state_screen.dart';
import '../common_widgets/appbar.dart';
import '../common_widgets/common_shimmer_loader.dart';
import '../completed_on_time_tasks_module/screen/task_completed_screen.dart';
import '../utils/img.dart';
import '../utils/no_internet_connectivity.dart';
import '../utils/shared_pref_constants.dart';
import '../utils/shared_preference.dart';
import 'controller/widget/controller.dart';

class GetDelayedScreen extends StatefulWidget {
  final bool showAppBar;
  final String? userId;
  final DateTime? fromDate;
  final String? assignTo;
  final DateTime? toDate;
  final String? taskId;
  const GetDelayedScreen({super.key, this.showAppBar = false, this.userId, this.fromDate, this.toDate, this.taskId, this.assignTo});

  @override
  State<GetDelayedScreen> createState() => _GetDelayedScreenState();
}

class _GetDelayedScreenState extends State<GetDelayedScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String? token;
  dynamic user;
  String? _userId;
  bool isTimedOut = false;
  final Connectivity _connectivity = Connectivity();
  bool _isNetworkAvailable = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool isLoading = false;


  @override
  void initState() {
    super.initState();
    _loadUserData().then((_) {
      if (_userId != null) {
        _fetchDataWithTimeout();
      }
    });
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final isConnected = results.any((result) =>
    result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi);

    setState(() {
      _isNetworkAvailable = isConnected;
    });
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
        _fetchDataWithTimeout();
      } else {
        debugPrint("❌ User ID is null!");
      }
    }
  }
  void _fetchDataWithTimeout() {
    if (_userId == null) {
      debugPrint("❌ User ID is null - cannot fetch delayed tasks");
      return;
    }
    final controller = Provider.of<GetDelayedController>(context, listen: false);
    controller.fetchDelayedTasks(
      userId: _userId!.toString(),
      taskId: widget.taskId,
      assignTo:widget.assignTo,
      fromDate: widget.fromDate?.toIso8601String().split('T')[0], // Format date
      toDate: widget.toDate?.toIso8601String().split('T')[0],
    );

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && controller.isLoading) {
        setState(() {
          isTimedOut = true;
        });
      }
    }).then((_) {
      // Sort delayed tasks by ID descending (newest first)
      controller.delayedTasks.sort((a, b) {
        final idA = int.tryParse(a.id?.toString() ?? '0') ?? 0;
        final idB = int.tryParse(b.id?.toString() ?? '0') ?? 0;
        return idB.compareTo(idA);  // Descending order
      });

      if (mounted) setState(() {});  // Refresh UI after sorting
    });
  }

  void _retryFetchingData() {
    setState(() {
      isTimedOut = false;
    });
    _fetchDataWithTimeout();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return _isNetworkAvailable ? Scaffold(
      backgroundColor: AppColors.white,
      appBar: widget.showAppBar
          ? customAppBar(
        context,
        title: 'Delayed Task Screen',
        showBack: true,showLogo: false
      )
          : null,
      body: Consumer<GetDelayedController>(
        builder: (context, controller, child) {
          final filteredTasks = controller.delayedTasks.where((task) {
            final taskName = task.taskName?.toLowerCase() ?? '';
            return taskName.contains(searchQuery.toLowerCase());
          }).toList();

          if (controller.isLoading) {
            return isTimedOut
                ? AppStateScreen(
              showAppBar: false,
              imagePath: AppImages.dataNotFound,
              title: 'Data Not Found!',
              subtitle1: 'We are unable to find the data that',
              subtitle2: 'you are looking for.',
              buttonText: 'Retry',
              onButtonPressed: () {
                _fetchDataWithTimeout();  // ✅ Re-fetch data
              },
            )
                :  Center(child: buildShimmerLoader());
          }

          if (filteredTasks.isEmpty) {
            return AppStateScreen(
              showAppBar: false,
              imagePath: AppImages.dataNotFound,
              title: 'No Tasks Found',
              subtitle1: 'Try adjusting your search term',
              subtitle2: 'or check back later.',
              buttonText: 'Retry',
              onButtonPressed: () {
                _fetchDataWithTimeout();
                setState(() {
                  searchController.clear();
                  searchQuery = '';
                });
              },
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: searchingField(
                    onPress: () {
                      setState(() {
                        searchController.clear();
                        searchQuery = '';
                      });
                    },
                    fillColor: Colors.white,
                    searchController: searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.trim();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return taskCard(
                        taskName: task.taskName ?? 'No Title',
                        priority: task.priority ?? 'N/A',
                        assignedDate:
                        DateTime.tryParse(task.assignDate ?? '') ??
                            DateTime.now(),
                        showBell: false,
                        showFavourite: false,
                        onEyeTap:() {
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

                                    // Add other fields you need
                                  }, previousScreenTitle:"Delayed Task Details Screen",
                                ),
                              )
                          );
                          print('click view...');
                        },

                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    )  : InternetIssue(
      onRetryPressed: () async {
        final result = await _connectivity.checkConnectivity();
        _updateConnectionStatus(result);
      },
      showAppBar: false,
    );
  }
}

