import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskDateTimeModel {
  final DateTime? date;
  final TimeOfDay? time;
  final String? repeatText;
  final Map<String, dynamic>? repeatData;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final String? estimatedHours;

  TaskDateTimeModel({
    this.date,
    this.time,
    this.repeatText,
    this.repeatData,
    this.rangeStart,
    this.rangeEnd,
    this.estimatedHours,
  });

  String formattedDateTime(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = MaterialLocalizations.of(context);

    String dateText = '';
    if (rangeStart != null && rangeEnd != null) {
      dateText = '${dateFormat.format(rangeStart!)} - ${dateFormat.format(rangeEnd!)}';
    } else if (date != null) {
      dateText = dateFormat.format(date!);
    }

    String timeText = time != null ? timeFormat.formatTimeOfDay(time!) : '';

    String hoursText = estimatedHours?.isNotEmpty == true ? '$estimatedHours hrs' : '';

    List<String> parts = [
      if (dateText.isNotEmpty) dateText,
      if (timeText.isNotEmpty) timeText,
      if (hoursText.isNotEmpty) hoursText,
      if (repeatText?.isNotEmpty == true) repeatText!,
    ];

    return parts.join('  |  ');
  }
}