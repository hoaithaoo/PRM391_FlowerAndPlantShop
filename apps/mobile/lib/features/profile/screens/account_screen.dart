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
  Map<String, int> _orderCounts = const <String, int>{};

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
      return;
    }
    await _loadOrderCounts();
  }

  /// Số đơn chỉ để hiển thị, lỗi thì giữ số 0 thay vì chặn cả màn.
  Future<void> _loadOrderCounts() async {
    try {
      final counts = await widget.repository.orderCounts(
        _orderSteps.map((step) => step.status).toList(growable: false),
      );
      if (mounted) setState(() => _orderCounts = counts);
    } catch (_) {}
  }

  Future<void> _openOrders() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => OrderListScreen(repository: widget.repository),
      ),
    );
    if (mounted) await _loadOrderCounts();
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
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            AppBottomNav.reservedHeight + 16,
          ),
          children: [
            _ProfileCard(
              profile: profile,
              uploading: _uploading,
              onAvatarTap: _changeAvatar,
              onEdit: () => _editProfile(profile),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Đơn hàng gần đây',
                    style: AppTextStyles.headline2,
                  ),
                ),
                TextButton(
                  key: const Key('account-orders-all'),
                  onPressed: _openOrders,
                  child: const Text('Tất cả ›'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final step in _orderSteps) ...[
                  Expanded(
                    child: _OrderStepTile(
                      step: step,
                      count: _orderCounts[step.status] ?? 0,
                      onTap: _openOrders,
                    ),
                  ),
                  if (step != _orderSteps.last) const SizedBox(width: 8),
                ],
              ],
            ),
            const _SectionTitle('TÀI KHOẢN & MUA HÀNG'),
            _MenuGroup(
              children: [
                _MenuTile(
                  key: const Key('account-edit'),
                  icon: Icons.person_outline,
                  label: 'Thông tin cá nhân',
                  subtitle: 'Họ tên và số điện thoại',
                  onTap: () => _editProfile(profile),
                ),
                _MenuTile(
                  key: const Key('account-orders'),
                  icon: Icons.receipt_long_outlined,
                  label: 'Đơn hàng của tôi',
                  subtitle: 'Lịch sử đặt hoa & tiến độ vận chuyển',
                  onTap: _openOrders,
                ),
                _MenuTile(
                  key: const Key('account-addresses'),
                  icon: Icons.location_on_outlined,
                  label: 'Sổ địa chỉ',
                  subtitle: 'Địa chỉ nhận hoa đã lưu',
                  onTap: _openAddresses,
                ),
                if (auth.canChangePassword)
                  _MenuTile(
                    key: const Key('account-password'),
                    icon: Icons.lock_outline,
                    label: 'Đổi mật khẩu',
                    subtitle: 'Cập nhật mật khẩu đăng nhập',
                    onTap: () => _push((_) => const ChangePasswordScreen()),
                  ),
              ],
            ),
            if (widget.onSignOut != null) ...[
              const _SectionTitle('HỆ THỐNG'),
              _MenuGroup(
                children: [
                  _MenuTile(
                    key: const Key('account_sign_out'),
                    icon: Icons.logout,
                    label: 'Đăng xuất',
                    subtitle: 'Rời tài khoản khỏi thiết bị',
                    color: AppColors.accentSoft,
                    onTap: widget.onSignOut!,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderStep {
  const _OrderStep(this.status, this.label, this.icon);

  final String status;
  final String label;
  final IconData icon;
}

const _orderSteps = <_OrderStep>[
  _OrderStep('PENDING', 'Chờ duyệt', Icons.assignment_turned_in_outlined),
  _OrderStep('PREPARING', 'Đang cắm', Icons.content_cut),
  _OrderStep('SHIPPING', 'Đang giao', Icons.local_shipping_outlined),
  _OrderStep('COMPLETED', 'Đã giao', Icons.inventory_2_outlined),
];

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.uploading,
    required this.onAvatarTap,
    required this.onEdit,
  });

  final UserProfile profile;
  final bool uploading;
  final VoidCallback onAvatarTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final muted = AppTextStyles.body.copyWith(color: AppColors.textMuted);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          _Avatar(
            url: profile.avatarUrl,
            uploading: uploading,
            onTap: onAvatarTap,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName ?? 'Khách hàng',
                  key: const Key('account-name'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headline2,
                ),
                if (profile.email != null)
                  Text(
                    profile.email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                if (profile.phone != null) Text(profile.phone!, style: muted),
              ],
            ),
          ),
          TextButton.icon(
            key: const Key('account-edit-chip'),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 14),
            label: const Text('Sửa'),
          ),
        ],
      ),
    );
  }
}

class _OrderStepTile extends StatelessWidget {
  const _OrderStepTile({
    required this.step,
    required this.count,
    required this.onTap,
  });

  final _OrderStep step;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key('account-step-${step.status}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfacePastel,
                child: Icon(step.icon, size: 20, color: AppColors.textHeading),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(step.label, style: AppTextStyles.caption),
              ),
              const SizedBox(height: 2),
              Text(
                '$count đơn',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            children[i],
          ],
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
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.surfacePastel,
        child: Icon(icon, size: 18, color: color ?? AppColors.textHeading),
      ),
      title: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: color ?? AppColors.textHeading,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: color),
      onTap: onTap,
    );
  }
}
