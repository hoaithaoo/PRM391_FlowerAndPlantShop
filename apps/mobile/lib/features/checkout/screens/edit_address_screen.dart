import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/checkout_flow_models.dart';
import '../utils/checkout_theme.dart';
import '../utils/checkout_validators.dart';
import '../widgets/checkout_common.dart';

class EditAddressScreen extends StatefulWidget {
  const EditAddressScreen({
    super.key,
    required this.address,
    this.isCreating = false,
  });

  final CheckoutAddress address;
  final bool isCreating;

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  static const _locationOptions = <String, Map<String, List<String>>>{
    'TP. Hồ Chí Minh': <String, List<String>>{
      'Quận 1': <String>['Phường Bến Nghé', 'Phường Bến Thành'],
      'Quận 3': <String>['Phường 2', 'Phường Võ Thị Sáu'],
      'TP. Thủ Đức': <String>['Phường An Khánh', 'Phường Thảo Điền'],
    },
    'Hà Nội': <String, List<String>>{
      'Quận Hoàn Kiếm': <String>['Phường Hàng Bạc', 'Phường Tràng Tiền'],
      'Quận Ba Đình': <String>['Phường Ngọc Hà', 'Phường Quán Thánh'],
    },
  };

  final _formKey = GlobalKey<FormState>();
  final _nameAnchorKey = GlobalKey();
  final _phoneAnchorKey = GlobalKey();
  final _provinceAnchorKey = GlobalKey();
  final _districtAnchorKey = GlobalKey();
  final _wardAnchorKey = GlobalKey();
  final _addressAnchorKey = GlobalKey();
  final _districtFieldKey = GlobalKey<FormFieldState<String>>();
  final _wardFieldKey = GlobalKey<FormFieldState<String>>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _driverNoteController;
  late String? _city;
  late String? _district;
  late String? _ward;
  late String _label;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address.recipientName);
    _phoneController = TextEditingController(
      text: widget.address.phone.replaceAll(RegExp(r'\D'), ''),
    );
    _city = _locationOptions.containsKey(widget.address.city)
        ? widget.address.city
        : null;
    _district =
        _locationOptions[_city]?.containsKey(widget.address.district) == true
        ? widget.address.district
        : null;
    _ward =
        _locationOptions[_city]?[_district]?.contains(widget.address.ward) ==
            true
        ? widget.address.ward
        : null;
    _addressController = TextEditingController(
      text: widget.address.addressLine,
    );
    _driverNoteController = TextEditingController(
      text: widget.address.driverNote,
    );
    _label = widget.address.label;
    _isDefault = widget.address.isDefault;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _driverNoteController.dispose();
    super.dispose();
  }

  void _changeProvince(String? value) {
    setState(() {
      _city = value;
      _district = null;
      _ward = null;
    });
    _districtFieldKey.currentState?.didChange(null);
    _wardFieldKey.currentState?.didChange(null);
    _districtFieldKey.currentState?.validate();
    _wardFieldKey.currentState?.validate();
  }

  void _changeDistrict(String? value) {
    setState(() {
      _district = value;
      _ward = null;
    });
    _wardFieldKey.currentState?.didChange(null);
    _wardFieldKey.currentState?.validate();
  }

  void _save() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _revealFirstInvalid(),
      );
      return;
    }

    final draft = CheckoutAddress(
      id: widget.address.id,
      label: _label,
      recipientName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      addressLine: _addressController.text.trim(),
      ward: _ward!,
      district: _district!,
      city: _city!,
      driverNote: CheckoutValidators.normalizeOptionalText(
        _driverNoteController.text,
      ),
      isDefault: _isDefault,
    );
    // Đổi địa chỉ thì bỏ tọa độ cũ để server tra lại từ địa chỉ mới.
    final sameAddress = draft.fullAddress == widget.address.fullAddress;
    Navigator.of(context).pop(
      sameAddress
          ? draft.copyWith(
              latitude: widget.address.latitude,
              longitude: widget.address.longitude,
            )
          : draft,
    );
  }

  void _revealFirstInvalid() {
    final checks = <(String?, GlobalKey)>[
      (CheckoutValidators.recipientName(_nameController.text), _nameAnchorKey),
      (
        CheckoutValidators.vietnamesePhone(_phoneController.text),
        _phoneAnchorKey,
      ),
      (CheckoutValidators.province(_city), _provinceAnchorKey),
      (CheckoutValidators.district(_district), _districtAnchorKey),
      (CheckoutValidators.ward(_ward), _wardAnchorKey),
      (
        CheckoutValidators.detailedAddress(_addressController.text),
        _addressAnchorKey,
      ),
    ];
    for (final check in checks) {
      final fieldContext = check.$2.currentContext;
      if (check.$1 == null || fieldContext == null) continue;
      Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 280),
        alignment: 0.16,
      );
      break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CheckoutTheme(
      child: Scaffold(
        appBar: FleureAppBar(
          title: widget.isCreating ? 'Thêm địa chỉ' : 'Chỉnh sửa địa chỉ',
          showProfile: false,
        ),
        body: Form(
          key: _formKey,
          child: CheckoutContent(
            children: <Widget>[
              const CheckoutStatusBadge(text: 'DỊCH VỤ GIAO HOA TẬN NƠI'),
              const SizedBox(height: 12),
              Text(
                widget.isCreating ? 'Địa chỉ mới' : 'Chỉnh sửa nơi nhận hoa',
                style: CheckoutTypography.heading,
              ),
              const SizedBox(height: 6),
              const Text(
                'Thông tin chính xác giúp nghệ nhân và tài xế trao hoa đúng người, đúng thời điểm.',
                style: TextStyle(
                  color: CheckoutPalette.charcoal500,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              const CheckoutInfoBanner(
                icon: Icons.location_on_outlined,
                title: 'Vị trí giao hoa',
                message:
                    'Vị trí được xác định tự động từ địa chỉ để tính phí giao hàng.',
              ),
              const SizedBox(height: 22),
              LabeledCheckoutField(
                key: _nameAnchorKey,
                label: 'Họ và tên người nhận *',
                controller: _nameController,
                hint: 'Nhập tên người nhận',
                prefixIcon: Icons.person_outline_rounded,
                validator: CheckoutValidators.recipientName,
              ),
              const SizedBox(height: 14),
              LabeledCheckoutField(
                key: _phoneAnchorKey,
                label: 'Số điện thoại *',
                controller: _phoneController,
                hint: 'Ví dụ: 0901234567',
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                prefixIcon: Icons.phone_outlined,
                validator: CheckoutValidators.vietnamesePhone,
              ),
              const SizedBox(height: 14),
              LabeledCheckoutDropdown<String>(
                key: _provinceAnchorKey,
                label: 'Tỉnh / Thành phố *',
                value: _city,
                items: _locationOptions.keys.toList(),
                hint: 'Chọn Tỉnh/Thành phố',
                prefixIcon: Icons.location_city_outlined,
                onChanged: _changeProvince,
                validator: CheckoutValidators.province,
              ),
              const SizedBox(height: 14),
              LabeledCheckoutDropdown<String>(
                key: _districtAnchorKey,
                fieldKey: _districtFieldKey,
                label: 'Quận / Huyện *',
                value: _district,
                items:
                    _locationOptions[_city]?.keys.toList() ?? const <String>[],
                hint: 'Chọn Quận/Huyện',
                prefixIcon: Icons.map_outlined,
                onChanged: _city == null ? null : _changeDistrict,
                validator: CheckoutValidators.district,
              ),
              const SizedBox(height: 14),
              LabeledCheckoutDropdown<String>(
                key: _wardAnchorKey,
                fieldKey: _wardFieldKey,
                label: 'Phường / Xã *',
                value: _ward,
                items: _locationOptions[_city]?[_district] ?? const <String>[],
                hint: 'Chọn Phường/Xã',
                prefixIcon: Icons.place_outlined,
                onChanged: _district == null
                    ? null
                    : (value) => setState(() => _ward = value),
                validator: CheckoutValidators.ward,
              ),
              const SizedBox(height: 14),
              LabeledCheckoutField(
                key: _addressAnchorKey,
                label: 'Địa chỉ cụ thể *',
                controller: _addressController,
                hint: 'Số nhà, tên đường, tòa nhà',
                prefixIcon: Icons.location_on_outlined,
                validator: CheckoutValidators.detailedAddress,
              ),
              const SizedBox(height: 14),
              LabeledCheckoutField(
                label: 'Chỉ dẫn cho tài xế',
                controller: _driverNoteController,
                hint: 'Ví dụ: gọi trước khi đến, giao tại sảnh...',
                maxLines: 3,
                maxLength: 180,
                showCounter: true,
                validator: (value) =>
                    CheckoutValidators.limitedNote(value, maxLength: 180),
              ),
              const SizedBox(height: 18),
              const Text(
                'Gắn nhãn địa chỉ',
                style: TextStyle(
                  color: CheckoutPalette.charcoal700,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                children: <String>['Nhà riêng', 'Văn phòng', 'Khác']
                    .map(
                      (label) => ChoiceChip(
                        label: Text(label),
                        selected: _label == label,
                        onSelected: (_) => setState(() => _label = label),
                        selectedColor: CheckoutPalette.forest100,
                        side: const BorderSide(color: CheckoutPalette.cream300),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              CheckoutSurfaceCard(
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isDefault,
                  onChanged: (value) => setState(() => _isDefault = value),
                  activeThumbColor: CheckoutPalette.forest800,
                  title: const Text(
                    'Đặt làm địa chỉ mặc định',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Tự động chọn địa chỉ này cho lần đặt hoa tiếp theo.',
                    style: TextStyle(fontSize: 10.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const CheckoutInfoBanner(
                icon: Icons.verified_user_outlined,
                title: 'Tiêu chuẩn bảo mật Fleuré',
                message:
                    'Thông tin người nhận chỉ được dùng để hoàn tất đơn hoa và không hiển thị công khai.',
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  widget.isCreating ? 'Thêm địa chỉ' : 'Lưu thay đổi',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
