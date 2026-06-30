import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

Widget buildPremiumTitle(String title, {double fontSize = 22, double height = 32}) {
  return SizedBox(
    height: height, // Controlled layout constraint preventing overflow thrashing
    child: title.length > 24 
      ? Marquee(
          text: title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: fontSize, letterSpacing: -0.5),
          scrollAxis: Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.center,
          blankSpace: 80.0,
          velocity: 35.0, // Ultra-smooth, non-distracting reading speed
          pauseAfterRound: const Duration(seconds: 3),
          startPadding: 0.0,
          accelerationDuration: const Duration(seconds: 1),
          accelerationCurve: Curves.easeIn,
          decelerationDuration: const Duration(milliseconds: 500),
          decelerationCurve: Curves.easeOut,
        )
      : Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: fontSize, letterSpacing: -0.5),
        ),
  );
}