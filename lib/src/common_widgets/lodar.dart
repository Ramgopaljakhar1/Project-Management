import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget commonLoader({Color color = CupertinoColors.activeBlue, double? size}) {
  return Center(
    child: SizedBox(
      height: size ?? 50, // default size
      width: size ?? 50,
      child: CupertinoActivityIndicator(
        color: color, // iOS-style circular loader with custom color
        radius: (size ?? 40) / 2, // makes it adapt to screen button size
      ),
    ),
  );
}
