import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_management/src/utils/colors.dart';
import '../utils/img.dart';

Widget textLabelFormField({
   String? img,
   String? hintText,
  String? taskName,
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
  Function(String)? onChanged, // ✅ Added onChanged callback
}) {
  return Container(
    decoration: BoxDecoration(
      color: backgroundColor ?? AppColors.white,
      border: Border.all(
        width:0.8,
          color: borderColor ?? Colors.grey.shade200),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// ✅ Icon centered with both texts
       // SvgPicture.asset(
       //    img,
       //    width: 25,
       //    height: 25,
       //    color: prefixIconColor ?? Colors.black.withOpacity(0.6),
       //  ),
        const SizedBox(width: 8),

        /// ✅ Label + Input Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Text(
              //   taskName ?? '', // ✅ dynamic label
              //   style: TextStyle(
              //     color: titleColor ?? Colors.grey,
              //     fontSize: 12,
              //     fontWeight: FontWeight.w500,
              //   ),
              // ),
              TextFormField(
                controller: controller,
                maxLines: maxLines ?? 1,
                validator: validator,
                readOnly: readOnly,
                onTap: onTap,
                obscureText: obscureText,
                onChanged: onChanged, // ✅ onChanged used here
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: titleColor ?? Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
