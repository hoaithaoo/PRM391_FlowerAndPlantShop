import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

class HomeStoreLocationCard extends StatelessWidget {
  const HomeStoreLocationCard({super.key, required this.onOpenMap});

  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Material(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          key: const Key('home-open-store-map'),
          onTap: onOpenMap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Vị trí cửa hàng',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Xem bản đồ và tìm cửa hàng gần bạn',
                        style: TextStyle(
                          color: Color(0xFF526158),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary,
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
