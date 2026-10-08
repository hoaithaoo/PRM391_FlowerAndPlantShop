import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';
import '../bloc/user_bloc.dart';
import '../bloc/user_event.dart';
import '../bloc/user_state.dart';
import '../widgets/user_detail_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();
  UserRole? _selectedRole;
  AccountStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    context.read<UserBloc>().add(const FetchUsersEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    context.read<UserBloc>().add(
      FetchUsersEvent(
        search: _searchController.text.trim(),
        role: _selectedRole,
        status: _selectedStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Quản Lý Người Dùng',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textLight,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới danh sách',
            onPressed: _onFilterChanged,
          ),
        ],
      ),
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.statusDelivered,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is UserError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.statusCancelled,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Search & Filter Bar
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.white,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm theo tên, email hoặc số điện thoại...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _onFilterChanged();
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) => _onFilterChanged(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Role Filter Dropdown
                        Expanded(
                          child: DropdownButtonFormField<UserRole?>(
                            initialValue: _selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'Vai trò',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('Tất cả vai trò')),
                              DropdownMenuItem(value: UserRole.admin, child: Text('ADMIN (Quản trị)')),
                              DropdownMenuItem(value: UserRole.user, child: Text('USER (Khách hàng)')),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedRole = val;
                              });
                              _onFilterChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Status Filter Dropdown
                        Expanded(
                          child: DropdownButtonFormField<AccountStatus?>(
                            initialValue: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Trạng thái',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('Tất cả trạng thái')),
                              DropdownMenuItem(value: AccountStatus.active, child: Text('ACTIVE (Hoạt động)')),
                              DropdownMenuItem(value: AccountStatus.disabled, child: Text('DISABLED (Đã khóa)')),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedStatus = val;
                              });
                              _onFilterChanged();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),

              // Content List
              Expanded(
                child: _buildUserList(state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserList(UserState state) {
    if (state is UserLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state is UserLoaded) {
      if (state.users.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_outline, size: 56, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'Không tìm thấy người dùng nào phù hợp',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textMuted,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: state.users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final user = state.users[index];
          return _buildUserCard(user);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildUserCard(UserProfile user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: user.isAdmin
                  ? AppColors.primaryLight
                  : AppColors.petal500.withValues(alpha: 0.15),
              child: Text(
                user.fullName != null && user.fullName!.isNotEmpty
                    ? user.fullName![0].toUpperCase()
                    : user.email[0].toUpperCase(),
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: user.isAdmin ? AppColors.primary : AppColors.petal500,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.fullName ?? 'Khách hàng',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: user.isAdmin ? AppColors.primaryLight : AppColors.surfacePastel,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          user.role.name.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: user.isAdmin ? AppColors.primary : AppColors.petal500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: user.isActive ? AppColors.forest100 : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.status.name.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: user.isActive ? AppColors.primary : AppColors.statusCancelled,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (user.phone != null && user.phone!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'SĐT: ${user.phone}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Lock / Unlock Button
                IconButton(
                  tooltip: user.isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản',
                  icon: Icon(
                    user.isActive ? Icons.lock_outline : Icons.lock_open,
                    color: user.isActive ? AppColors.statusCancelled : AppColors.statusDelivered,
                    size: 20,
                  ),
                  onPressed: () {
                    final nextStatus = user.isActive
                        ? AccountStatus.disabled
                        : AccountStatus.active;
                    context.read<UserBloc>().add(
                      UpdateUserStatusEvent(userId: user.id, newStatus: nextStatus),
                    );
                  },
                ),
                // Detail Button
                IconButton(
                  tooltip: 'Xem chi tiết',
                  icon: const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => BlocProvider.value(
                        value: context.read<UserBloc>(),
                        child: UserDetailDialog(user: user),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
