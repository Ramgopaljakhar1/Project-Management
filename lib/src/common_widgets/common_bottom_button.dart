import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/colors.dart';

Widget bottomButton({
  required String title,
  required String subtitle,
  required IconData icon,
  required IconData icons,
  required VoidCallback onPress,
  required VoidCallback onTap,
  double? width,
  double? padding,
  Color? leftButtonColor,
  Color? rightButtonColor,
  Color? leftTextColor,
  Color? rightTextColor,
  Color? leftIconColor,
  Color? rightIconColor,
}
    ){
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: padding ?? 6.0),
    child: Row(
      children: [
        Expanded(
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: rightButtonColor ?? Color(0xFFE6EEFB),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: onTap,
              child:Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    subtitle,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: rightTextColor ?? AppColors.gray,
                    ),
                  ),

                  Icon(icons, size: 18,color:rightIconColor ?? AppColors.gray,),

                ],)


          ),
        ),
        SizedBox(width: width ?? 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: leftButtonColor ?? AppColors.appBar,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            onPressed:onPress,
            child:Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,style:GoogleFonts.lato(fontSize:14,fontWeight:FontWeight.w400, color: leftTextColor ?? AppColors.white,),),Icon(icon,size: 18,color:leftIconColor ?? AppColors.white,)
              ],),

          ),
        ),

      ],
    ),
  );
}