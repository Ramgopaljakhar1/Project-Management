import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project_management/src/utils/colors.dart';
import 'package:project_management/src/utils/img.dart';

class InternetIssue extends StatefulWidget {
  final Function onRetryPressed;
  final bool showAppBar;

  const InternetIssue({super.key, required this.onRetryPressed, required this.showAppBar});

  @override
  State<InternetIssue> createState() => _InternetIssueState();
}

class _InternetIssueState extends State<InternetIssue> {
  bool isButtonLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
        elevation: 0,
        backgroundColor: AppColors.appBar,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      )
          : null,
      body: GestureDetector(
        onTap: () {},
        child: Container(
          height: screenHeight,
          width: screenWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9.0),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 11, left: 8, right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(11.0),
                  child: Image.asset(
                    AppImages.internet,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 33),
                const Center(
                  child: Text(
                    "Oh No !",
                    style: TextStyle(
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w700,
                        fontSize: 24),
                  ),
                ),
                const SizedBox(height: 33),
                const Center(
                  child: Column(
                    children: [
                      Text(
                        "No internet connection found.",
                        style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 16,
                            fontWeight: FontWeight.w400),
                      ),
                      Text(
                        "Check your connection or try again.",
                        style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 16,
                            fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(
                        width: screenWidth / 2.8,
                        height: screenHeight / 20,
                        child: ElevatedButton(
                          onPressed: isButtonLoading
                              ? null
                              : () async {
                            setState(() {
                              isButtonLoading = true;
                            });

                            // Small delay to show spinner
                            await Future.delayed(
                                const Duration(milliseconds: 300));

                            // Check connectivity
                            final connectivityResult =
                            await Connectivity()
                                .checkConnectivity();
                            final isConnected =
                                connectivityResult ==
                                    ConnectivityResult.mobile ||
                                    connectivityResult ==
                                        ConnectivityResult.wifi;

                            if (isConnected) {
                              await widget.onRetryPressed();
                            } else {
                              Get.snackbar(
                                "No Internet",
                                "Still no connection found. Please try again.",
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }

                            setState(() {
                              isButtonLoading = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26.0),
                            ),
                            backgroundColor: AppColors.appBar,
                            foregroundColor: AppColors.primaryDarkColor,
                          ),
                          child: isButtonLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Retry",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                              Icon(Icons.arrow_forward_outlined,
                                  color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20,)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
