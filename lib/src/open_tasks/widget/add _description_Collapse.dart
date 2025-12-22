import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:project_management/src/common_widgets/priority_button.dart';
import 'package:project_management/src/utils/colors.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../dashboard_module/controller/controller.dart';
import '../../utils/img.dart';
import '../../utils/string.dart';


Widget addDescriptionCollapse({
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
  required List<Map<String, dynamic>> projectList,
  required String? selectedProject,
  required Function(String?) onChange,
  TextEditingController? projectNameController,
  VoidCallback? onUploadPress,
  File? uploadedFile,
  required VoidCallback onDeleteFile,
  required String selectedPriority,
  required Function(String) onPriorityChange,
  bool showDropdownForProjectName = true,
  required BuildContext context,
}) {
  final dashboardController = Provider.of<DashboardController>(context, listen: false);
  final priorityDisplayMap = {
    'sst': 'Showstopper',
    'crit': 'Critical',
    'min': 'Minor',
    'high': 'Showstopper',
    'medium': 'Critical',
    'low': 'Minor',
  };

  debugPrint('🔘 Current Selected Priority: $selectedPriority');
  // Map the API values to display names
  final currentDisplayName = priorityDisplayMap[selectedPriority?.toLowerCase() ?? ''] ??
      (selectedPriority?.isNotEmpty == true ? selectedPriority : 'Not Set');
  debugPrint('🔄 Mapped Priority: $currentDisplayName');
  debugPrint('📋 Available Priorities from Mapping:');
  final priorities = ['Showstopper', 'Critical', 'Minor'];

  final priorityColors = {
    'SST': Colors.red,
    'CRIT': Colors.orange,
    'MIN': Colors.green,
    // Add fallbacks
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
                  // children: const [
                  //   TextSpan(
                  //     text: ' *',
                  //     style: TextStyle(
                  //       color: Colors.red,
                  //       fontWeight: FontWeight.bold,fontSize: 19
                  //     ),
                  //   ),
                  // ],
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
                  // prefixIcon:
                  //     prefixIconImage != null
                  //         ? Padding(
                  //           padding: const EdgeInsets.only(bottom: 47.0),
                  //           child: SvgPicture.asset(
                  //             prefixIconImage,
                  //             width: 20,
                  //             height: 20,
                  //             color: prefixIconColor ?? Colors.black,
                  //           ),
                  //         )
                  //         : null,
                  hintText: hintText,
                  hintStyle: TextStyle(color: AppColors.gray, fontSize: 14),
                  filled: true,
                  fillColor: backgroundColor ?? Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.shade400, // Adjust shade if needed
                      width: 0.8, // Thin border
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

            /// ✅ Project Name Dropdown
            // customDropdown(
            //   img: AppImages.projectSvg,
            //   title: 'Project Name',
            //   items: projectList,
            //   selectedValue: selectedProject,
            //   onChanged: onChange,
            // ),
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
            DropdownSearch<Map<String, dynamic>>(
              items: (filter, loadProps) => projectList,
              selectedItem: selectedProject != null && selectedProject.isNotEmpty
                  ? projectList.firstWhere(
                    (p) => p['name'] == selectedProject,
                orElse: () => {},
              )
                  : null,
              itemAsString: (item) => item['name'] ?? '',
              compareFn: (item1, item2) => item1['id'] == item2['id'],
              onChanged: (value) {
                if (value != null) {
                  onChange(value['name']);
                }
              },
              popupProps: PopupProps.modalBottomSheet(
                showSearchBox: true,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                modalBottomSheetProps: ModalBottomSheetProps(
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                ),
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: "Search project...",
                    hintStyle: TextStyle(fontSize: 14, color: AppColors.gray),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  hintText: "Select Project",
                  hintStyle:TextStyle(fontSize: 14, color:AppColors.gray),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
            if (uploadedFile != null)
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
                    Image.asset(AppImages.pdf, color: Colors.black),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "File",
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Size: 1.5 MB',
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
                      onPressed: () async {
                        final result = await OpenFile.open(uploadedFile.path);
                        print('Open result: ${result.message}');
                      },
                      icon: SvgPicture.asset(
                        AppImages.viewSvg,
                        width: 27,
                        height: 27,
                        color: AppColors.blue,
                      ),
                    ),
                    IconButton(
                      onPressed: onDeleteFile,
                      icon: SvgPicture.asset(
                        AppImages.DeleteSvg,
                        color: AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),

            /// ✅ Priority Section
            if(showPrioritySection)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 12),
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
                      children: ['Showstopper', 'Critical', 'Minor'].map((priority) {
                        final isSelected = currentDisplayName == priority;
                        debugPrint('🔘 Priority: $priority | Selected: $isSelected');

                        return Expanded(
                          child: GestureDetector(
                              onTap: () {
                                // Find the corresponding API value
                                final apiValue = priorityDisplayMap.entries
                                    .firstWhere(
                                      (entry) => entry.value == priority,
                                  orElse: () => MapEntry('', ''),
                                )
                                    .key;

                                if (apiValue.isNotEmpty) {
                                  onPriorityChange(apiValue);
                                  dashboardController.selectPriority(apiValue);
                                }
                              },
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: priority,
                                    groupValue: currentDisplayName,
                                    onChanged: (value) {
                                      if (value != null) {
                                        final apiValue = priorityDisplayMap.entries
                                            .firstWhere(
                                              (entry) => entry.value == value,
                                          orElse: () => MapEntry('', ''),
                                        )
                                            .key;
                                        if (apiValue.isNotEmpty) {
                                          onPriorityChange(apiValue);
                                          dashboardController.selectPriority(apiValue);
                                        }
                                      }
                                    },
                                    activeColor: AppColors.appBar,
                                  ),
                                  Expanded(
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: priorityColors[priority],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                              )
                          ),
                        );;
                      }).toList(),
                    )
                  ],
                ),
              ),
            const SizedBox(height: 22),
            if(showSubtitle!)
              if (showSubtitle && subtitle != null && subtitle.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Severity', // this will show "Showstopper", "Critical", etc.
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: priorityColors[currentDisplayName] ?? Colors.grey.shade300,
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
