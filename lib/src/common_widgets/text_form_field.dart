import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/colors.dart';

Widget textFormField({
  required BuildContext context,
  String? img,
  IconData? suffixImg,
  required String hintText,
  VoidCallback? onSuffixTap,
  double? fontSize,
  bool obscureText = false,
  Color? backgroundColor,
  Color? borderColor,
  Color? prefixIconColor,
  int? maxLines,
  Color? titleColor,
  TextEditingController? controller,
  String? Function(String?)? validator,
  bool readOnly = false,
  VoidCallback? onTap,
  EdgeInsets? prefixIconPadding,
  EdgeInsets? suffixIconPadding,
}) {
  return TextFormField(
    maxLines: maxLines ?? 1,
    controller: controller,
    validator: validator,
    readOnly: readOnly,
    onTap: onTap,
    obscureText: obscureText,
    style: GoogleFonts.lato(
      color: titleColor ?? Colors.white,
      fontSize: fontSize ?? 14,
    ),
    decoration: InputDecoration(
      prefixIcon: img != null
          ? Padding(
        padding: prefixIconPadding ?? const EdgeInsets.only(left: 12, right: 8),
        child: SvgPicture.asset(
          img!,
          width: 18,
          height: 18,
          color: prefixIconColor ?? Colors.white,
        ),
      )
          : null,
      suffixIcon: suffixImg != null
          ? GestureDetector(
        onTap: onSuffixTap,
        child: Padding(
          padding: suffixIconPadding ?? const EdgeInsets.only(right: 12),
          child: Icon(
            suffixImg,
            size: 20,
            color: prefixIconColor ?? Colors.white,
          ),
        ),
      )
          : null,
      hintText: hintText,
      hintStyle: GoogleFonts.lato(
        fontSize: fontSize ?? 14,
        color: (titleColor ?? Colors.white).withOpacity(0.7),
      ),
      filled: true,
      fillColor: backgroundColor ?? AppColors.blue,
      isDense: true, // compact banata hai
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: borderColor ?? Colors.white,
          width: 0.8,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: borderColor ?? Colors.white,
          width: 0.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 0.8,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 0.8,
        ),
      ),
      errorStyle: GoogleFonts.lato(
        fontSize: 12,
        color: Colors.red,
        height: 1.2, // spacing between field & error text
      ),
    ),
  );
}
