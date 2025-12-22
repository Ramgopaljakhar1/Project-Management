import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/img.dart';
import '../utils/string.dart';

Widget searchingField({
  TextEditingController? searchController,
  String? hint,
  String? img,
  Color? fillColor,
  VoidCallback? onTap,
  VoidCallback? onPress,
  ValueChanged<String>? onChanged,
}) {
  return Container(
    alignment:Alignment.center,
    height:50,
    decoration: BoxDecoration(
      color: fillColor ?? AppColors.white,
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 6,
          offset: const Offset(-3, 0),
        ),
      ],
    ),
    child: Center(
      child: TextField(
        controller: searchController,
        onTap: onTap,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintStyle:TextStyle(color:  AppColors.black),
          hintText: hint ?? AppStrings.search,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 5),
           // child: Image.asset(img ?? AppImages.search,color: AppColors.black,),
            child:Icon(Icons.search,color: AppColors.appBar,),
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: onPress,
              icon: Icon(Icons.clear, color: AppColors.black),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent, // important: use transparent here since Container provides color
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    ),
  );
}
