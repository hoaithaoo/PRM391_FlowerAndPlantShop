import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../../../app/main_shell.dart';
import '../../auth/data/auth_scope.dart';
import '../../checkout/data/checkout_repository.dart';
import '../../checkout/screens/address_list_screen.dart';
import '../../checkout/state/checkout_flow_controller.dart';
import '../data/profile_repository.dart';
import '../models/profile_models.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'order_list_screen.dart';

/// Tab Tài khoản.
class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.repository,
    required this.checkoutRepository,
    this.onSignOut,
  });

  final ProfileRepository repository;
  final CheckoutRepository checkoutRepository;
  final VoidCallback? onSignOut;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  UserProfile? _profile;
  bool _loadFailed = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final profile = await widget.repository.getProfile();
      if (mounted) setState(() => _profile = profile);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changeAvatar() async {
    if (_uploading) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final profile = await widget.repository.uploadAvatar(
        await picked.readAsBytes(),
        picked.mimeType ?? 'image/jpeg',
      );
      if (mounted) setState(() => _profile = profile);
    } catch (error) {
      if (mounted) _showMessage(profileErrorMessage(error));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _editProfile(UserProfile profile) async {
    final updated = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute<UserProfile>(
        builder: (_) =>
            EditProfileScreen(repository: widget.repository, profile: profile),
      ),
    );
    if (updated != null && mounted) setState(() => _profile = updated);
  }

  Future<void> _openAddresses() async {
    final controller = CheckoutFlowController();
    try {
      controller.setAddresses(await widget.checkoutRepository.listAddresses());
    } catch (_) {
      controller.dispose();
      if (mounted) _showMessage('Không tải được sổ địa chỉ. Vui lòng thử lại.');
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AddressListScreen(
          controller: controller,
          onSave: widget.checkoutRepository.saveAddress,
        ),
      ),
    );
    controller.dispose();
  }

  void _push(WidgetBuilder builder) {
    Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: builder));
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile == null) {
      return Center(
        child: _loadFailed
            ? TextButton(
                key: const Key('account-retry'),
                onPressed: _load,
                child: const Text('Không tải được hồ sơ. Chạm để thử lại.'),
              )
            : const CircularProgressIndicator(),
      );
    }
    final auth = AuthScope.of(context);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          24,
          20,
          AppBottomNav.reservedHeight + 16,
        ),
        children: [
          Center(
            child: _Avatar(
              url: profile.avatarUrl,
              uploading: _uploading,
              onTap: _changeAvatar,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.fullName ?? 'Khách hàng',
            key: const Key('account-name'),
            textAlign: TextAlign.center,
            style: AppTextStyles.headline2,
          ),
          if (profile.email != null)
            Text(
              profile.email!,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            ),
          const SizedBox(height: 24),
          _MenuTile(
            key: const Key('account-edit'),
            icon: Icons.person_outline,
            label: 'Thông tin cá nhân',
            onTap: () => _editProfile(profile),
          ),
          _MenuTile(
            key: const Key('account-orders'),
            icon: Icons.receipt_long_outlined,
            label: 'Đơn hàng của tôi',
            onTap: () =>
                _push((_) => OrderListScreen(repository: widget.repository)),
          ),
          _MenuTile(
            key: const Key('account-addresses'),
            icon: Icons.location_on_outlined,
            label: 'Sổ địa chỉ',
            onTap: _openAddresses,
          ),
          if (auth.canChangePassword)
            _MenuTile(
              key: const Key('account-password'),
              icon: Icons.lock_outline,
              label: 'Đổi mật khẩu',
              onTap: () => _push((_) => const ChangePasswordScreen()),
            ),
          const SizedBox(height: 16),
          if (widget.onSignOut != null)
            OutlinedButton(
              key: const Key('account_sign_out'),
              onPressed: widget.onSignOut,
              child: const Text('Đăng xuất'),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url, required this.uploading, required this.onTap});

  final String? url;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = url;
    return Semantics(
      button: true,
      label: 'Đổi ảnh đại diện',
      child: InkWell(
        key: const Key('account-avatar'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.surfacePastel,
              foregroundImage: image == null ? null : NetworkImage(image),
              child: const Icon(
                Icons.person_outline,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.primary,
                child: uploading
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textLight,
                        ),
                      )
                    : const Icon(
                        Icons.photo_camera_outlined,
                        size: 15,
                        color: AppColors.textLight,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: AppTextStyles.body),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
