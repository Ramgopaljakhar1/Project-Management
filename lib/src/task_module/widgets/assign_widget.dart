import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/colors.dart';
import '../../utils/img.dart';
import '../../utils/shared_pref_constants.dart';
import '../../utils/shared_preference.dart';
import '../../utils/string.dart';
import '../controller/task_detail_controller.dart';

Widget assignToUser(BuildContext context, {
  required TaskDetailController taskDetail,
  required VoidCallback onAssignToTap,
  required VoidCallback onTagUserUpdated,
  bool showCollapseIcon = true,
  bool showAssignToSection = true,
  bool showTagSection = true,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      /// Assign To Section
      if (showAssignToSection)
        ...[ GestureDetector(
        onTap: onAssignToTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11,),
          child: Row(
            children: [
             SvgPicture.asset(AppImages.assignToSvg,width: 22,height:22,color:AppColors.black,),
              SizedBox(width: 12),
              Text(
                AppStrings.assignTo,
                style: GoogleFonts.lato(
                  color: AppColors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 17),
              if (showCollapseIcon)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0298D7)),
                  ),
                  child: Icon(
                    taskDetail.isAssignToExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.blue,
                  ),
                ),
            ],
          ),
        ),
      ),

      // Show selected assign to users
      if (taskDetail.selectedAssignToUser != null && taskDetail.selectedAssignToUser!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text(
                    taskDetail.selectedAssignToUserId == 'self' ||
                        taskDetail.selectedAssignToUserId == taskDetail.currentUserId
                        ? 'Assign To Self'
                        : taskDetail.selectedAssignToUser! ?? ""),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  taskDetail.setAssignToUser(null);
                  onTagUserUpdated();
                },
              ),
            ],
          ),
        ),
          // const SizedBox(height: 17),

        ],
      const SizedBox(height: 7),
      /// Tag For Notification Section
      if (showTagSection &&
        taskDetail.selectedAssignToUser != null &&
          taskDetail.selectedAssignToUser!.isNotEmpty)...[
      GestureDetector(
        onTap: onAssignToTap, // Same bottom sheet for both
        child: Row(
          children: [
            SvgPicture.asset(AppImages.tagUserSvg,width:28,height:28,color:AppColors.black,),
            const SizedBox(width: 17),
            Text(
              AppStrings.tagForNotification,
              style: GoogleFonts.lato(
                color: AppColors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 17),
            if (showCollapseIcon)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0298D7)),
                ),
                child: Icon(
                  taskDetail.isTagForNotificationExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.blue,
                ),
              ),
          ],
        ),
      ),

      // Show selected tag users
      if (taskDetail.taggedUsers.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 13.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: taskDetail.taggedUserDetails.map((user) {
              return Chip(
                label: Text(user['user_name']),
                deleteIcon: Icon(Icons.close),
                onDeleted: () {
                  taskDetail.removeTaggedUsers(user['user_id'].toString());
                  onTagUserUpdated(); // Optional callback to sync with parent
                },
              );
            }).toList(),



          ),
        ),]
    ],
  );
}


