import 'package:flutter/material.dart';

import '../models/notification_item.dart';
import '../models/notification_type.dart';
import '../utils/notification_theme.dart';
import '../utils/notification_time_formatter.dart';
import 'notification_type_icon.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.isUpdating,
    required this.onTap,
  });

  final NotificationItem notification;
  final bool isUpdating;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: notification.isRead
            ? NotificationColors.white
            : NotificationColors.petal100.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? NotificationColors.cream200
              : NotificationColors.petal200,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isUpdating ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: switch (notification.type) {
              NotificationType.order => _OrderCard(notification: notification),
              NotificationType.payment => _PaymentCard(
                notification: notification,
              ),
              NotificationType.promotion => _PromotionCard(
                notification: notification,
              ),
              NotificationType.system => _SystemCard(
                notification: notification,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.notification});

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _RoundedAssetImage(
              asset: notification.imageAsset,
              width: 46,
              height: 46,
              fallbackType: notification.type,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _TitleTimeRow(notification: notification),
                  const SizedBox(height: 5),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: NotificationTextStyles.body,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      if (notification.badge != null)
                        _MetadataPill(
                          icon: Icons.local_florist_outlined,
                          label: notification.badge!,
                        ),
                      if (notification.secondaryAction != null)
                        Text(
                          notification.secondaryAction!,
                          style: NotificationTextStyles.caption.copyWith(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 11),
          child: Divider(height: 1, color: NotificationColors.cream200),
        ),
        Row(
          children: <Widget>[
            const Icon(
              Icons.touch_app_outlined,
              size: 14,
              color: NotificationColors.charcoal500,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                notification.isRead
                    ? 'Chạm để xem chi tiết'
                    : 'Chạm để đánh dấu đã đọc',
                style: NotificationTextStyles.caption,
              ),
            ),
            Text(
              notification.isRead ? 'Đã đọc ✓' : 'Chưa đọc',
              style: NotificationTextStyles.caption.copyWith(
                color: NotificationColors.forest900,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.notification});

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        NotificationTypeIcon(type: notification.type),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _TitleTimeRow(notification: notification),
              const SizedBox(height: 6),
              Text(
                notification.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: NotificationTextStyles.body,
              ),
              const SizedBox(height: 9),
              Row(
                children: <Widget>[
                  if (notification.badge != null)
                    Flexible(
                      child: _MetadataPill(
                        icon: Icons.verified_outlined,
                        label: notification.badge!,
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (notification.amount != null)
                    Text(
                      notification.amount!,
                      style: NotificationTextStyles.caption.copyWith(
                        color: NotificationColors.charcoal900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({required this.notification});

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        NotificationTypeIcon(type: notification.type),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _TitleTimeRow(notification: notification),
              const SizedBox(height: 6),
              Text(
                notification.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: NotificationTextStyles.body,
              ),
              const SizedBox(height: 9),
              Stack(
                children: <Widget>[
                  _RoundedAssetImage(
                    asset: notification.imageAsset,
                    width: double.infinity,
                    height: 82,
                    radius: 9,
                    fallbackType: notification.type,
                  ),
                  if (notification.badge != null)
                    Positioned(
                      left: 8,
                      bottom: 7,
                      child: _MetadataPill(label: notification.badge!),
                    ),
                ],
              ),
              const SizedBox(height: 9),
              if (notification.secondaryAction != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      notification.secondaryAction!,
                      style: NotificationTextStyles.caption.copyWith(
                        color: NotificationColors.charcoal900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_forward,
                      size: 13,
                      color: NotificationColors.charcoal900,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SystemCard extends StatelessWidget {
  const _SystemCard({required this.notification});

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        NotificationTypeIcon(type: notification.type),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _TitleTimeRow(notification: notification),
              const SizedBox(height: 6),
              Text(
                notification.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: NotificationTextStyles.body,
              ),
              if (notification.badge != null) ...<Widget>[
                const SizedBox(height: 9),
                _MetadataPill(
                  icon: Icons.info_outline,
                  label: notification.badge!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TitleTimeRow extends StatelessWidget {
  const _TitleTimeRow({required this.notification});

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            notification.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: NotificationTextStyles.cardTitle.copyWith(
              fontWeight: notification.isRead
                  ? FontWeight.w600
                  : FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            notification.timeLabel ??
                formatNotificationTime(notification.createdAt),
            style: NotificationTextStyles.caption.copyWith(
              color: notification.isRead
                  ? NotificationColors.charcoal500
                  : NotificationColors.petal500,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetadataPill extends StatelessWidget {
  const _MetadataPill({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: NotificationColors.forest50,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: NotificationColors.forest100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 11, color: NotificationColors.forest700),
              const SizedBox(width: 3),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: NotificationTextStyles.caption.copyWith(
                  fontSize: 9.5,
                  color: NotificationColors.forest700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundedAssetImage extends StatelessWidget {
  const _RoundedAssetImage({
    required this.asset,
    required this.width,
    required this.height,
    required this.fallbackType,
    this.radius = 10,
  });

  final String? asset;
  final double width;
  final double height;
  final double radius;
  final NotificationType fallbackType;

  @override
  Widget build(BuildContext context) {
    final fallback = SizedBox(
      width: width,
      height: height,
      child: NotificationTypeIcon(type: fallbackType, size: 42),
    );
    if (asset == null) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        asset!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
