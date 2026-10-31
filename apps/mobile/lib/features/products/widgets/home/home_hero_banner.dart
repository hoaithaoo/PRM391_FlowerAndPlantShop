import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Banner hero bo góc (Penpot: "Editorial Hero Section").
///
/// Ảnh nền + scrim `primaryDark` từ dưới lên (90% → 40% → 0%), overline,
/// tiêu đề và nút pill "Khám phá bộ sưu tập".
class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({super.key, required this.onExplore});

  final VoidCallback onExplore;

  static const _minHeight = 261.0;
  static const _image = 'assets/home/hero_banner.png';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  _image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: AppColors.primaryActive),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.primaryDark.withValues(alpha: 0.9),
                        AppColors.primaryDark.withValues(alpha: 0.4),
                        AppColors.primaryDark.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.5, 1],
                    ),
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minHeight: _minHeight),
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BOUTIQUE CURATIONS',
                      style: AppTextStyles.overline.copyWith(
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tạo không gian sống với thực vật & hoa tươi tự nhiên',
                      style: AppTextStyles.headline2.copyWith(
                        color: AppColors.textLight,
                        height: 1.375,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ExploreButton(onTap: onExplore),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreButton extends StatelessWidget {
  const _ExploreButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
    );
    return Material(
      color: AppColors.surface,
      shape: shape,
      child: InkWell(
        key: const Key('home-hero-cta'),
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Khám phá bộ sưu tập',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.sans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryActive,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward,
                size: 12,
                color: AppColors.primaryActive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
