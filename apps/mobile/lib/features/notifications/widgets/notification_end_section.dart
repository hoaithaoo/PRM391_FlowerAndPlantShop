import 'package:flutter/material.dart';

import '../utils/notification_theme.dart';

class NotificationEndSection extends StatelessWidget {
  const NotificationEndSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 24, 30, 30),
      child: Column(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: NotificationColors.creamPastel,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.spa_outlined,
              size: 20,
              color: NotificationColors.charcoal400,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tất cả yên bình & nở rộ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: NotificationTextStyles.serif,
              fontSize: 20,
              height: 1.2,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: NotificationColors.charcoal700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn đã xem hết thông báo gần đây của Fleuré. Chúc bạn có một ngày tràn ngập hương sắc.',
            textAlign: TextAlign.center,
            style: NotificationTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
