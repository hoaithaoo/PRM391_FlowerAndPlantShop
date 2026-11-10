import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      color: _Palette.background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(
            bottom: AppBottomNav.reservedHeight + 24,
          ),
          children: [
            _AccountHeader(avatarUrl: profile.avatarUrl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileCard(
                    profile: profile,
                    uploading: _uploading,
                    onAvatarTap: _changeAvatar,
                    onEdit: () => _editProfile(profile),
                  ),
                  const SizedBox(height: 24),
                  _OrderSection(counts: _orderCounts, onOpen: _openOrders),
                  const SizedBox(height: 24),
                  _MenuSection(
                    title: 'TÀI KHOẢN & MUA HÀNG',
                    children: [
                      _MenuTile(
                        key: const Key('account-edit'),
                        icon: const _Asset('person'),
                        label: 'Thông tin cá nhân',
                        subtitle: 'Họ tên và số điện thoại',
                        onTap: () => _editProfile(profile),
                      ),
                      _MenuTile(
                        key: const Key('account-orders'),
                        icon: const _Asset('receipt'),
                        label: 'Đơn hàng của tôi',
                        subtitle: 'Lịch sử đặt hoa & tiến độ vận chuyển',
                        showDot: (_orderCounts['PENDING'] ?? 0) > 0,
                        onTap: _openOrders,
                      ),
                      _MenuTile(
                        key: const Key('account-addresses'),
                        icon: const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: _Palette.ink,
                        ),
                        label: 'Sổ địa chỉ',
                        subtitle: 'Địa chỉ nhận hoa đã lưu',
                        onTap: _openAddresses,
                      ),
                      if (auth.canChangePassword)
                        _MenuTile(
                          key: const Key('account-password'),
                          icon: const Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: _Palette.ink,
                          ),
                          label: 'Đổi mật khẩu',
                          subtitle: 'Cập nhật mật khẩu đăng nhập',
                          onTap: () =>
                              _push((_) => const ChangePasswordScreen()),
                        ),
                    ],
                  ),
                  if (widget.onSignOut != null) ...[
                    const SizedBox(height: 24),
                    _MenuSection(
                      title: 'HỆ THỐNG & QUY ĐỊNH',
                      children: [
                        _MenuTile(
                          key: const Key('account_sign_out'),
                          icon: const _Asset('logout'),
                          iconBackground: _Palette.logoutSurface,
                          label: 'Đăng xuất',
                          labelColor: _Palette.rose,
                          chevron: 'chevron_logout',
                          subtitle: 'Rời tài khoản tạm thời khỏi thiết bị',
                          onTap: widget.onSignOut!,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  const _BrandFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Màu riêng của màn Tài khoản theo Figma (node 5:3116).
abstract final class _Palette {
  static const background = Color(0xFFFCF9F3);
  static const card = Color(0xFFFFFDF9);
  static const chip = Color(0xFFF6F3ED);
  static const iconCircle = Color(0xFFF0EEE8);
  static const ink = Color(0xFF242623);
  static const muted = Color(0xFF77736D);
  static const moss = Color(0xFF566252);
  static const rose = Color(0xFFB98286);
  static const logoutSurface = Color(0x80FFDAD6);
  static const cardShadow = [
    BoxShadow(color: Color(0x08242623), offset: Offset(0, 4), blurRadius: 20),
  ];
  static const groupShadow = [
    BoxShadow(color: Color(0x05242623), offset: Offset(0, 3), blurRadius: 16),
  ];
}

/// Icon SVG xuất từ Figma, giữ đúng kích thước gốc.
class _Asset extends StatelessWidget {
  const _Asset(this.name);

  final String name;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/account/$name.svg');
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    return Container(
      height: 64,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: const Color(0xD9FFFDF9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Nhà Có Hoa',
            style: AppTextStyles.brandLogo.copyWith(fontSize: 26),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: _Palette.chip,
            foregroundImage: url == null ? null : NetworkImage(url),
            child: const Icon(
              Icons.person_outline,
              size: 16,
              color: _Palette.moss,
            ),
          ),
        ],
      ),
    );
  }
}

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

  /// Che bớt email như thiết kế: `ph***@gmail.com`.
  static String _maskEmail(String email) {
    final at = email.indexOf('@');
    if (at < 0) return email;
    final name = email.substring(0, at);
    final visible = name.length < 2 ? name : name.substring(0, 2);
    return '$visible***${email.substring(at)}';
  }

  /// 0912345678 thành 0912 345 678.
  static String _formatPhone(String phone) => phone.length == 10
      ? '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7)}'
      : phone;

  @override
  Widget build(BuildContext context) {
    final detail = AppFonts.sans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: _Palette.muted,
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _Palette.cardShadow,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              profile.fullName ?? 'Khách hàng',
                              key: const Key('account-name'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.serif(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 26 / 18,
                                color: _Palette.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _EditChip(onTap: onEdit),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (profile.email != null)
                        Text(
                          _maskEmail(profile.email!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: detail,
                        ),
                      if (profile.phone != null)
                        Text(_formatPhone(profile.phone!), style: detail),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditChip extends StatelessWidget {
  const _EditChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _Palette.chip,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        key: const Key('account-edit-chip'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Asset('edit'),
              const SizedBox(width: 4),
              Text(
                'Sửa',
                style: AppFonts.sans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 16 / 11,
                  color: _Palette.moss,
                ),
              ),
            ],
          ),
        ),
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
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: _Palette.chip,
              foregroundImage: image == null ? null : NetworkImage(image),
              child: const Icon(
                Icons.person_outline,
                size: 28,
                color: _Palette.moss,
              ),
            ),
            if (uploading)
              const Positioned.fill(
                child: Center(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderStep {
  const _OrderStep(this.status, this.label, this.asset);

  final String status;
  final String label;
  final String asset;
}

const _orderSteps = <_OrderStep>[
  _OrderStep('PENDING', 'Chờ duyệt', 'step_pending'),
  _OrderStep('PREPARING', 'Đang cắm', 'step_preparing'),
  _OrderStep('SHIPPING', 'Đang giao', 'step_shipping'),
  _OrderStep('COMPLETED', 'Đã giao', 'step_completed'),
];

class _OrderSection extends StatelessWidget {
  const _OrderSection({required this.counts, required this.onOpen});

  final Map<String, int> counts;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Đơn hàng gần đây',
                  style: AppFonts.serif(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 26 / 18,
                    color: _Palette.ink,
                  ),
                ),
              ),
              InkWell(
                key: const Key('account-orders-all'),
                onTap: onOpen,
                child: Row(
                  children: [
                    Text(
                      'Tất cả',
                      style: AppFonts.sans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 16 / 11,
                        color: _Palette.moss,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const _Asset('chevron_small'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final step in _orderSteps) ...[
              Expanded(
                child: _OrderStepTile(
                  step: step,
                  count: counts[step.status] ?? 0,
                  onTap: onOpen,
                ),
              ),
              if (step != _orderSteps.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
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
    final inProgress = step.status == 'PREPARING' && count > 0;
    return Material(
      color: _Palette.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: Key('account-step-${step.status}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _Palette.chip,
                  shape: BoxShape.circle,
                ),
                child: _Asset(step.asset),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  step.label,
                  maxLines: 1,
                  style: AppFonts.sans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                    color: _Palette.ink,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  inProgress ? 'Đang làm' : '$count đơn',
                  maxLines: 1,
                  style: AppFonts.sans(
                    fontSize: 10,
                    fontWeight: inProgress ? FontWeight.w500 : FontWeight.w400,
                    height: 2.2,
                    color: inProgress ? _Palette.rose : _Palette.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            title,
            style: AppFonts.sans(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              height: 2.1,
              letterSpacing: 0.525,
              color: _Palette.muted,
            ),
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _Palette.groupShadow,
          ),
          child: Material(
            color: _Palette.card,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: _Palette.chip),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
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
    this.iconBackground = _Palette.iconCircle,
    this.labelColor = _Palette.ink,
    this.chevron = 'chevron',
    this.showDot = false,
  });

  final Widget icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconBackground;
  final Color labelColor;
  final String chevron;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: icon,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppFonts.sans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 22 / 14,
                      color: labelColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppFonts.sans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: _Palette.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (showDot) ...[
              const SizedBox(width: 8),
              const SizedBox.square(
                key: Key('account-orders-dot'),
                dimension: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _Palette.rose,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            _Asset(chevron),
          ],
        ),
      ),
    );
  }
}

class _BrandFooter extends StatelessWidget {
  const _BrandFooter();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.7,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _Asset('footer_leaf'),
          const SizedBox(width: 6),
          Text(
            'NHÀ CÓ HOA',
            style: AppFonts.sans(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              height: 2,
              letterSpacing: 1.1,
              color: _Palette.moss,
            ),
          ),
        ],
      ),
    );
  }
}
