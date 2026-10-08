import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';
import '../bloc/user_bloc.dart';
import '../bloc/user_event.dart';

class UserDetailDialog extends StatelessWidget {
  final UserProfile user;

  const UserDetailDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chi Tiết Người Dùng',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 24),

              // Avatar & Basic Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: user.isAdmin
                        ? AppColors.primary
                        : AppColors.petal500.withValues(alpha: 0.2),
                    child: Text(
                      user.fullName != null && user.fullName!.isNotEmpty
                          ? user.fullName![0].toUpperCase()
                          : user.email[0].toUpperCase(),
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: user.isAdmin ? Colors.white : AppColors.petal500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName ?? 'Chưa cập nhật tên',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Info Table Rows
              _buildInfoRow('Số điện thoại', user.phone ?? 'Chưa cung cấp'),
              _buildInfoRow(
                'Vai trò',
                user.isAdmin ? 'Quản trị viên (ADMIN)' : 'Khách hàng (USER)',
                badgeColor: user.isAdmin ? AppColors.primaryLight : AppColors.surfacePastel,
                badgeTextColor: user.isAdmin ? AppColors.primary : AppColors.petal500,
              ),
              _buildInfoRow(
                'Trạng thái tài khoản',
                user.isActive ? 'Đang hoạt động (ACTIVE)' : 'Bị vô hiệu hóa (DISABLED)',
                badgeColor: user.isActive ? AppColors.forest100 : const Color(0xFFFFEBEE),
                badgeTextColor: user.isActive ? AppColors.primary : AppColors.statusCancelled,
              ),
              if (user.createdAt != null)
                _buildInfoRow('Ngày đăng ký', dateFormat.format(user.createdAt!)),

              const SizedBox(height: 24),
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Change Role Button
                  OutlinedButton.icon(
                    icon: Icon(
                      user.isAdmin ? Icons.person_outline : Icons.shield_outlined,
                      size: 18,
                    ),
                    label: Text(user.isAdmin ? 'Chuyển về USER' : 'Thăng cấp ADMIN'),
                    onPressed: () {
                      final newRole = user.isAdmin ? UserRole.user : UserRole.admin;
                      context.read<UserBloc>().add(
                        UpdateUserRoleEvent(userId: user.id, newRole: newRole),
                      );
                      Navigator.of(context).pop();
                    },
                  ),

                  // Toggle Status (Lock / Unlock) Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: user.isActive
                          ? AppColors.statusCancelled
                          : AppColors.statusDelivered,
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(
                      user.isActive ? Icons.lock_outline : Icons.lock_open,
                      size: 18,
                    ),
                    label: Text(user.isActive ? 'Khóa tài khoản' : 'Mở khóa'),
                    onPressed: () {
                      final newStatus = user.isActive
                          ? AccountStatus.disabled
                          : AccountStatus.active;
                      context.read<UserBloc>().add(
                        UpdateUserStatusEvent(userId: user.id, newStatus: newStatus),
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          if (badgeColor != null && badgeTextColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: badgeTextColor,
                ),
              ),
            )
          else
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
              ),
            ),
        ],
      ),
    );
  }
}
