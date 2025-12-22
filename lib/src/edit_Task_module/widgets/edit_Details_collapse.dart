import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:project_management/src/common_widgets/priority_button.dart';
import 'package:project_management/src/utils/colors.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart'; // Add this import

import '../../common_widgets/common_text_lable_field.dart';
import '../../common_widgets/custom_dropdown.dart';
import '../../common_widgets/custom_snackbar.dart';
import '../../utils/img.dart';
import '../../utils/string.dart';

Widget EditDetailsCollapse({
  required BuildContext context, // Add context parameter
  required VoidCallback onPress,
  required bool isExpanded,
  required String title,
  String? subtitle,
  required String img,
  required String hintText,
  bool obscureText = false,
  bool showPrioritySection = true,
  bool showSubtitle = true,
  Color? backgroundColor,
  Color? borderColor,
  Color? prefixIconColor,
  Color? images,
  int? maxLines,
  required bool showCollapseIcon,
  String? prefixIconImage,
  Color? titleColor,
  TextEditingController? controller,
  String? Function(String?)? validator,
  bool readOnly = false,
  VoidCallback? onTap,
  required List<String> projectList,
  required String? selectedProject,
  required Function(String?) onChange,
  TextEditingController? projectNameController,
  VoidCallback? onUploadPress,
  File? uploadedFile,
  String? uploadedFileUrl,
  required VoidCallback onDeleteFile,
  required VoidCallback viewFile,
  required String selectedPriority,
  required Function(String) onPriorityChange,
  bool showDropdownForProjectName = true,
  String? apiFileUrl,
}) {
  final priorityMapping = {
    'high': 'Showstopper',
    'medium': 'Critical',
    'low': 'Minor',
  };
  final apiPriority = selectedPriority.toLowerCase();
  final mappedPriority = priorityMapping[apiPriority] ?? selectedPriority;
  final priorities = ['Showstopper', 'Critical', 'Minor'];
  final colors = {
    'Showstopper': Colors.red,
    'Critical': Colors.orange,
    'Minor': Colors.green,
  };

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      /// 🔻 Tappable Header
      GestureDetector(
        onTap: onPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          child: Row(
            children: [
              SvgPicture.asset(
                img,
                color: images ?? Colors.black,
                width: 22,
                height: 22,
              ),
              SizedBox(width: 12),
              RichText(
                text: TextSpan(
                  text: title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: titleColor ?? Colors.black,
                  ),
                ),
              ),

              const SizedBox(width: 18),
              if (showCollapseIcon)
                Container(
                  padding: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0298D7)),
                  ),
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down_outlined,
                    size: 22,
                    color: const Color(0xFF0298D7),
                  ),
                ),
            ],
          ),
        ),
      ),

      /// 🔻 Collapsible Content
      if (isExpanded)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ✅ Add Details Field
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: TextFormField(
                maxLines: maxLines ?? 3,
                validator: validator,
                onTap: onTap,
                readOnly: readOnly,
                obscureText: obscureText,
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(color: AppColors.gray, fontSize: 14),
                  filled: true,
                  fillColor: backgroundColor ?? Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 0.8,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 0.8,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            /// ✅ Project Name Field (Dropdown or Static)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  SvgPicture.asset(
                    AppImages.projectSvg,
                    width: 23,
                    height: 23,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Project Name',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            showDropdownForProjectName
                ? customDropdown(
                  img: AppImages.projectSvg,
                  title: 'Select Project',
                  items: projectList,
                  selectedValue: selectedProject,
                  onChanged: onChange,
                )
                : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: textLabelFormField(
                    readOnly: true,
                    img: AppImages.projectSvg,
                    taskName: 'Project Name',
                    hintText: selectedProject ?? '',
                    onChanged: (_) {},
                    borderColor: borderColor ?? Colors.grey,
                    prefixIconColor: prefixIconColor ?? Colors.black,
                    backgroundColor: backgroundColor ?? Colors.white,
                  ),
                ),

            /// ✅ Upload File Section
            GestureDetector(
              onTap: onUploadPress,
              child: Container(
                margin: const EdgeInsets.only(top: 22),
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 32,
                ),
                decoration: BoxDecoration(
                  border: Border.all(width: 0.5, color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.upload, color: Colors.blue),
                    const SizedBox(height: 8),
                    const Text(
                      'Click to Upload Files',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '(Max. File size: 25 MB)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Text(
                      '(File Format Supports: PDF/JPEG/JPG/PNG/DWG/ZIP)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            /// ✅ Uploaded File View + Delete
            // if (uploadedFile != null || apiFileUrl != null)
            if (uploadedFile != null ||
                (apiFileUrl != null && apiFileUrl!.trim().isNotEmpty))
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    // Display appropriate icon based on file type
                    _buildFileIcon(uploadedFile?.path ?? apiFileUrl),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            uploadedFile != null
                                ? "File"
                                : (apiFileUrl != null ? "File" : ""),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Size: ${uploadedFile != null ? _getFileSize(uploadedFile) : 'Unknown'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                    ),



                    IconButton(
                      onPressed:viewFile,
                      icon: SvgPicture.asset(
                        AppImages.viewSvg,
                        width: 27,
                        height: 27,
                        color: AppColors.blue,
                      ),
                    ),




                    // In EditDetailsCollapse widget
                    IconButton(
                      onPressed:onDeleteFile,
                      icon: SvgPicture.asset(
                        AppImages.DeleteSvg,
                        color: AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),

            /// ✅ Priority Section
            if (showPrioritySection)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 0.0,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        AppStrings.priority,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: titleColor ?? Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children:
                          priorities.map((priority) {
                            final isSelected = selectedPriority == priority;
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Radio<String>(
                                      value: priority,
                                      groupValue: selectedPriority,
                                      onChanged: (value) {
                                        if (value != null)
                                          onPriorityChange(value);
                                      },
                                      activeColor: AppColors.appBar,
                                      fillColor:
                                          MaterialStateProperty.resolveWith<
                                            Color
                                          >((Set<MaterialState> states) {
                                            return isSelected
                                                ? AppColors.appBar
                                                : Colors.grey;
                                          }),
                                    ),
                                    Expanded(
                                      child: Container(
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors[priority],
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0,
                                            ),
                                            child: Text(
                                              priority,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 22),
            if (showSubtitle)
              if (showSubtitle && subtitle != null && subtitle.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Severity',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors[mappedPriority] ?? Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
          ],
        ),
    ],
  );
}

Widget _buildFileIcon(String? filePath) {
  if (filePath == null) return Image.asset(AppImages.pdf, color: Colors.black);

  final extension = filePath.split('.').last.toLowerCase();

  switch (extension) {
    case 'jpg':
    case 'jpeg':
    case 'png':
      return Image.asset(AppImages.pdf, color: Colors.black);
    case 'pdf':
      return Image.asset(AppImages.pdf, color: Colors.black);
    case 'dwg':
      return Image.asset(AppImages.pdf, color: Colors.black);
    case 'zip':
      return Image.asset(AppImages.pdf, color: Colors.black);
    default:
      return Image.asset(AppImages.pdf, color: Colors.black);
  }
}

String _getFileSize(File file) {
  final size = file.lengthSync();
  if (size < 1024) {
    return '$size B';
  } else if (size < 1024 * 1024) {
    return '${(size / 1024).toStringAsFixed(1)} KB';
  } else {
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
