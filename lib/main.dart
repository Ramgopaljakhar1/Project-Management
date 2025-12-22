import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:project_management/src/force_update/app_entry_point.dart';
import 'package:project_management/src/assigned_to_team_module/controller/controller.dart';
import 'package:project_management/src/auth_module/login_module/login_controller/login_controller.dart';
import 'package:project_management/src/completed_on_time_tasks_module/controller/completed_on_time%20_controller.dart';
import 'package:project_management/src/completed_on_time_tasks_module/widgets/completed_on_time_task_card.dart';
import 'package:project_management/src/dashboard_module/controller/dashboard_details_controller.dart';
import 'package:project_management/src/deyaled_module/controller/widget/controller.dart';
import 'package:project_management/src/edit_Task_module/controller/controller.dart';
import 'package:project_management/src/favourites/controller/add_task_favourites.dart';
import 'package:project_management/src/my_task/contrroller/my_task_controller.dart';
import 'package:project_management/src/utils/notification_firebase/notification_firebase.dart';
import 'package:project_management/src/notifications/controller/notification_controller.dart';
import 'package:project_management/src/open_tasks/controller/open_task_controller.dart';
import 'package:project_management/src/overdue_module/controller/overdue_controller.dart';
import 'package:project_management/src/task_module/controller/add_task_controller.dart';
import 'package:project_management/src/task_module/controller/task_detail_controller.dart';
import 'package:project_management/src/utils/colors.dart';
import 'package:project_management/src/utils/network_controller.dart';
import 'package:project_management/src/utils/network_status.dart';
import 'package:project_management/src/view_my_task/controller/view_my_task_controller.dart';
import 'package:project_management/src/view_ticket_module/controller/ticket_controller.dart';
import 'package:provider/provider.dart';
import 'package:project_management/routes/app_routes.dart';
import 'package:project_management/src/dashboard_module/controller/controller.dart';
import 'firebase_options.dart';


final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📩 Background message received: ${message.notification?.title}');
}
void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // final fcmToken = await FirebaseMessaging.instance.getToken();
  // debugPrint('FCM Token-----: $fcmToken');
  NotificationFirebaseService().setNavigatorKey(navigatorKey);
  await NotificationFirebaseService().initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.appBar,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  Get.put(NetworkController());
  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => MultiProvider(
        providers: [
          Provider<NetworkStatusService>(
            create: (context) => NetworkStatusService(),
          ),
          ChangeNotifierProvider(create: (_) => DashboardController()),
          ChangeNotifierProvider(create: (_) => AddTaskController()),
          ChangeNotifierProvider(create: (_) => LoginController()),
          ChangeNotifierProvider(create: (_) => TaskDetailController(),),
          ChangeNotifierProvider(create: (_) => DashboardDetailsController(),),
          ChangeNotifierProvider(create: (_) => CompletedOnTimeController(),),
          ChangeNotifierProvider(create: (_) => AddTaskFavouriteController()),
          ChangeNotifierProvider(create: (_) => DashboardDetailsController()),
          ChangeNotifierProvider(create: (_) => AssignedToTeam()),
          ChangeNotifierProvider(create: (_) => MyTaskController()),
          ChangeNotifierProvider(create: (_) => OpenTaskController()),
          ChangeNotifierProvider(create: (_) => ViewMyTaskController()),
          ChangeNotifierProvider(create: (_) => OverDueController()),
          ChangeNotifierProvider(create: (_) => EditTaskController()),
          ChangeNotifierProvider(create: (_) => GetDelayedController()),
          ChangeNotifierProvider(create: (_) => CompletedOnTimeController()),
          ChangeNotifierProvider(create: (_) => NotificationController()),
          ChangeNotifierProvider(create: (_) => TicketController()),
        ],

        //child: const AppEntryPoint(),
        child: MyApp(navigatorKey: navigatorKey),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  const MyApp({super.key, required this.navigatorKey});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.appBar,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Container(
        color: AppColors.appBar,
        child: SafeArea(
          top: true,
          bottom: false,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            useInheritedMediaQuery: true,
            locale: DevicePreview.locale(context),
            builder: (context, child) => DevicePreview.appBuilder!(context, child),
            debugShowCheckedModeBanner: false,
            title: 'Project Management',
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,
          ),
        ),
      ),
    );
  }
}

