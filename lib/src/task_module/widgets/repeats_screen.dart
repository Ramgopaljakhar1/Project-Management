import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:time_picker_spinner/time_picker_spinner.dart';
import '../../common_widgets/appbar.dart';
import '../../common_widgets/common_bottom_button.dart';
import '../../utils/colors.dart';

import '../../utils/img.dart';

class RepeatsScreen extends StatefulWidget {
  const RepeatsScreen({Key? key}) : super(key: key);

  @override
  State<RepeatsScreen> createState() => _RepeatsScreenState();
}

class _RepeatsScreenState extends State<RepeatsScreen> {
  String selectedFrequency = 'Day';
  List<String> frequencies = ['Day', 'Week', 'Month'];
  List<bool> selectedDays = List.generate(7, (_) => false);
  final List<String> weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  int? selectedDayIndex;
  DateTime? startsOnDate = DateTime.now();
  DateTime? endsOnDate;
  TextEditingController occurrencesController = TextEditingController();
  TextEditingController numberController = TextEditingController(text:'2');
  final TextEditingController startsOnController = TextEditingController();
  String endsOption = 'Never';
  TimeOfDay? selectedTime;
  DateTime? selectedDate;
  String? repeatText;
  DateTime? fromDate;
  DateTime? toDate;
  DateTime? startDate;
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        startDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, title: 'Repeats', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Every',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 45,
                          //padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextFormField(
                            controller: numberController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 8,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(color: AppColors.gray),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(
                                  color: AppColors.gray,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.gray),
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedFrequency,

