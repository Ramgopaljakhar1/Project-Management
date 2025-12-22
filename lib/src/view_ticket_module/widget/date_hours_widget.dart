//
//
//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:project_management/src/utils/colors.dart';
// import 'package:project_management/src/utils/img.dart';
//
// Widget estimatedDate ({
//   String? EstimatedStartDate,
//   String? EstimatedEndDate,
//   String? EstimatedHours,
//   String? taskStatus,
// }){
//   return   Column(
//     children: [
//       Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment:CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Estimated Start Date',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               SizedBox(height:13),
//               Row(
//                 children: [
//                   SvgPicture.asset(AppImages.dateTimeSvg),
//                   SizedBox(width:13),
//                   Padding(
//                     padding: const EdgeInsets.only(right: 32.0),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
//                       decoration: BoxDecoration(
//                         color: AppColors.white,
//                         border: Border.all(color: AppColors.gray.withOpacity(0.7)),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Text(
//                         EstimatedStartDate!,
//                         style: const TextStyle(fontSize: 14),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               //  SvgPicture.asset(AppImages.appLogo512,color: Colors.black,)
//             ],
//           ),
//           //  const SizedBox(width: 16),
//           Column(
//             crossAxisAlignment:CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Estimated End Date',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               SizedBox(height:13),
//               Row(
//                 children: [
//                   SvgPicture.asset(AppImages.dateTimeSvg),
//                   SizedBox(width:13),
//                   Padding(
//                     padding: const EdgeInsets.only(right: 11.0),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
//                       decoration: BoxDecoration(
//                         color: AppColors.white,
//                         border: Border.all(color: AppColors.gray.withOpacity(0.7)),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Text(
//                         EstimatedEndDate!,
//                         style: const TextStyle(fontSize: 14,color:AppColors.darkGray),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               //  SvgPicture.asset(AppImages.appLogo512,color: Colors.black,)
//             ],
//           ),
//         ],
//       ),
//       const SizedBox(height: 11),
//     Divider(),
//       const SizedBox(height: 11),
//       Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment:CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Estimated Hours',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               SizedBox(height:13),
//               Row(
//                 children: [
//                   SvgPicture.asset(AppImages.dateTimeSvg),
//                   SizedBox(width:13),
//                   Padding(
//                     padding: const EdgeInsets.only(right: 32.0),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
//                       decoration: BoxDecoration(
//                         color: AppColors.white,
//                         border: Border.all(color: AppColors.gray.withOpacity(0.7)),
//                         borderRadius: BorderRadius.circular(13),
//                       ),
//                       child: Text(
//                         EstimatedHours!,
//                         // "${task['est_hrs']} Hours",
//                         style: const TextStyle(fontSize: 14),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               //  SvgPicture.asset(AppImages.appLogo512,color: Colors.black,)
//             ],
//           ),
//           //  const SizedBox(width: 16),
//           Column(
//             crossAxisAlignment:CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Task Status',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               SizedBox(height:13),
//               Row(
//                 children: [
//                   SvgPicture.asset(AppImages.ClockSvg,),
//                   SizedBox(width:13),
//                   Padding(
//                     padding: const EdgeInsets.only(right: 11.0),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
//                       decoration: BoxDecoration(
//                         color: AppColors.white,
//                         border: Border.all(color: AppColors.gray.withOpacity(0.7)),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Text(
//                         taskStatus!,
//                         //task['status'],
//                         style: const TextStyle(fontSize: 14,color:AppColors.darkGray),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               //  SvgPicture.asset(AppImages.appLogo512,color: Colors.black,)
//             ],
//           ),
//         ],
//       ),
//     ],
//   );
// }
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_management/src/utils/colors.dart';
import 'package:project_management/src/utils/img.dart';

Widget estimatedDate({
  String? estimatedStartDate,
  String? estimatedEndDate,
  String? estimatedHours,
  String? taskStatus,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 🔹 Estimated Start & End Dates
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoColumn(
            title: 'Estimated Start Date',
            icon: AppImages.dateTimeSvg,
            value: estimatedStartDate ?? 'N/A',
          ),
          SizedBox(width: 8,),
          _buildInfoColumn(
            title: 'Estimated End Date',
            icon: AppImages.dateTimeSvg,
            value: estimatedEndDate ?? 'N/A',
          ),
        ],
      ),

      const SizedBox(height: 16),
      const Divider(),
      const SizedBox(height: 16),

      // 🔹 Estimated Hours & Task Status
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoColumn(
            title: 'Estimated Hours',
            icon: AppImages.dateTimeSvg,
            value: estimatedHours ?? 'N/A',
          ),
          _buildInfoColumn(
            title: 'Task Status',
            icon: AppImages.ClockSvg,
            value: taskStatus ?? 'N/A',
          ),
        ],
      ),
    ],
  );
}

// 📦 Reusable Column widget builder
Widget _buildInfoColumn({
  required String title,
  required String icon,
  required String value,
}) {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            SvgPicture.asset(
              icon,  height: 30, width: 25,),
            const SizedBox(width: 9),
            IntrinsicWidth(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.gray.withOpacity(0.7)),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,fontWeight:FontWeight.w400,
                    color: AppColors.darkGray,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          ],
        ),
      ],
    ),
  );
}
