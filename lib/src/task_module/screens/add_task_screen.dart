import 'package:flutter/material.dart';
import 'package:project_management/src/utils/colors.dart';
import 'package:provider/provider.dart';
import '../../common_widgets/appbar.dart';
import '../../common_widgets/elevated_button.dart';
import '../../common_widgets/text_form_field.dart';
import '../../utils/img.dart';
import '../controller/add_task_controller.dart';

class AddTaskScreen extends StatelessWidget {
  const AddTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AddTaskController>(context);

    return Scaffold(
      appBar: customAppBar(context, title: 'Add Task', showBack: true),
      // body: Column(
      //   children: [
      //     Padding(
      //       padding: const EdgeInsets.symmetric(horizontal: 11.0, vertical: 18),
      //       child: Container(
      //         decoration: BoxDecoration(
      //           borderRadius: BorderRadius.circular(20),
      //           color: AppColors.gray.withOpacity(0.2),
      //         ),
      //         child: Form(
      //           key: controller.formKey,
      //           child: Padding(
      //             padding: const EdgeInsets.symmetric(
      //               horizontal: 8,
      //               vertical: 16,
      //             ),
      //             child: Column(
      //               children: [
      //                 textFormField(
      //                   maxLines: 1,
      //                   titleColor: AppColors.black,
      //                   prefixIconColor: AppColors.gray,
      //                   borderColor: AppColors.gray.withOpacity(0.5),
      //                   backgroundColor: AppColors.white,
      //                   controller: controller.projectNameController,
      //                   hintText: 'Project Name',
      //                   img:
      //                       AppImages
      //                           .project, // ✅ use your user icon or project icon
      //                   validator:
      //                       (value) =>
      //                           value!.isEmpty
      //                               ? 'Please enter project name'
      //                               : null,
      //                 ),
      //                 const SizedBox(height: 22),
      //                 // Description field with maxLines: 3
      //                 TextFormField(
      //                   controller: controller.descriptionController,
      //                   maxLines: 4, // Changed from 3 to 1 for single line
      //                   validator: (value) => value!.isEmpty ? 'Please enter description' : null,
      //                   decoration: InputDecoration(
      //                     hintText: 'Description',
      //                     alignLabelWithHint: true,
      //                     prefixIcon: Padding(
      //                       padding: const EdgeInsets.only(left: 18.0, right: 5.0, bottom:70),
      //                       child: Image.asset(
      //                         AppImages.dashboard,
      //                         width: 24,
      //                         height: 24,
      //                         color: AppColors.gray,
      //                         fit: BoxFit.contain,
      //                       ),
      //                     ),
      //                     filled: true,
      //                     fillColor: Colors.white,
      //                     contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      //                     enabledBorder: OutlineInputBorder(
      //                       borderRadius: BorderRadius.circular(30),
      //                       borderSide: BorderSide(
      //                         color: AppColors.gray.withOpacity(0.5),
      //                       ),
      //                     ),
      //                     focusedBorder: OutlineInputBorder(
      //                       borderRadius: BorderRadius.circular(30),
      //                       borderSide: BorderSide(
      //                         color: AppColors.gray.withOpacity(0.5),
      //                         width: 1.5,
      //                       ),
      //                     ),
      //                   ),
      //                 ),
      //
      //               ],
      //             ),
      //           ),
      //         ),
      //
      //       ),
      //     ),
      //     const Spacer(), // pushes buttons to bottom
      //     Padding(
      //       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30),
      //       child: Row(
      //         children: [
      //           Expanded(
      //             child: elevatedButton(
      //               onpress: () {
      //                 if (controller.formKey.currentState!.validate()) {
      //                   controller.addNewTask(context,token);
      //                   showSuccessDialog(context);
      //                 }
      //               },
      //               title: 'Save',
      //               textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      //               iconColor: Colors.white,
      //               foregroundColor: Colors.white,
      //               backgroundColor: Colors.blue,
      //             ),
      //           ),
      //
      //           const SizedBox(width: 12),
      //           Expanded(
      //             child: elevatedButton(
      //               onpress: () {
      //                 // Cancel logic here
      //               },
      //               title: 'Cancel',
      //               textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      //               iconColor: Colors.white,
      //               foregroundColor: Colors.white,
      //               backgroundColor: Colors.orange,
      //             ),
      //           ),
      //
      //
      //         ],
      //       ),
      //     ),
      //   ],
      // ),
    );
  }
  void showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
               AppImages.taskAddedSuccessfully, // ✅ replace with your success image path
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'Task Added Successfully.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  Navigator.of(context).pop(); // go back to Dashboard
                },
                icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                label: const Text(
                  'Ok',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}
