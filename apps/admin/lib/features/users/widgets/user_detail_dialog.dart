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
    final hasValidName = user.fullName != null && user.fullName!.trim().isNotEmpty;
    final displayName = hasValidName
        ? user.fullName!.trim()
        : (user.email.contains('@') ? user.email.split('@').first : 'Khách hàng');
    final avatarLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
          child: SingleChildScrollView(
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
                        color: AppColors.textHeading,
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
                      radius: 26,
                      backgroundColor: user.isAdmin
                          ? AppColors.primary
                          : AppColors.petal500.withValues(alpha: 0.2),
                      child: Text(
                        avatarLetter,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: user.isAdmin ? Colors.white : AppColors.petal500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textHeading,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user.email,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                  user.isAdmin ? 'ADMIN' : 'USER',
                  badgeColor: user.isAdmin ? AppColors.primaryLight : AppColors.surfacePastel,
                  badgeTextColor: user.isAdmin ? AppColors.primary : AppColors.petal500,
                ),
                _buildInfoRow(
                  'Trạng thái tài khoản',
                  user.isActive ? 'Đang hoạt động' : 'Bị vô hiệu hóa',
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
                  children: [
                    // Change Role Button
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                        icon: Icon(
                          user.isAdmin ? Icons.person_outline : Icons.shield_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          user.isAdmin ? 'Chuyển về USER' : 'Thăng cấp ADMIN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () {
                          final newRole = user.isAdmin ? UserRole.user : UserRole.admin;
                          context.read<UserBloc>().add(
                            UpdateUserRoleEvent(userId: user.id, newRole: newRole),
                          );
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Toggle Status (Lock / Unlock) Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: user.isActive
                              ? AppColors.statusCancelled
                              : AppColors.statusDelivered,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                        ),
                        icon: Icon(
                          user.isActive ? Icons.lock_outline : Icons.lock_open,
                          size: 16,
                        ),
                        label: Text(
                          user.isActive ? 'Khóa tài khoản' : 'Mở khóa',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                    ),
                  ],
                ),
              ],
            ),
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
          const SizedBox(width: 8),
          Flexible(
            child: badgeColor != null && badgeTextColor != null
                ? Container(
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHeading,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
          ),
        ],
      ),
    );
  }
}
