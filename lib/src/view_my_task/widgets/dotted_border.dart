import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_management/src/utils/img.dart';
import '../../utils/colors.dart';

Widget dottedBorder(
{
  required VoidCallback onPress
}
    ) {
  return DottedBorder(
    borderType: BorderType.RRect,
    radius: const Radius.circular(11),
    dashPattern: [6, 3], // Outer container: dashed border
    color: AppColors.gray,
    strokeWidth: 0.8,
    child: GestureDetector(
      onTap: onPress,
      child: Container(
        height: 150,
        width: double.infinity,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 👇 Inner dashed circle
            DottedBorder(
              borderType: BorderType.Circle,
              color: AppColors.gray,
              dashPattern: [4, 3],
              strokeWidth: 0.8,
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,

                ),
                child:Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(AppImages.upload),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click to Upload Files',
              style: TextStyle(color: AppColors.uploadFile,fontSize: 12,fontWeight:FontWeight.w400),
            ),
            const SizedBox(height: 4),
            Text(
              '(Max. File size: 25 MB)',
              style: TextStyle(color: AppColors.gray,fontSize: 11,fontWeight:FontWeight.w400),
            ),
            const SizedBox(height: 4),
            Text(
              '(File Format Supports: PDF/JPEG/JPG/PNG/ DWG/ZIP)',
              style: TextStyle(color: AppColors.gray,fontSize: 11,fontWeight:FontWeight.w400),
            ),
          ],
        ),
      ),
    ),
  );
}
