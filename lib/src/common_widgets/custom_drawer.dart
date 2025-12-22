import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_management/src/auth_module/login_module/login_screen.dart';
import 'package:project_management/src/auth_module/logout_module/logout_screen.dart';
import 'package:project_management/src/services/api_service.dart';
import 'package:project_management/src/utils/colors.dart';
import 'package:provider/provider.dart';
import '../dashboard_module/controller/dashboard_details_controller.dart';
import '../my_task/contrroller/my_task_controller.dart';
import '../services/constants/api_constants.dart';
import '../utils/img.dart';
import '../utils/shared_pref_constants.dart';
import '../utils/shared_preference.dart';
import 'package:flutter_upgrade_version/models/package_info.dart';


class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String userName = 'User';
  String? token;
  String appVersion = '';
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = user?['id']?.toString();
      if (userId != null) {
        final controller = Provider.of<MyTaskController>(context, listen: false);
        controller.fetchMyTasks(userId: userId);
      }
    });
  }
  Future<void> loadUserData() async {
    SharedPref prefs = SharedPref();

    final tokenVal = await prefs.read(SharedPrefConstant().kAuthToken);
    final userData = await prefs.read(SharedPrefConstant().kUserData);

    setState(() {
      token = tokenVal;
      user = userData;
      userName = userData?['username'] ?? 'User';
    });

    debugPrint("🔑drawer Token: $token");
    debugPrint("drawer 👤 Username: ${user?['username']}");
    final userId = user?['id']?.toString();
    if (userId != null) {
      final controller = Provider.of<MyTaskController>(context, listen: false);
      await controller.fetchMyTasks(userId: userId);
      final dashboardController =
      Provider.of<DashboardDetailsController>(context, listen: false);
      await dashboardController.loadUserDataAndFetchTasks();
    }

    print('userId-- : $userId');
  }

  @override
  Widget build(BuildContext context) {
    final dashboardController = Provider.of<DashboardDetailsController>(context);
    int myTasksCount = dashboardController.myTasksCount;
    return Consumer<MyTaskController>(
        builder: (context, taskController, child) {
          int taskCount = taskController.myTaskListData.length;
        return Drawer(
          width: 280,
          child: Container(
            decoration: const BoxDecoration(color: Color(0xFF5B73E8)),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ClipOval(
                              child: Container(
                                height: 52,width: 52,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12), // jitna corner chahiye
                                    child: Image.asset(
                                      AppImages.appLogo512,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),

                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Drawer Items
                  buildDrawerItem(
                    leadingIcon: Icon(Icons.dashboard,color: AppColors.white,),
                    title: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/dashboardDetails');
                    },
                  ),
                  buildDrawerItem(
                   leadingIcon:SvgPicture.asset(AppImages.myTask,color: AppColors.white),
                    title: 'My Tasks',
                    trailing: taskCount > 0
                        ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        myTasksCount.toString(), // dynamic task count from API
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/myTask');
                    },
                  ),
                  buildDrawerItem(
                     leadingIcon: Icon( Icons.star_border,color: AppColors.white),
                    title: 'Favorites',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/favorites');
                    },
                  ),
                  // inside buildDrawerItem:
                  buildDrawerItem(
                    leadingIcon: Icon( Icons.logout,color: AppColors.white),
                    title: 'Logout',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LogoutScreen()),
                      );
                    },
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'v.1.3',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        );
      }
    );
  }
  Widget buildDrawerItem({
    required Widget leadingIcon,
    required String title,
 Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading:leadingIcon,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: trailing,
      onTap: onTap,
    );
  }


}
