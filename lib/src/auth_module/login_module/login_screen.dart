import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../routes/app_routes.dart';
import '../../common_widgets/elevated_button.dart';
import '../../common_widgets/lodar.dart';
import '../../common_widgets/text_button.dart';
import '../../common_widgets/text_form_field.dart';
import '../../utils/no_internet_connectivity.dart';
import '../login_module/login_controller/login_controller.dart';
import '../../utils/colors.dart';
import '../../utils/img.dart';
import '../../utils/screen_size_util.dart';
import '../../utils/string.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Connectivity _connectivity = Connectivity();
  bool _isNetworkAvailable = true;
  bool isLoading = false;
  LoginController? loginController;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  // Update connectivity check method
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
    loginController?.passwordController.clear();
    loginController?.usernameController.clear();
    // myAnimationController.dispose();
    // setState(() {});
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> handleLogin() async {
    setState(() => isLoading = true);

    // Perform your login logic here (API call, validation, etc.)
    await Future.delayed(const Duration(milliseconds: 100)); // simulate login

    setState(() => isLoading = false);

    // On success, navigate
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }
  @override
  Widget build(BuildContext context) {
    final loginController = Provider.of<LoginController>(context);
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child:
          _isNetworkAvailable
              ? GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
                child: Scaffold(
                  resizeToAvoidBottomInset: true,
                  backgroundColor: Colors.white,
                  body: Column(
                    children: [
                      const SizedBox(height: 70),
                      Center(
                        child: Column(
                          children: [
                            SizedBox(
                              height: ScreenSizeUtil.screenHeight(context) * 0.17,
                              width: ScreenSizeUtil.screenWidth(context) * 0.25,
                              child: Image.asset(
                                AppImages.aapPngLogo,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppStrings.appName,
                              style: GoogleFonts.lato(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 35),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.appBar,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    'LOGIN',
                                    style: GoogleFonts.lato(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 52),
                                Form(
                                  key: loginController.formKey,
                                  child: Column(
                                    children: [
                                      textFormField(
                                        context: context,

                                        controller:
                                            loginController.usernameController,
                                        hintText: AppStrings.username,
                                        borderColor: AppColors.white,
                                        backgroundColor: AppColors.appBar,
                                        obscureText: false,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter Username';
                                          }
                                          return null;
                                        },

                                        img: AppImages.usernameSvg,
                                      ),
                                      const SizedBox(height: 32),
                                      textFormField(
                                        context: context,
                                        suffixImg:
                                            loginController.isPasswordVisible
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                        controller:
                                            loginController.passwordController,
                                        hintText: AppStrings.password,
                                        borderColor: Color(0xFFFFFFFF),

                                        backgroundColor: AppColors.appBar,
                                        onSuffixTap: () {
                                          loginController
                                              .togglePasswordVisibility(); // 👈 Call controller method
                                        },
                                        obscureText:
                                            !loginController.isPasswordVisible,
                                        // obscureText: true,
                                        // verticalContentPadding: 6, // reduce height
                                        // verticalIconPadding: 3,
                                        img: AppImages.PasswordSvg,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter Password';
                                          } else if (value.length < 6) {
                                            return 'Password must be at least 6 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 6),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: textButton(
                                          onPress: () => print("Forgot Button?"),
                                          title: "Forgot Password?",
                                          textStyle: GoogleFonts.lato(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 34),
                                      Center(
                                        child:
                                            isLoading
                                                ? commonLoader(
                                                  color: AppColors.white,
                                                  size: 28,
                                                ) // 👈 Using common loader
                                                : elevatedButton(
                                                  onpress: () async {
                                                    if (loginController
                                                        .formKey
                                                        .currentState!
                                                        .validate()) {
                                                      setState(
                                                        () => isLoading = true,
                                                      );
                                                      await loginController.login(
                                                        context,
                                                      );
                                                      setState(
                                                        () => isLoading = false,
                                                      );
                                                    }
                                                    // await loginController.login(context);
                                                  },
                                                  title: "Login",
                                                  textStyle: GoogleFonts.lato(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  iconColor: AppColors.black,
                                                ),
                                      ),


                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )!,
              )
              : InternetIssue(
                onRetryPressed: () async {
                  final result = await _connectivity.checkConnectivity();
                  _updateConnectionStatus(result);
                },
                showAppBar: true,
              ),
    );
  }
}
