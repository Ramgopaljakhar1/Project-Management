import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project_management/src/services/api_service.dart';
import 'package:project_management/src/services/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common_widgets/custom_snackbar.dart';
import '../../../utils/shared_pref_constants.dart';
import '../../../utils/shared_preference.dart';

class LoginController extends ChangeNotifier {
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  bool get isPasswordVisible => _isPasswordVisible;
  bool get isLoading => _isLoading;

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> login(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      CustomSnackBar.errorSnackBar(context, "Please fill all required fields properly");
      return;
    }

    setLoading(true);

    String username = usernameController.text.trim();
    String password = passwordController.text.trim();

    try {
      final response = await ApiService.post(
        ApiConstants.loginApi,
        {
          "username": username,
          "password": password,
        },
      );

      debugPrint('response of user Name: $username');
      debugPrint('response of user Password: $password');
      debugPrint('🔁 Full Login API Response: $response');

      // Check if response is null
      if (response == null) {
        throw Exception("No response from server");
      }

      // Check if login was successful
      if (response['status'] == 'success' && response['token'] != null) {
        String token = response['token'];
        Map<String, dynamic> user = response['user'];

        // Save token and user data
        SharedPref prefs = SharedPref();
        await prefs.save(SharedPrefConstant().kAuthToken, token);
        await prefs.saveUserData(SharedPrefConstant().kUserData, user);
        await prefs.save(SharedPrefConstant().login, true);

        SharedPreferences customPrefs = await SharedPreferences.getInstance();
        await customPrefs.setString('id', user['id'].toString());

        debugPrint('✅ Login Success');
        debugPrint('Token: $token');
        debugPrint('User: $user');

        // Clear text fields after successful login
        usernameController.clear();
        passwordController.clear();

        // Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');

        // Show success message from API or default
        final successMessage = response['message']?.toString() ?? "Login Successful";
        CustomSnackBar.successSnackBar(context, successMessage);
      } else {
        // Show error message from API or default
        final errorMessage = response['message']?.toString() ?? "Login failed";
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ Login API error: ${e.toString()}');
      CustomSnackBar.errorSnackBar(context, e.toString());
    } finally {
      setLoading(false);
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}