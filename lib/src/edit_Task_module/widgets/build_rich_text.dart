import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildRichText(String label, String value) {
  return RichText(
    text: TextSpan(
      style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600),
      children: [
        TextSpan(text: '# ', style: GoogleFonts.lato(color: Colors.grey)),
        TextSpan(
          text: '$label :  ',
          style: GoogleFonts.lato(color: Colors.black),
        ),
        TextSpan(text:value, style: GoogleFonts.lato(color: Colors.grey)),
      ],
    ),
  );
}
