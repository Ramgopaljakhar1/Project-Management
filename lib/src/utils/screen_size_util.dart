import 'package:flutter/cupertino.dart';

class ScreenSizeUtil {



  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
}
