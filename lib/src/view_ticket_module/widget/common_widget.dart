import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_management/src/utils/colors.dart';
import 'package:project_management/src/utils/img.dart';
import 'package:project_management/src/utils/string.dart';

Widget commonRow({String? img, String? title, Color? color, String? subtitle}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Icon
        Row(
          children: [ if (img != null)
          SvgPicture.asset(img, height: 30, width: 25, color: color),
          if (img != null)
            const SizedBox(width: 8),
          Text(
            title!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.darkGray,
            ),
          ),],),

        // Chip-like subtitle
        Row(
          children: [
          if (subtitle != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.gray.withOpacity(0.7)),
                borderRadius: BorderRadius.circular(16),
              ),
              constraints: const BoxConstraints(maxWidth: 200),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.darkGray,
                  ),
                ),
              ),
            ),
        ],)

      ],
    ),
  );
}
