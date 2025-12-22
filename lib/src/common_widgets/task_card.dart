import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../utils/animated_bell_icon.dart';
import '../utils/img.dart';

Widget taskCard({
  String? priority,
  String? taskName,
  String? title,
  bool showAssignedTo = false,
  String? subTitle,
  DateTime? assignedDate,
  DateTime? completedDate,
  String? taskStatus,
  String? taskStatusType, // e.g. "completed", "overdue", "delayed"
  bool showTaskStatus = true, // NEW parameter
  VoidCallback? onBellTap,
  VoidCallback? removeFavourite,
  VoidCallback? onEyeTap,
  bool showBell = true,
  bool showFavourite = true,
  EdgeInsetsGeometry? margin,
  EdgeInsetsGeometry? padding,
  Color? favouriteIconColor,   // icon ka color
  Color? favouriteBgColor,
  IconData? favouriteIcon,

}) {
  return Container(
    margin: margin ?? const EdgeInsets.all(8),
    padding: padding ?? const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color:Colors.black.withOpacity(0.2),
          blurRadius: 6,
          offset: const Offset(0, -4), // top shadow
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius:6,
          offset: const Offset(0, 4), // bottom shadow
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (priority != null)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    priority,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(AppImages.addTaskSvg,
                      width: 18, height: 18, color: Colors.black87),
                  const SizedBox(width: 8,),
                  const Text(
                    'Task Name : ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      taskName ?? 'No Task',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              if (assignedDate != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      AppImages.calendarSvg,
                      width: 18,
                      height: 18,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Assigned Date : ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Expanded(   // 👈 This will prevent overflow
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(assignedDate),
                        style: const TextStyle(color: Colors.black87),
                        overflow: TextOverflow.ellipsis, // 👈 optional, trims long text with ...
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 11),
              if (completedDate != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(AppImages.calendarSvg,
                        width: 18, height: 18, color: Colors.black54),
                    const SizedBox(width: 8),
                    const Text(
                      'Completed On : ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(completedDate),
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              if (showAssignedTo && subTitle != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(AppImages.calendarSvg,
                        width: 18, height: 18, color: Colors.black87),
                    const SizedBox(width: 8),
                    const Text(
                      'Assigned To : ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        subTitle,overflow: TextOverflow.ellipsis,maxLines: 1,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Right section
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Task Status Badge (controlled by showTaskStatus)
            if (showTaskStatus && taskStatus != null && taskStatusType != null) ...[
              if (_taskStatusWidget(taskStatus, taskStatusType) != null)
                _taskStatusWidget(taskStatus, taskStatusType)!,
            ],

            const SizedBox(height: 6),
            if (showBell)
            //  _circleImageButton(Icons.notifications_active, onBellTap),
            AnimatedBellIcon(onBellTap: onBellTap),
            const SizedBox(height: 6),
            if (showFavourite)
              _circleImageButton(favouriteIcon ?? Icons.star_border, removeFavourite,
                  backgroundColor: favouriteBgColor ?? Color(0xFFFFFFFF),
                iconColor: favouriteIconColor ?? Colors.black87),

            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomCenter,
              child: _circleImageButton(Icons.remove_red_eye, onEyeTap),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget? _taskStatusWidget(String status, String statusType) {
  String? iconPath;
  Color? color;

  switch (statusType.toLowerCase()) {
    case 'completed':
      iconPath = AppImages.completedSvg;
      color = Colors.green;
      break;

    case 'overdue':
      iconPath = AppImages.overdue;
      color = Colors.red;
      break;

    case 'delayed':
      iconPath = AppImages.delayedSvg;
      color = Colors.orange;
      break;

    default:
      return null;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color!, width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          iconPath!,
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          status,
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}


Widget _circleImageButton(IconData iconData, VoidCallback? onPressed,
    {Color? backgroundColor,Color? iconColor,}) {
  return Container(
    decoration: BoxDecoration(
      color: backgroundColor ?? Colors.blue[100],
      shape: BoxShape.circle,
    ),
    padding: const EdgeInsets.all(4),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(100),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(iconData, color:iconColor  ?? Colors.black87, size: 22),
      ),
    ),
  );
}

Color _getPriorityColor(String? priority) {
  if (priority == null) return Colors.grey;
  final value = priority.trim().toLowerCase();

  switch (value) {
    case 'high':
    case 'showstopper':
      return Colors.red;
    case 'medium':
    case 'critical':
      return Colors.orange;
    case 'low':
    case 'minor':
      return Colors.green;
    default:
      return Colors.grey;
  }
}
