import 'package:flutter/material.dart';

abstract final class NotificationColors {
  static const forest950 = Color(0xFF0D1E15);
  static const forest900 = Color(0xFF132B1E);
  static const forest800 = Color(0xFF193828);
  static const forest700 = Color(0xFF224A35);
  static const forest100 = Color(0xFFE2F0E9);
  static const forest50 = Color(0xFFF1F7F4);

  static const petal500 = Color(0xFFA84366);
  static const petal400 = Color(0xFFD982A0);
  static const petal200 = Color(0xFFF6D6E1);
  static const petal100 = Color(0xFFFCEAF0);

  static const cream100 = Color(0xFFFFF8FA);
  static const creamPastel = Color(0xFFFFF5F7);
  static const cream200 = Color(0xFFFCEEF2);

  static const charcoal900 = Color(0xFF171C19);
  static const charcoal700 = Color(0xFF36403A);
  static const charcoal500 = Color(0xFF6B7770);
  static const charcoal400 = Color(0xFF8E9993);
  static const white = Color(0xFFFFFFFF);
}

abstract final class NotificationTextStyles {
  static const sans = 'Plus Jakarta Sans';
  static const serif = 'Cormorant Garamond';
  static const script = 'Dancing Script';

  static const cardTitle = TextStyle(
    fontFamily: serif,
    fontSize: 18,
    height: 1.15,
    fontWeight: FontWeight.w600,
    color: NotificationColors.charcoal900,
  );

  static const body = TextStyle(
    fontFamily: sans,
    fontSize: 12.5,
    height: 1.48,
    fontWeight: FontWeight.w400,
    color: NotificationColors.charcoal700,
  );

  static const caption = TextStyle(
    fontFamily: sans,
    fontSize: 10.5,
    height: 1.3,
    fontWeight: FontWeight.w500,
    color: NotificationColors.charcoal500,
  );
}

abstract final class NotificationAssets {
  static const orderWorkshop = 'assets/notifications/order_workshop.png';
  static const autumnCollection = 'assets/notifications/autumn_collection.png';
  static const profileAvatar = 'assets/notifications/profile_avatar.png';
}
