import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/colors.dart';

Widget elevatedButton({
  required VoidCallback onpress,
  required String title,
  TextStyle? textStyle,
  Color iconColor = AppColors.white,
  Color foregroundColor = const Color(0xFF333333),
  Color backgroundColor = Colors.white,
}) {
  return ElevatedButton(
    onPressed: onpress,
    style: ElevatedButton.styleFrom(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      minimumSize: const Size(double.infinity, 50),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: textStyle ?? GoogleFonts.lato(color: Colors.black,),
        ),
        Icon(
          Icons.arrow_forward,
          color: iconColor,
        ),
      ],
    ),
  );
}
