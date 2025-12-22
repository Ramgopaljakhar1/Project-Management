import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../task_module/controller/task_detail_controller.dart';
import '../task_module/models/task_date_time_model.dart';
import '../task_module/widgets/repeats_screen.dart';

class BottomSheetUtils {
  static Future<void> showProjectBottomSheet(BuildContext context) async {
    return showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            DateTime? selectedDate;
            TimeOfDay? selectedTime;
            Map<String, dynamic>? repeatData;
            String? repeatSummary;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 50,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CalendarDatePicker(
                      firstDate: DateTime(2000),
                      initialDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      onDateChanged: (date) {
                        setModalState(() {
                          selectedDate = date;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    /// Time Picker
                    GestureDetector(
                      onTap: () async {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setModalState(() {
                            selectedTime = pickedTime;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.grey),
                            SizedBox(width: 12),
                            Text(
                              selectedTime != null
                                  ? selectedTime!.format(context)
                                  : 'Select Time',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Repeat field
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RepeatsScreen(),
                          ),
                        );
                        if (result != null && result is Map<String, dynamic>) {
                          setModalState(() {
                            repeatData = result['data'];
                            repeatSummary = result['summary'];
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.repeat, color: Colors.grey),
                            SizedBox(width: 12),
                            Text(
                              repeatSummary ?? 'Repeat',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: repeatSummary != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Done & Cancel buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (selectedDate != null && selectedTime != null) {
                                final taskDetail = Provider.of<TaskDetailController>(
                                  context,
                                  listen: false,
                                );
                                final dateTimeModel = TaskDateTimeModel(
                                  date: selectedDate!,
                                  time: selectedTime!,
                                  repeatText: repeatSummary,
                                  repeatData: repeatData,
                                );
                                taskDetail.addDateTime(dateTimeModel);
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Please select date and time'),
                                  ),
                                );
                              }
                            },
                            child: Text('Done'),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}