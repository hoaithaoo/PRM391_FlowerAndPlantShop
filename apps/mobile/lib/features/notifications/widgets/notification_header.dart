import 'package:flutter/material.dart';

import '../utils/notification_theme.dart';

class NotificationHeader extends StatelessWidget {
  const NotificationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: NotificationColors.white,
        border: Border(bottom: BorderSide(color: NotificationColors.cream200)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  tooltip: 'Quay lại',
                  icon: const Icon(Icons.arrow_back, size: 22),
                  color: NotificationColors.charcoal700,
                ),
                const Icon(
                  Icons.local_florist_outlined,
                  size: 16,
                  color: NotificationColors.forest700,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Fleuré',
                  style: TextStyle(
                    fontFamily: NotificationTextStyles.serif,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: NotificationColors.forest900,
                  ),
                ),
              ],
            ),
          ),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Thông Báo',
                style: TextStyle(
                  fontFamily: NotificationTextStyles.serif,
                  fontSize: 17,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: NotificationColors.charcoal900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Fleuré',
                style: TextStyle(
                  fontFamily: NotificationTextStyles.serif,
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: NotificationColors.charcoal900,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  onPressed: () {},
                  tooltip: 'Thông báo',
                  icon: const Icon(Icons.notifications_none_rounded, size: 21),
                  color: NotificationColors.forest900,
                ),
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: NotificationColors.forest100,
                  backgroundImage: AssetImage(NotificationAssets.profileAvatar),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
