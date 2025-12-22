import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:project_management/src/common_widgets/priority_button.dart';
import 'package:project_management/src/utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../../common_widgets/common_text_lable_field.dart';
import '../../common_widgets/custom_dropdown.dart';
import '../../common_widgets/custom_snackbar.dart';
import '../../utils/img.dart';
import '../../utils/string.dart';

Widget CompletedViewCollapse({
  BuildContext,context,
  required VoidCallback onPress,
  required bool isExpanded,
  required String title,
  String? img,
  required String hintText,
  bool obscureText = false,
  Color? backgroundColor,
  Color? borderColor,
  Color? prefixIconColor,
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
  String? uploadedFileUrl, // Add this parameter for API file URL
  required VoidCallback onDeleteFile,
  required String selectedPriority,
  required Function(String) onPriorityChange,
  bool showDropdownForProjectName = true,
}) {
  final priorities = ['Showstopper', 'Medium', 'Low'];
  final colors = {
    'Showstopper': Colors.red,
    'Minor': Colors.orange,
    'Critical': Colors.green,
  };

  // Function to get file name from URL
  String getFileNameFromUrl(String url) {
    try {
      return Uri.parse(url).pathSegments.last;
    } catch (e) {
      return 'Downloaded File';
    }
  }

  // Function to get file icon based on extension
  Widget getFileIcon(String url) {
    final fileName = url.toLowerCase();
    if (fileName.endsWith('.pdf')) {
      return Image.asset(AppImages.pdf, color: Colors.black, width: 24, height: 24);
    } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png')) {
      return Image.asset(AppImages.pdfSvg, color: Colors.black, width: 24, height: 24);
    } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Image.asset(AppImages.pdfSvg, color: Colors.black, width: 24, height: 24);
    } else {
      return Image.asset(AppImages.pdfSvg, color: Colors.black, width: 24, height: 24);
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      /// 🔻 Tappable Header
      GestureDetector(
        onTap: onPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
          child: Row(
            children: [
              if (img != null) // Only show if img is not null
                SvgPicture.asset(img, color: prefixIconColor ?? Colors.black, width: 22, height: 22),
              const SizedBox(width: 12),
              if (img != null) const SizedBox(width: 12),
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
                  prefixIcon: prefixIconImage != null
                      ? Padding(
                    padding: const EdgeInsets.only(bottom: 47.0),
                    child: SvgPicture.asset(
                      prefixIconImage,
                      width: 28,
                      height: 28,
                      color: prefixIconColor ?? Colors.black,
                    ),
                  )
                      : null,
                  hintText: hintText,
                  filled: true,
                  fillColor: backgroundColor ?? Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(33),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                'Project Name',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:Colors.black,
                ),
              ),
            ),
            /// ✅ Project Name Dropdown or Static Field
            showDropdownForProjectName
                ? customDropdown(
              img: AppImages.projectSvg,
              title: 'Project Name',
              items: projectList,
              selectedValue: selectedProject,
              onChanged: onChange,
            )
                : Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
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

            /// ✅ Task Details.PNG Section (for API file)
            if (uploadedFileUrl != null && uploadedFileUrl.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 13),
                padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Row(
                  children: [
                    Image.asset(AppImages.pdf,width: 22,height: 22,),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'File',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              'Size: 1.5 MB', // You can get actual size if available
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ]),
                    ),

                    IconButton(
                      onPressed: () async {
                        if (uploadedFileUrl != null && uploadedFileUrl!.isNotEmpty) {
                          try {
                            final uri = Uri.parse(uploadedFileUrl!);
                            final response = await http.get(uri);

                            if (response.statusCode == 200) {
                              final tempDir = Directory.systemTemp;
                              final filePath = '${tempDir.path}/${uri.pathSegments.last}';
                              final file = File(filePath);
                              await file.writeAsBytes(response.bodyBytes);

                              await OpenFile.open(file.path);
                            } else {
                              throw Exception("Failed to download file");
                            }
                          } catch (e) {
                            debugPrint('Error opening file: $e');
                            CustomSnackBar.errorSnackBar(context, 'Could not open file');
                          }
                        }
                      },
                      icon: SvgPicture.asset(
                        AppImages.viewSvg,
                        width: 27,
                        height: 27,
                        color: AppColors.blue,
                      ),
                    )
                  ],
                ),

              ),
            SizedBox(height: 11),


            /// ✅ Priority Section

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      AppStrings.priority,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width:16),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: selectedPriority == 'Showstopper'
                            ? Colors.red
                            : selectedPriority == 'Minor'
                            ? Colors.orange  : (selectedPriority == 'Critical') ? Colors.green  : Colors.grey,

                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:  Text(
                        (selectedPriority == null || selectedPriority!.isEmpty)
                            ? 'null'
                            : selectedPriority!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
    ],
  );
}