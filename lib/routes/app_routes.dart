// lib/routes/app_routes.dart

import 'package:flutter/material.dart';
import 'package:project_management/src/auth_module/login_module/login_screen.dart';
import 'package:project_management/src/dashboard_module/dashboard_details.dart';
import 'package:project_management/src/dashboard_module/home.dart';
import 'package:project_management/src/favourites/screen/favourites_screen.dart';
import 'package:project_management/src/my_task/screen/my_task_screen.dart';
import 'package:project_management/src/splash_screen.dart';
import 'package:project_management/src/task_module/screens/add_task_screen.dart';
import 'package:project_management/src/task_module/screens/task_details.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String addTask = '/addTask';
  static const String taskDetails = '/taskDetails';
  static const String dashboardDetails = '/dashboardDetails';
  static const String favorites = '/favorites';
  static const String myTask = '/myTask';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) =>  Home());
        case addTask:
        return MaterialPageRoute(builder: (_) =>  AddTaskScreen());
      case dashboardDetails:
        return MaterialPageRoute(builder: (_) => DashboardDetails());
      case myTask:
        return MaterialPageRoute(builder: (_) => MyTaskScreen());
      case favorites:
        return MaterialPageRoute(
          builder: (_) => const FavouritesScreen(), // Pass real map if needed
        );

      case taskDetails:
        return MaterialPageRoute(builder: (_) =>  TaskDetailsScreen(
         taskName: '', taskId: '',

        ));
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}

