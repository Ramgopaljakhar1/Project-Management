import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_management/src/utils/colors.dart';

Widget completedOnTimeTaskCard({
  String? title,
  String? completedOn,
  String? svgImage,
  VoidCallback? onTap,
}) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 6,
          offset: const Offset(0, -3),
        ),BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 6,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    margin: const EdgeInsets.symmetric(vertical: 6), // spacing between cards
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(
      children: [
        // 🧾 SVG Icon (only if path is provided)
        if (svgImage != null)
          SvgPicture.asset(
            svgImage,
            height: 24,
            width: 24,
          ),

        if (svgImage != null) const SizedBox(width: 12),

        // 📝 Task Title & Completed Date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title ?? 'No Title',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Completed On: ${completedOn ?? 'Unknown'}',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight:FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // 👁️ Eye Icon (if onTap is provided)
        if (onTap != null)
          InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFB3E5FC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.remove_red_eye_outlined,
                size: 20,
                color: Colors.black87,
              ),
            ),
          ),
      ],
    ),
  );
}
