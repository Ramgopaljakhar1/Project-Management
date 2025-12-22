import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/colors.dart';

class AppStateScreen extends StatelessWidget {
  final bool showAppBar;
  final String imagePath;
  final String title;
  final String subtitle1;
  final bool showBackArrow;
  final String subtitle2;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final double? topSpacing;
  final double? bottomSpacing;

  const AppStateScreen({
    super.key,
    required this.showAppBar,
    required this.imagePath,
    this.showBackArrow = true,
    required this.title,
    required this.subtitle1,
    required this.subtitle2,
    required this.buttonText,
    required this.onButtonPressed,
    this.topSpacing,
    this.bottomSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: showAppBar
          ? AppBar(
        backgroundColor: const Color(0xFF9DB8FF),
        elevation: 0,
        leading: showBackArrow
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        )
            : null,

      )
          : null,
      body: Column(


        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: topSpacing ?? 0),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    //  width: 500,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                 const SizedBox(height: 10),
                  Text(
                    subtitle1,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF666666),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle2,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF666666),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  //const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // Bottom button
          Padding(
            padding: const EdgeInsets.only(
              bottom: 60,
              left: 24,
              right: 24,
            ),
            child: SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9DB8FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buttonText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: bottomSpacing ?? 0),
        ],
      ),
    );
  }
}
