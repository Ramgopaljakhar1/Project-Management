import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_upgrade_version/flutter_upgrade_version.dart';
import 'package:flutter_upgrade_version/models/package_info.dart' as upgradeFlutter;
import 'package:flutter_upgrade_version/models/version_info.dart';
import 'package:project_management/src/utils/img.dart';
import 'package:project_management/src/utils/no_internet_connectivity.dart';
import 'package:project_management/src/utils/screen_size_util.dart';
import 'package:project_management/src/utils/shared_pref_constants.dart';
import 'package:project_management/src/utils/shared_preference.dart';
import 'package:project_management/src/utils/string.dart';
import 'package:project_management/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late upgradeFlutter.PackageInfo _packageInfo;
  final Connectivity _connectivity = Connectivity();
  bool _isNetworkAvailable = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;



  void checkLoginStatus() async {
    SharedPref prefs = SharedPref();
    final token = await prefs.read(SharedPrefConstant().kAuthToken);
    final isLogged = await prefs.read(SharedPrefConstant().login);
    debugPrint('User Token : $token');
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if(token != null && isLogged == true) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void initState() {
    super.initState();

    if (kReleaseMode || Platform.environment.containsKey("FLUTTER_TEST")) {
      debugPrint("Skipping real update check in release/test mode.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.microtask(() async {
          await getPackageData();
          await checkForUpdate();
        });
      });



      /// Instead: proceed to login check directly
      Future.delayed(const Duration(milliseconds: 500), () {
        checkLoginStatus();
      });
    } else {
      /// During development, you can still test login flow
      Future.delayed(const Duration(milliseconds: 500), () {
        checkLoginStatus();
      });
    }
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  // @override
  // void initState() {
  //   super.initState();
  //   if (kReleaseMode || Platform.environment.containsKey("FLUTTER_TEST")) {
  //     debugPrint("Skipping real update check in debug/test mode.");
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       getPackageData();
  //       checkForUpdate();
  //     });
  //   } else {
  //     // Optionally skip to login screen during development
  //     Future.delayed(const Duration(milliseconds: 500), () {
  //       checkLoginStatus();
  //     });
  //   }
  //   // Future.delayed(const Duration(seconds: 3), () {
  //   //   checkLoginStatus();
  //   // //  Navigator.pushReplacementNamed(context, AppRoutes.login);
  //   // });
  // }


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
    return _isNetworkAvailable ? Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: ScreenSizeUtil.screenHeight(context) * 0.27,
              width: ScreenSizeUtil.screenWidth(context) * 0.45,
              child: Image.asset(AppImages.aapPngLogo, fit: BoxFit.contain),
            ),
            const SizedBox(height: 32),
            const Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.appSubTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    )  : InternetIssue(
      onRetryPressed: () async {
        final result = await _connectivity.checkConnectivity();
        _updateConnectionStatus(result);
      },
      showAppBar: false,
    );
  }

  Future<void> checkForUpdate()async {
    try{
      if (Platform.isAndroid) {
        InAppUpdateManager manager = InAppUpdateManager();
        AppUpdateInfo? appUpdateInfo =
        await manager.checkForUpdate();
        if (appUpdateInfo == null) return;
        if (appUpdateInfo.updateAvailability ==
            UpdateAvailability
                .developerTriggeredUpdateInProgress) {
          //If an in-app update is already running, resume the update.
          String? message = await manager.startAnUpdate(
              type: AppUpdateType.immediate);
          debugPrint(message ?? '');
        } else if (appUpdateInfo.updateAvailability ==
            UpdateAvailability.updateAvailable) {
          ///Update available
          if (appUpdateInfo.immediateAllowed) {
            String? message = await manager.startAnUpdate(
                type: AppUpdateType.immediate);
            debugPrint(message ?? '');
          } else if (appUpdateInfo.flexibleAllowed) {
            String? message = await manager.startAnUpdate(
                type: AppUpdateType.flexible);
            debugPrint(message ?? '');
          } else {
            debugPrint(
                'Update available. Immediate & Flexible Update Flow not allow');
          }
        }
      }else if (Platform.isIOS) {
        VersionInfo? _versionInfo =
        await UpgradeVersion.getiOSStoreVersion(
            packageInfo: _packageInfo, regionCode: "US");
        debugPrint(_versionInfo.toJson().toString());
      }
    }catch(e){
    }
  }
  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> getPackageData() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    _packageInfo = await PackageManager.getPackageInfo();
    setState(() {});
  }
}

