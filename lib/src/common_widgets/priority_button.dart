import 'package:flutter/material.dart';

Widget prioritySelector({
  required String selectedPriority,
  required Function(String) onChanged,
}) {
  final priorities = ['Showstopper', 'Medium', 'Low'];
  final colors = {
    'Showstopper': Colors.red,
    'Medium': Colors.orange,
    'Low': Colors.green,
  };

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: priorities.map((priority) {
      return SizedBox(
        width: 115,
        child: RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity(horizontal: -4.0),
          dense: false,
          title: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: colors[priority],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              priority,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          value: priority,
          groupValue: selectedPriority,
          onChanged: (value) {
            if (value != null) {
              print('Priority selected in UI: $value'); // Debug print
              onChanged(value);
            }
          },
        ),
      );
    }).toList(),
  );
}