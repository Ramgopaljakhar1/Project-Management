import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/colors.dart';

Widget customDropdown({
  required String img,
  required String title,
  required List<String> items,
  required String? selectedValue,
  required Function(String?) onChanged,
}) {
  return DropdownSearch<String>(
    items: (filter, infiniteScrollProps) =>
    items,
    selectedItem: selectedValue,
    onChanged: onChanged,

    popupProps: PopupProps.bottomSheet(

      showSearchBox: true, // ✅ Enable search
     bottomSheetProps:BottomSheetProps(),
      constraints: BoxConstraints(

        maxHeight: MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.height * 0.95,
      ),
      searchFieldProps: TextFieldProps(
        padding: EdgeInsets.symmetric(vertical:30,horizontal:17),
        decoration: InputDecoration(

          hintText: title,hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color:Colors.grey.shade400,
        ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SvgPicture.asset(
              img,
              color: AppColors.gray,
              width: 20,
              height: 20,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color:Colors.grey.shade400, width:0.2), // <-- Thickness here
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color:Colors.grey.shade400, width:0.2), // <-- Thickness here
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color:Colors.grey.shade400, width: 0.2), // <-- Thickness here
          ),
        ),

      ),
    ),
    decoratorProps: DropDownDecoratorProps(
      decoration: InputDecoration(
        hintText: title,
        hintStyle:TextStyle(fontSize: 14, color:AppColors.gray),
        // prefixIcon: Padding(
        //   padding: const EdgeInsets.all(12.0),
        //   child: SvgPicture.asset(
        //     img,
        //     color: AppColors.gray,
        //     width: 20,
        //     height: 20,
        //   ),
        // ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color:Colors.grey.shade400,width:0.1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400,width:0.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color:Colors.grey.shade400,width:0.2),
        ),
      ),
    ),
  );
}
