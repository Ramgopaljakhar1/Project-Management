import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../common_widgets/app_state_screen.dart';
import '../../common_widgets/appbar.dart';
import '../../common_widgets/common_shimmer_loader.dart';
import '../../common_widgets/searching_field.dart';
import '../../common_widgets/task_card.dart';
import '../../completed_on_time_tasks_module/screen/task_completed_screen.dart';
import '../../utils/colors.dart';
import '../../utils/img.dart';
import '../../utils/no_internet_connectivity.dart';
import '../../utils/shared_pref_constants.dart';
import '../../utils/shared_preference.dart';
import '../controller/add_task_favourites.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool isLoading = true;
  String? token;
  Map<String, dynamic>? user;
  String? _userId;
  final Connectivity _connectivity = Connectivity();
  bool _isNetworkAvailable = true;
  bool _isRemoving = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    Future.delayed(Duration.zero, () async {
      final controller = Provider.of<AddTaskFavouriteController>(
        context,
        listen: false,
      );
      await controller.fetchFavouriteTasks();
      setState(() {
        isLoading = false;
      });
    });
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );

  }

  Future<void> _loadUserData() async {
    final prefs = SharedPref();
    final tokenVal = await prefs.read(SharedPrefConstant().kAuthToken);
    final userData = await prefs.read(SharedPrefConstant().kUserData);

    if (mounted) {
      setState(() {
        token = tokenVal;
        user = userData;
        _userId = userData?['id']?.toString();
      });

      debugPrint("🔑 Token: $token");
      debugPrint("👤 Username: ${user?['username']}");
      debugPrint("🆔 User ID----: $_userId");
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
    searchController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AddTaskFavouriteController>(context);

    final filteredTasks =
        controller.favouriteTasks.where((task) {
          final taskName = task['task_name']?.toLowerCase() ?? '';
          return taskName.contains(searchQuery.toLowerCase());
        }).toList();

    return _isNetworkAvailable
        ? Scaffold(
          appBar: customAppBar(context, title: 'Favourites', showBack: true,showLogo: false),
          body:
              isLoading
                  ? Center(child: buildShimmerLoader()) // ✅ Show loader
                  : filteredTasks.isEmpty
                  ? AppStateScreen(
                    // ✅ No data found UI
                    showAppBar: false,
                    imagePath: AppImages.dataNotFound,
                    title: 'Data Not Found!',
                    subtitle1: 'We are unable to find the data that',
                    subtitle2: 'you are looking for.',
                    buttonText: 'Retry',
                onButtonPressed: () async {
                  setState(() {
                    isLoading = true;
                  });

                  final connectivityResult = await _connectivity.checkConnectivity();
                 // _updateConnectionStatus([connectivityResult]);

                  if (_isNetworkAvailable) {
                    await controller.fetchFavouriteTasks();
                  }

                  setState(() {
                    isLoading = false;
                  });
                },
                  )
                  : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 18),
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
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredTasks.length,
                            itemBuilder: (context, index) {
                              final task = filteredTasks[index];
                              print("🔍 Favourite Task: ${jsonEncode(task)}");
                              return taskCard(
                                showFavourite: true,
                                taskName: task['task_name'] ?? 'No Task Name',
                                priority:
                                    task['priority_lookupdet_desc'] ,
                                assignedDate:
                                    DateTime.tryParse(
                                      task['assign_date'] ?? '',
                                    ) ??
                                    DateTime.now(),
                                removeFavourite: () async {
                                  if (token != null && _userId != null && !_isRemoving) {
                                    setState(() { _isRemoving = true; });

                                    await controller.toggleFavouriteStatus(
                                      context: context,
                                      task: task,
                                      token: token!,
                                      userId: _userId!,
                                    );
                                    setState(() { _isRemoving = false; });
                                  }
                                },
                                favouriteIcon: Icons.star,
                                favouriteIconColor: AppColors.red,
                                showBell: false,
                                onEyeTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TaskCompletedScreen(
                                        taskData: task,
                                        previousScreenTitle: "Favourite Task Details",
                                      ),
                                    ),
                                  );
                                },
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 8,
                                ),
                                padding: const EdgeInsets.all(10),
                              );
                            },
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
          showAppBar: false,
        );
  }
}
