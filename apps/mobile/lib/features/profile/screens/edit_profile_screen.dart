import 'package:flutter/material.dart';

import '../../../core/location/current_address_service.dart';
import '../../../core/location/delivery_location.dart';
import '../../../core/location/location_service.dart';
import '../../auth/screens/delivery_location_picker_screen.dart';
import '../../auth/utils/auth_theme.dart';
import '../../auth/utils/auth_validators.dart';
import '../../auth/widgets/auth_common.dart';
import '../../checkout/data/checkout_repository.dart';
import '../../checkout/models/checkout_flow_models.dart';
import '../data/profile_repository.dart';
import '../models/profile_models.dart';

/// Thông tin cá nhân: cùng bố cục với màn "Hoàn thiện thông tin".
/// Họ tên, số điện thoại lưu qua PUT /profile; địa chỉ mặc định lưu vào
/// Sổ địa chỉ (PUT /addresses/{id}, chưa có thì POST /addresses).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.repository,
    required this.profile,
    this.checkoutRepository,
    this.currentAddressService = const CurrentAddressService(),
    this.onOpenAddressBook,
  });

  final ProfileRepository repository;
  final UserProfile profile;

  /// Null thì ẩn phần địa chỉ (vd. màn được mở ở nơi không có Sổ địa chỉ).
  final CheckoutRepository? checkoutRepository;
  final CurrentAddressService currentAddressService;
  final Future<void> Function()? onOpenAddressBook;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _phone = TextEditingController(text: widget.profile.phone);
  final _addressText = TextEditingController();
  final _details = TextEditingController();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();

  bool _loadingAddress = false;
  bool _addressLoadFailed = false;
  CheckoutAddress? _address;
  DeliveryLocation? _picked;
  bool _showDetails = false;
  bool _saving = false;
  bool _showErrors = false;

  bool get _hasAddressSection => widget.checkoutRepository != null;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _phone, _addressText, _details]) {
      c.addListener(_onChanged);
    }
    if (_hasAddressSection) _loadAddress();
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _addressText, _details]) {
      c.dispose();
    }
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_showErrors) setState(() {});
  }

  Future<void> _loadAddress() async {
    setState(() {
      _loadingAddress = true;
      _addressLoadFailed = false;
    });
    try {
      final items = await widget.checkoutRepository!.listAddresses();
      if (!mounted) return;
      final address =
          items.where((a) => a.isDefault).firstOrNull ?? items.firstOrNull;
      setState(() {
        _address = address;
        _addressText.text = address?.fullAddress ?? '';
        _loadingAddress = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingAddress = false;
          _addressLoadFailed = true;
        });
      }
    }
  }

  DeliveryLocation? get _currentLocation {
    if (_picked != null) return _picked;
    final a = _address;
    if (a == null || !a.hasCoordinates) return null;
    return DeliveryLocation(
      coordinates: LocationCoordinates(
        latitude: a.latitude!,
        longitude: a.longitude!,
        accuracy: 0,
      ),
      address: a.fullAddress,
    );
  }

  Future<void> _openPicker({required bool useCurrentLocation}) async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    final result = await Navigator.of(context).push<DeliveryLocation>(
      MaterialPageRoute(
        builder: (_) => AuthTheme(
          child: DeliveryLocationPickerScreen(
            service: widget.currentAddressService,
            initialLocation: _currentLocation,
            useCurrentLocation: useCurrentLocation,
          ),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _picked = result;
      _addressText.text = result.address;
    });
  }

  Future<void> _openAddressBook() async {
    await widget.onOpenAddressBook?.call();
    if (!mounted) return;
    _picked = null;
    _details.clear();
    await _loadAddress();
  }

  void _useManualAddress() {
    setState(() => _picked = null);
    _addressFocus.requestFocus();
  }

  String? get _nameError =>
      _showErrors ? AuthValidators.fullName(_name.text) : null;
  String? get _phoneError =>
      _showErrors ? AuthValidators.phone(_phone.text) : null;
  String? get _addressError {
    if (!_showErrors || !_hasAddressSection || _addressLoadFailed) return null;
    return AuthValidators.address(_addressText.text);
  }

  String get _fullAddress {
    final details = _details.text.trim();
    final base = _addressText.text.trim();
    return details.isEmpty ? base : '$details, $base';
  }

  bool get _addressChanged {
    final a = _address;
    if (a == null) return _addressText.text.trim().isNotEmpty;
    return _picked != null ||
        _details.text.trim().isNotEmpty ||
        _addressText.text.trim() != a.fullAddress.trim();
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _showErrors = true);
    final firstError = _nameError != null
        ? _nameFocus
        : _phoneError != null
        ? _phoneFocus
        : _addressError != null
        ? _addressFocus
        : null;
    if (firstError != null) {
      firstError.requestFocus();
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final fullName = _name.text.trim();
      final phone = _phone.text.replaceAll(RegExp(r'[^\d+]'), '');
      final profile = await widget.repository.updateProfile(
        fullName: fullName,
        phone: phone,
      );
      final repo = widget.checkoutRepository;
      if (repo != null && !_addressLoadFailed && _addressChanged) {
        final picked = _picked?.coordinates;
        final base =
            _address ??
            const CheckoutAddress(
              id: newAddressId,
              label: 'Nhà riêng',
              recipientName: '',
              phone: '',
              addressLine: '',
              ward: '',
              district: '',
              city: '',
              isDefault: true,
            );
        await repo.saveAddress(
          CheckoutAddress(
            id: base.id,
            label: base.label,
            recipientName: fullName,
            phone: phone,
            addressLine: _fullAddress,
            ward: '',
            district: '',
            city: '',
            driverNote: base.driverNote,
            isDefault: base.isDefault,
            // Sửa tay mà không chọn lại ghim thì bỏ toạ độ cũ đã lệch.
            latitude:
                picked?.latitude ??
                (_addressText.text.trim() == base.fullAddress.trim()
                    ? base.latitude
                    : null),
            longitude:
                picked?.longitude ??
                (_addressText.text.trim() == base.fullAddress.trim()
                    ? base.longitude
                    : null),
          ),
        );
      }
      navigator.pop(profile);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(profileErrorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthTheme(
      child: Scaffold(
        backgroundColor: AuthPalette.background,
        appBar: AppBar(
          backgroundColor: AuthPalette.background,
          surfaceTintColor: Colors.transparent,
          title: Text('Thông tin cá nhân', style: AuthTextStyles.headerTitle),
          leading: IconButton(
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _buildForm(),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          margin: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            color: AuthPalette.background,
            border: Border(top: BorderSide(color: AuthPalette.divider)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: AuthPrimaryButton(
                    key: const Key('profile-save'),
                    label: 'Lưu thay đổi',
                    height: 52,
                    radius: 12,
                    color: AuthPalette.forestButton,
                    shadows: const [],
                    isLoading: _saving,
                    onPressed: _saving || _loadingAddress ? null : _save,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final email = widget.profile.email ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          key: 'profile-name',
          label: 'Họ và tên',
          hint: 'Nhập họ và tên người nhận',
          controller: _name,
          focusNode: _nameFocus,
          icon: Icons.person_outline,
          capitalization: TextCapitalization.words,
          error: _nameError,
          onSubmitted: (_) => _phoneFocus.requestFocus(),
        ),
        const SizedBox(height: 16),
        _field(
          key: 'profile-phone',
          label: 'Số điện thoại',
          hint: 'Nhập số điện thoại nhận hàng',
          controller: _phone,
          focusNode: _phoneFocus,
          icon: Icons.phone_outlined,
          keyboard: TextInputType.phone,
          error: _phoneError,
          action: TextInputAction.done,
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: 16),
          _label('Email'),
          const SizedBox(height: 6),
          Semantics(
            label: 'Email, không đổi được',
            child: Container(
              key: const Key('profile-email'),
              constraints: const BoxConstraints(minHeight: 50),
              padding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
              decoration: BoxDecoration(
                color: AuthPalette.surfaceMuted,
                border: Border.all(color: AuthPalette.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.mail_outline,
                    size: 18,
                    color: AuthPalette.sage,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AuthFonts.sans(
                        fontSize: 14,
                        height: 1.5,
                        color: AuthPalette.sage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Tooltip(
                    message: 'Email gắn với tài khoản, không đổi được',
                    child: Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: AuthPalette.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_hasAddressSection) ...[
          const SizedBox(height: 24),
          _buildAddress(),
        ],
      ],
    );
  }

  Widget _buildAddress() {
    final selected =
        _picked != null ||
        (_address?.hasCoordinates ?? false) &&
            _addressText.text.trim() == _address!.fullAddress.trim();
    final busy = _saving || _loadingAddress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('Địa chỉ nhận hàng mặc định'),
        const SizedBox(height: 8),
        if (_addressLoadFailed)
          Container(
            key: const Key('profile-address-load-failed'),
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            decoration: BoxDecoration(
              color: AuthPalette.surface,
              border: Border.all(color: AuthPalette.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Không tải được địa chỉ đã lưu.',
                    style: AuthFonts.sans(
                      fontSize: 13,
                      color: AuthPalette.sage,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _loadAddress,
                  child: Text(
                    'Thử lại',
                    style: AuthFonts.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AuthPalette.forest,
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('profile-map-button'),
                  onPressed: busy
                      ? null
                      : () => _openPicker(useCurrentLocation: false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AuthPalette.forest,
                    backgroundColor: selected
                        ? AuthPalette.sageSoft
                        : AuthPalette.surface,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    side: const BorderSide(color: AuthPalette.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(
                    selected ? 'Đổi vị trí trên bản đồ' : 'Chọn trên bản đồ',
                    style: AuthFonts.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AuthPalette.forest,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AuthPalette.sageSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  key: const Key('profile-location-button'),
                  tooltip: 'Dùng vị trí hiện tại',
                  onPressed: busy
                      ? null
                      : () => _openPicker(useCurrentLocation: true),
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                  icon: const Icon(
                    Icons.my_location_outlined,
                    size: 20,
                    color: AuthPalette.forest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loadingAddress)
            Container(
              key: const Key('profile-address-loading'),
              height: 76,
              decoration: BoxDecoration(
                color: AuthPalette.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
            )
          else
            _field(
              key: 'profile-address',
              hint: 'Số nhà, tên đường, phường/xã, tỉnh/thành',
              semanticLabel: 'Địa chỉ nhận hàng mặc định',
              controller: _addressText,
              focusNode: _addressFocus,
              icon: Icons.location_on_outlined,
              keyboard: TextInputType.multiline,
              capitalization: TextCapitalization.sentences,
              action: TextInputAction.newline,
              minLines: 2,
              maxLines: 4,
              readOnly: selected,
              fillColor: selected ? AuthPalette.surfaceMuted : null,
              onTap: selected && !busy
                  ? () => _openPicker(useCurrentLocation: false)
                  : null,
              suffix: selected
                  ? const Icon(
                      Icons.edit_location_alt_outlined,
                      size: 18,
                      color: AuthPalette.forest,
                    )
                  : null,
              error: _addressError,
            ),
          if (selected && !_loadingAddress)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: AuthPalette.forest,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Đã chọn vị trí trên bản đồ',
                      style: AuthFonts.sans(
                        fontSize: 11,
                        color: AuthPalette.forest,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const Key('profile-manual-address'),
                    onPressed: busy ? null : _useManualAddress,
                    child: Text(
                      'Nhập tay',
                      style: AuthFonts.sans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AuthPalette.forest,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_showDetails) ...[
            const SizedBox(height: 16),
            _field(
              key: 'profile-address-details',
              label: 'Tầng, căn hộ (không bắt buộc)',
              hint: 'Tầng, căn hộ, tên tòa nhà',
              controller: _details,
              icon: Icons.apartment_outlined,
              action: TextInputAction.done,
            ),
          ] else if (!_loadingAddress) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('profile-expand-details'),
                onPressed: busy
                    ? null
                    : () => setState(() => _showDetails = true),
                style: TextButton.styleFrom(
                  foregroundColor: AuthPalette.forest,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 44),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Thêm tầng/căn hộ',
                  style: AuthFonts.sans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AuthPalette.forest,
                  ),
                ),
              ),
            ),
          ],
        ],
        if (widget.onOpenAddressBook != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('profile-open-address-book'),
              onPressed: _saving ? null : _openAddressBook,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 44),
              ),
              child: Text(
                'Quản lý tất cả trong Sổ địa chỉ ›',
                style: AuthFonts.sans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AuthPalette.forest,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _label(String text) => Text(
    text,
    style: AuthFonts.sans(fontSize: 13, fontWeight: FontWeight.w600),
  );

  Widget _field({
    required String key,
    String? label,
    String? semanticLabel,
    required String hint,
    required TextEditingController controller,
    FocusNode? focusNode,
    IconData? icon,
    TextInputType? keyboard,
    TextCapitalization capitalization = TextCapitalization.none,
    TextInputAction action = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
    int minLines = 1,
    int maxLines = 1,
    bool readOnly = false,
    Color? fillColor,
    VoidCallback? onTap,
    Widget? suffix,
    String? error,
  }) {
    final multiline = maxLines > 1;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: error == null ? AuthPalette.border : AuthPalette.error,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[_label(label), const SizedBox(height: 6)],
        Stack(
          children: [
            Semantics(
              label: semanticLabel ?? label,
              child: TextField(
                key: Key(key),
                controller: controller,
                focusNode: focusNode,
                enabled: !_saving,
                readOnly: readOnly,
                onTap: onTap,
                keyboardType: keyboard,
                textCapitalization: capitalization,
                textInputAction: action,
                onSubmitted: onSubmitted,
                minLines: minLines,
                maxLines: maxLines,
                style: AuthFonts.sans(
                  fontSize: 14,
                  height: 1.5,
                  color: readOnly && onTap == null
                      ? AuthPalette.sage
                      : AuthPalette.ink,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AuthFonts.sans(
                    fontSize: 13,
                    height: 1.5,
                    color: AuthPalette.muted,
                  ),
                  filled: true,
                  fillColor: fillColor ?? AuthPalette.surface,
                  // Ô nhiều dòng: icon vẽ riêng ở dòng đầu (prefixIcon luôn bị
                  // canh giữa theo chiều cao ô).
                  contentPadding: multiline && icon != null
                      ? const EdgeInsets.fromLTRB(46, 14, 14, 14)
                      : const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                  prefixIcon: icon == null || multiline
                      ? null
                      : Icon(icon, size: 18, color: AuthPalette.sage),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 42,
                    minHeight: 48,
                  ),
                  suffixIcon: suffix,
                  enabledBorder: border,
                  disabledBorder: border,
                  focusedBorder: border.copyWith(
                    borderSide: BorderSide(
                      color: error == null
                          ? AuthPalette.forest
                          : AuthPalette.error,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            if (multiline && icon != null)
              Positioned(
                left: 12,
                top: 15,
                child: IgnorePointer(
                  child: Icon(icon, size: 18, color: AuthPalette.sage),
                ),
              ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Semantics(
              liveRegion: true,
              child: AuthFieldError(key: Key('$key-error'), message: error),
            ),
          ),
      ],
    );
  }
}
