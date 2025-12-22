import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget textButton({
  required VoidCallback onPress,
  required String title,
  Color color = Colors.white,
  TextStyle? textStyle,
}) {
  return TextButton(
    onPressed: onPress,
    child: Text(
      title,
      style: textStyle ??
          GoogleFonts.lato(
            color: color,
          ),
    ),
  );
}
