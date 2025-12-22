import 'package:flutter/material.dart';

class RepeatData {
  final String frequency;
  final String day;
  final TimeOfDay? time;
  final DateTime? startDate;

  RepeatData({
    required this.frequency,
    required this.day,
    this.time,
    this.startDate,
  });
}