                              icon: const Icon(Icons.arrow_drop_down),
                              isExpanded: true,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                              items: frequencies
                                  .map(
                                    (f) => DropdownMenuItem(
                                  value: f,
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        AppImages.calendar,
                                        color: AppColors.gray,
                                      ),
                                      const SizedBox(width: 11),
                                      Text(f),
                                    ],
                                  ),
                                ),
                              )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedFrequency = value!;
                                  debugPrint('Selected Frequency: $selectedFrequency');
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),


                  const SizedBox(height: 20),

                  /// Weekday selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:
                        weekDays
                            .asMap()
                            .entries
                            .map(
                              (entry) => InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedDayIndex = entry.key;
                                    for (
                                      int i = 0;
                                      i < selectedDays.length;
                                      i++
                                    ) {
                                      selectedDays[i] = i == entry.key;
                                    }

                                    // 👇 Print or use the selected day here
                                    debugPrint(
                                      'Selected Day: ${weekDays[selectedDayIndex!]}',
                                    );
                                  });
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient:
                                        selectedDays[entry.key]
                                            ? const LinearGradient(
                                              colors: [
                                                Color(0xFF06B1EF),
                                                Color(0xFFF9AD23),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                            : null,
                                    color:
                                        selectedDays[entry.key]
                                            ? null
                                            : Colors.white,
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      color:
                                          selectedDays[entry.key]
                                              ? Colors.white
                                              : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),

                  const SizedBox(height: 30),

                  /// Set Time field
                  GestureDetector(
                    onTap: () {
                      _showSelectTimeBottomSheet(context);
                    },

                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.gray),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: AppColors.gray),
                          const SizedBox(width: 12),
                          Text(
                            selectedTime != null
                                ? selectedTime!.format(context)
                                : 'Set Time',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Starts field
                  GestureDetector(
                    onTap: () {
                      _pickDate(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.gray),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            AppImages.calendar,
                            color: AppColors.gray,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            startDate != null
                                ? DateFormat('dd MMM yyyy').format(startDate!)
                                : 'Starts',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Ends options
                  const Text(
                    'Ends',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  RadioListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Never'),
                    value: 'Never',
                    groupValue: endsOption,
                    onChanged: (value) {
                      setState(() {
                        endsOption = value.toString();
                      });
                    },
                  ),
                  //ON Radio button
                  Row(
                    children: [
                      Radio<String>(
                        value: 'On',
                        groupValue: endsOption,
                        onChanged: (value) async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: endsOnDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              endsOption = value!;
                              endsOnDate = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'On',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 30),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: endsOnDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                endsOption = 'On';
                                endsOnDate = picked;
                              });
                            }
                          },

                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.gray),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  AppImages.calendar,
                                  color: AppColors.gray,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    endsOnDate != null
                                        ? DateFormat(
                                          'dd MMMM',
                                        ).format(endsOnDate!)
                                        : 'Select Date',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: AppColors.gray,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'After',
                        groupValue: endsOption,
                        onChanged: (value) {
                          setState(() {
                            endsOption = value!;
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'After',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height:48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.gray),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextField(
                            controller: occurrencesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Occurrences',
                            ),
                            onTap: () {
                              setState(() {
                                endsOption = 'After';
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),

                    onPressed: () {
                      // Parse the interval number from the text field
                      int interval = int.tryParse(numberController.text) ?? 1;

                      // Prepare the repeat data map
                      Map<String, dynamic> repeatData = {
                        'frequency': selectedFrequency,
                        'interval': interval,
                        'selectedDays': selectedDays,
                        'time': selectedTime?.format(context),
                        'startsOn': startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : null,
                        'endsOption': endsOption,
                        'endsOnDate': endsOnDate != null ? DateFormat('yyyy-MM-dd').format(endsOnDate!) : null,
                        'occurrences': occurrencesController.text.isNotEmpty ? int.tryParse(occurrencesController.text) : null,
                      };
//
                      // Generate more user-friendly summary text
                      String summary = '';

                      // Handle frequency text
                      if (selectedFrequency == 'Week') {
                        List<String> selectedDayNames = [];
                        for (int i = 0; i < selectedDays.length; i++) {
                          if (selectedDays[i]) {
                            selectedDayNames.add(['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][i]);
                          }
                        }
                        summary = 'Weekly on ${selectedDayNames.join(', ')}';
                      }
                      else if (selectedFrequency == 'Day') {
                        summary = interval == 1 ? 'Daily' : 'Every $interval days';
                      }
                      else if (selectedFrequency == 'Month') {
                        summary = interval == 1 ? 'Monthly' : 'Every $interval months';
                      }

                      // Add time if set
                      if (selectedTime != null) {
                        // Format time in 12-hour format without AM/PM if you prefer
                        final timeFormat = MaterialLocalizations.of(context).formatTimeOfDay(selectedTime!);
                        summary += ', $timeFormat';
                      }

                      // Add ends information if not "Never"
                      if (endsOption == 'On' && endsOnDate != null) {
                        summary += ', until ${DateFormat('MMM d, y').format(endsOnDate!)}';
                      }
                      else if (endsOption == 'After' && occurrencesController.text.isNotEmpty) {
                      //  summary += ', ${occurrencesController.text} times';
                      }

                      // Print all selected data to console
                      debugPrint('========== REPEAT SETTINGS ==========');
                      debugPrint('Frequency: $selectedFrequency');
                      debugPrint('Interval: $interval');

                      if (selectedFrequency == 'Week') {
                        debugPrint('Selected Days:');
                        for (int i = 0; i < selectedDays.length; i++) {
                          if (selectedDays[i]) {
                            debugPrint('- ${['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][i]}');
                          }
                        }
                      }

                      debugPrint('Time: ${selectedTime?.format(context) ?? 'Not set'}');
                      debugPrint('Starts On: ${startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : 'Not set'}');
                      debugPrint('Ends Option: $endsOption');

                      if (endsOption == 'On') {
                        debugPrint('Ends On Date: ${endsOnDate != null ? DateFormat('yyyy-MM-dd').format(endsOnDate!) : 'Not set'}');
                      } else if (endsOption == 'After') {
                        debugPrint('Occurrences: ${occurrencesController.text.isNotEmpty ? occurrencesController.text : 'Not set'}');
                      }

                      debugPrint('Summary: $summary');
                      debugPrint('=====================================');

                      Navigator.pop(context, {
                        'data': repeatData,
                        'summary': summary.trim(),
                      });
                    },

                    child: const Text(
                      'Done',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSelectTimeBottomSheet(
    BuildContext context, [
    StateSetter? setModalState,
  ]) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: child,
              ),
            ],
          ),
        );
      },
    );

    if (pickedTime != null) {
      if (setModalState != null) {
        setModalState(() {
          selectedTime = pickedTime;
        });
      } else {
        setState(() {
          selectedTime = pickedTime;
        });
      }
    }
  }

  void _showProjectBottomSheet(BuildContext context) {
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Calendar Picker
                    CalendarDatePicker(
                      firstDate: DateTime(2000),

                      initialDate: selectedDate ?? DateTime.now(),
                      lastDate: DateTime(2100),
                      onDateChanged: (date) {
                        setModalState(() {
                          selectedDate = date;
                        });
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 16),

                    /// Set Time field
                    GestureDetector(
                      onTap: () {
                        _showSelectTimeBottomSheet(context, setModalState);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppColors.gray),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              AppImages.clock,
                              width: 20,
                              height: 20,
                              color: AppColors.gray,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Set Time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.gray,
                                    ),
                                  ),
                                  Text(
                                    selectedTime != null
                                        ? DateFormat.jm().format(
                                          DateTime(
                                            0,
                                            0,
                                            0,
                                            selectedTime!.hour,
                                            selectedTime!.minute,
                                          ),
                                        )
                                        : '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// Repeat field
                    // GestureDetector(
                    //   onTap: () async {
                    //     final result = await Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //           builder: (context) => const RepeatsScreen()),
                    //     );
                    //     if (result != null && result is String) {
                    //       setModalState(() {
                    //         repeatText = result;
                    //       });
                    //     }
                    //   },
                    //   child: Container(
                    //     padding: const EdgeInsets.symmetric(
                    //         horizontal: 16, vertical: 14),
                    //     decoration: BoxDecoration(
                    //       borderRadius: BorderRadius.circular(30),
                    //       border: Border.all(color: AppColors.gray),
                    //     ),
                    //     child: Row(
                    //       children: [
                    //         Image.asset(AppImages.recurring,
                    //             width: 20, height: 20, color: AppColors.gray),
                    //         const SizedBox(width: 12),
                    //         Expanded(
                    //           child: Text(
                    //             repeatText ?? 'Repeat',
                    //             style: const TextStyle(
                    //                 fontSize: 14, color: AppColors.black),
                    //           ),
                    //         )
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(height: 24),

                    /// Done & Cancel buttons
                    bottomButton(
                      title: 'Done',
                      subtitle: 'Cancel',
                      icon: Icons.check,
                      icons: Icons.clear,
                      // In the Done button onPressed in RepeatsScreen:
                      onPress: () {
                        String summary = '';
                        String? repeatPattern;

                        if (selectedFrequency == 'Week') {
                          int index = selectedDays.indexWhere((e) => e);
                          String weekDay =
                              [
                                'Sunday',
                                'Monday',
                                'Tuesday',
                                'Wednesday',
                                'Thursday',
                                'Friday',
                                'Saturday',
                              ][index];
                          summary = 'Weekly on $weekDay';
                          repeatPattern = 'Weekly';
                        } else if (selectedFrequency == 'Day') {
                          summary = 'Daily';
                          repeatPattern = 'Daily';
                        } else if (selectedFrequency == 'Month') {
                          summary = 'Monthly';
                          repeatPattern = 'Monthly';
                        }

                        if (selectedTime != null) {
                          summary += ', ${selectedTime!.format(context)}';
                        }
                        //
                        // Return a map with all repeat data
                        Navigator.pop(context, {
                          'summary': summary.trim(),
                          'pattern': repeatPattern,
                          'frequency': selectedFrequency,
                          'selectedDays': selectedDays,
                          'endsOption': endsOption,
                          'endsOnDate': endsOnDate,
                          'occurrences': occurrencesController.text,
                        });
                      },
                      onTap: () {
                        Navigator.pop(context);
                      },
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
