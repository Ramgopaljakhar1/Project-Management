import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/colors.dart';
import '../../utils/img.dart';

Widget tagUser(

    ){
  return  Column(
    children: [
      Row(
        children: [
          SvgPicture.asset(AppImages.tagUserSvg,color:AppColors.gray,),
          SizedBox(width: 14,),
          Text('Tagged for Notification',style:GoogleFonts.lato(fontSize: 14,fontWeight:FontWeight.w600,color:Color(0xFF333333)),),
        ],
      ),

    ],
  );
}