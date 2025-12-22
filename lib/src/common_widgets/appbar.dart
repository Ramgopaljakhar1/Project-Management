import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../notifications/controller/notification_controller.dart';
import '../utils/colors.dart';
import '../utils/img.dart';
import 'package:auto_size_text/auto_size_text.dart';

PreferredSizeWidget customAppBar(
    BuildContext context,
    {
      String? title,
  bool showBack = false,
  bool showLogo  = true,
  GlobalKey<ScaffoldState>? scaffoldKey,
  VoidCallback? onAdd,
  VoidCallback? onBell,
  VoidCallback? filter,
  VoidCallback? edit,
    }) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(60),
    child: AppBar(

      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(

          color:AppColors.appBar
          // gradient: LinearGradient(
          //   colors: [Color(0xFF00B4DB), Color(0xFFEDE574)],
          //   begin: Alignment.topLeft,
          //   end: Alignment.bottomRight,
          // ),
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop(); // ✅ use context here
              },
            )

          else if (scaffoldKey != null)
            IconButton(
              icon: Icon(Icons.menu,
                size:28,
                color: Colors.white,
              ),
              onPressed: () {
                scaffoldKey.currentState?.openDrawer();
              },
            ),

          // ✅ Conditionally show logo
          if (showLogo) ...[
            Image.asset(
              AppImages.appLogo512,
              color: AppColors.white,
              width: 30,
              height: 30,
            ),
            const SizedBox(width: 12), // ✅ space ONLY if logo exists
          ],

          // if (showBack || scaffoldKey != null)
          //   const SizedBox(width: 14),

          if (title != null && title.isNotEmpty)
            Expanded(
              child: AutoSizeText(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                minFontSize: 14,
                maxLines: 1,

                //softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),

          const Spacer(),
          if (onAdd != null)
            IconButton(
              icon: SvgPicture.asset(
                AppImages.addIconSvg,
                width: 30,
                height: 30,
                color: Colors.white,
              ),
              onPressed: onAdd,
            ),
          if (edit != null)
            IconButton(
              icon: Image.asset(
                AppImages.edit, // 🖼️ Replace with your actual image path
                width: 24,
                height: 24,
                color: Colors.white, // Optional: tint it white
              ),
              onPressed: edit,
            ),

          if (filter != null)
            IconButton(
              icon: Image.asset(AppImages.filter),
              onPressed: filter,
            ),
          if (onBell != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Consumer<NotificationController>(
                builder: (context, controller, child) {
                  final count = controller.notifications.length; // ✅ sirf list count
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: SvgPicture.asset(
                          AppImages.bellSvg,
                          width: 30,
                          height: 30,
                          color: Colors.white,
                        ),
                        onPressed: onBell,
                      ),
                      if (count > 0)
                        Positioned(
                          right: 3,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 15,
                              minHeight: 15,
                            ),
                            child: Text(
                              '$count', // ✅ only count
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

        ],
      ),

      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
