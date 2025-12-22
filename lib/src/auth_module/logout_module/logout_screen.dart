import 'dart:async';
import 'dart:math' as CustomSnackBar;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:project_management/src/services/api_service.dart';

import '../../common_widgets/appbar.dart';
import '../../common_widgets/common_bottom_button.dart';
import '../../common_widgets/lodar.dart';
import '../../services/constants/api_constants.dart';
import '../../utils/colors.dart';
import '../../utils/img.dart';
import '../../utils/no_internet_connectivity.dart';
import '../../utils/shared_pref_constants.dart';
import '../../utils/shared_preference.dart';
import '../login_module/login_screen.dart';

class LogoutScreen extends StatefulWidget {
  const LogoutScreen({super.key});

  @override
  State<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen> {
  final Connectivity _connectivity = Connectivity();
  bool _isNetworkAvailable = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool isLoading = false;
  @override
  void initState() {
    super.initState();

    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
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



  Future<void> _onLogoutTap() async {
    setState(() => isLoading = true);
    SharedPref prefs = SharedPref();

    try {
      final token = await prefs.read(SharedPrefConstant().kAuthToken);

      if (token == null) {
        _logoutLocally(message: "Session expired. Please login again.");
        return;
      }

      final response = await ApiService.post(
        ApiConstants.logOut,
        {},
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      final status = response['status'];
      final message = response['message'] ?? 'Logged out';

      if (status == 'success') {

        _logoutLocally(message: message);
      } else {
        // Even if token invalid
        _logoutLocally(message: "Session expired. Please login again.");
      }
    } catch (e) {
      debugPrint("❌ Logout failed: $e");
      _logoutLocally(message: "Session expired. Please login again.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }


// Clear local data and navigate to login
  void _logoutLocally({String? message}) async {
    SharedPref prefs = SharedPref();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );

    if (message != null && message.isNotEmpty) {
      // 👇 Run AFTER navigation completes
      Future.delayed(const Duration(milliseconds: 300), () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor:AppColors.accentColor, content: Text(message)),
          );
        }
      });
    }
  }


  @override
  void dispose() {
    //myTabController.dispose();  // ✅ safely dispose
    _connectivitySubscription?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return _isNetworkAvailable
        ? Scaffold(
      appBar: customAppBar(showLogo: false, context, showBack: true),
      body: Stack( // 👈 Column ko Stack ke andar rakho
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // SVG Image
                Image.asset(AppImages.logout, fit: BoxFit.cover),

                const SizedBox(height: 40),

                // Logout Title
                const Text(
                  'Logout',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 8),

                // Subtext
                const Text(
                  'Are you sure you want to Logout ?',
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),

                // Buttons
                bottomButton(
                  title: 'No',
                  subtitle: 'Yes',
                  leftButtonColor: AppColors.primer,
                  leftTextColor: AppColors.gray,
                  rightTextColor: AppColors.white,
                  rightButtonColor: AppColors.appBar,
                  icon: Icons.arrow_forward,
                  leftIconColor: AppColors.gray,
                  rightIconColor: AppColors.white,
                  icons: Icons.arrow_forward,
                  onPress: () {
                    Navigator.of(context).pop();
                  },
                  onTap: _onLogoutTap
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),

          // 👇 Overlay Loader (always on top)
          if (isLoading)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: commonLoader(
                  color: AppColors.white,
                  size: 50,
                ),
              ),
            ),
        ],
      ),
    )
        : InternetIssue(
      onRetryPressed: () async {
        final result = await _connectivity.checkConnectivity();
        _updateConnectionStatus(result);
      },
      showAppBar: true,
    );
  }





  // Helper method to show success message (you'll need to implement this in LoginScreen)
  void _showLogoutSuccessMessage(String message) {
    // This would need to be implemented in your LoginScreen or using a global approach
  }
}
