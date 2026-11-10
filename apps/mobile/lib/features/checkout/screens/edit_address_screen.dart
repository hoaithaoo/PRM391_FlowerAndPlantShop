import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/location/location_service.dart';
import '../data/vietnam_administrative_service.dart';
import '../models/checkout_flow_models.dart';
import '../utils/checkout_theme.dart';
import '../utils/checkout_validators.dart';
import '../widgets/checkout_common.dart';

class EditAddressScreen extends StatefulWidget {
  const EditAddressScreen({
    super.key,
    required this.address,
    this.isCreating = false,
    this.locationService = const LocationService(),
    this.administrativeService,
  });

  final CheckoutAddress address;
  final bool isCreating;
  final LocationService locationService;
  final VietnamAdministrativeService? administrativeService;

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
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
  late final VietnamAdministrativeService _administrativeService;
  late final bool _ownsAdministrativeService;
  List<AdministrativeUnit> _provinces = const <AdministrativeUnit>[];
  List<AdministrativeUnit> _districts = const <AdministrativeUnit>[];
  List<AdministrativeUnit> _wards = const <AdministrativeUnit>[];
  late String? _city;
  late String? _district;
  late String? _ward;
  int? _provinceCode;
  int? _districtCode;
  late String _label;
  late bool _isDefault;
  late double? _latitude;
  late double? _longitude;
  bool _locating = false;
  bool _loadingProvinces = true;
  bool _loadingDistricts = false;
  bool _loadingWards = false;
  String? _administrativeError;
  Future<void> Function()? _administrativeRetry;
  int _districtRequest = 0;
  int _wardRequest = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address.recipientName);
    _phoneController = TextEditingController(
      text: widget.address.phone.replaceAll(RegExp(r'\D'), ''),
    );
    _city = _nonEmpty(widget.address.city);
    _district = _nonEmpty(widget.address.district);
    _ward = _nonEmpty(widget.address.ward);
    _addressController = TextEditingController(
      text: widget.address.addressLine,
    );
    _driverNoteController = TextEditingController(
      text: widget.address.driverNote,
    );
    _label = widget.address.label;
    _isDefault = widget.address.isDefault;
    _latitude = widget.address.latitude;
    _longitude = widget.address.longitude;
    _ownsAdministrativeService = widget.administrativeService == null;
    _administrativeService =
        widget.administrativeService ?? VietnamAdministrativeService();
    _loadInitialAdministrativeData();
  }

  String? _nonEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _loadInitialAdministrativeData() async {
    final preferredCity = _city;
    final preferredDistrict = _district;
    final preferredWard = _ward;
    setState(() {
      _loadingProvinces = true;
      _administrativeError = null;
      _administrativeRetry = null;
    });
    try {
      final provinces = await _administrativeService.listProvinces();
      if (!mounted) return;
      final selectedProvince = _findMatchingUnit(provinces, preferredCity);
      setState(() {
        _provinces = provinces;
        _loadingProvinces = false;
        _city = selectedProvince == null
            ? preferredCity
            : preferredCity ?? selectedProvince.name;
        _provinceCode = selectedProvince?.code;
      });
      if (selectedProvince != null) {
        await _loadDistricts(
          selectedProvince.code,
          preferredDistrict: preferredDistrict,
          preferredWard: preferredWard,
        );
      }
    } on AdministrativeLocationException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingProvinces = false;
        _administrativeError = error.message;
        _administrativeRetry = _loadInitialAdministrativeData;
      });
    }
  }

  Future<void> _loadDistricts(
    int provinceCode, {
    String? preferredDistrict,
    String? preferredWard,
  }) async {
    final request = ++_districtRequest;
    setState(() {
      _loadingDistricts = true;
      _administrativeError = null;
      _administrativeRetry = null;
    });
    try {
      final districts = await _administrativeService.listDistricts(
        provinceCode,
      );
      if (!mounted ||
          request != _districtRequest ||
          _provinceCode != provinceCode) {
        return;
      }
      final selectedDistrict = _findMatchingUnit(districts, preferredDistrict);
      setState(() {
        _districts = districts;
        _loadingDistricts = false;
        _district = selectedDistrict == null
            ? null
            : preferredDistrict ?? selectedDistrict.name;
        _districtCode = selectedDistrict?.code;
        if (selectedDistrict == null) _ward = null;
      });
      if (selectedDistrict != null) {
        await _loadWards(selectedDistrict.code, preferredWard: preferredWard);
      }
    } on AdministrativeLocationException catch (error) {
      if (!mounted || request != _districtRequest) return;
      setState(() {
        _loadingDistricts = false;
        _administrativeError = error.message;
        _administrativeRetry = () => _loadDistricts(
          provinceCode,
          preferredDistrict: preferredDistrict,
          preferredWard: preferredWard,
        );
      });
    }
  }

  Future<void> _loadWards(int districtCode, {String? preferredWard}) async {
    final request = ++_wardRequest;
    setState(() {
      _loadingWards = true;
      _administrativeError = null;
      _administrativeRetry = null;
    });
    try {
      final wards = await _administrativeService.listWards(districtCode);
      if (!mounted ||
          request != _wardRequest ||
          _districtCode != districtCode) {
        return;
      }
      final selectedWard = _findMatchingUnit(wards, preferredWard);
      setState(() {
        _wards = wards;
        _loadingWards = false;
        _ward = selectedWard == null
            ? null
            : preferredWard ?? selectedWard.name;
      });
    } on AdministrativeLocationException catch (error) {
      if (!mounted || request != _wardRequest) return;
      setState(() {
        _loadingWards = false;
        _administrativeError = error.message;
        _administrativeRetry = () =>
            _loadWards(districtCode, preferredWard: preferredWard);
      });
    }
  }

  AdministrativeUnit? _findMatchingUnit(
    List<AdministrativeUnit> units,
    String? name,
  ) {
    if (name == null) return null;
    final normalized = _normalizeAdministrativeName(name);
    for (final unit in units) {
      if (_normalizeAdministrativeName(unit.name) == normalized) return unit;
    }
    return null;
  }

  String _normalizeAdministrativeName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceFirst(
          RegExp(
            r'^(tỉnh|thành phố|tp\.?|quận|huyện|thị xã|phường|xã|thị trấn)\s+',
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  List<String> _unitNames(List<AdministrativeUnit> units, String? selected) {
    final selectedName = selected == null
        ? null
        : _normalizeAdministrativeName(selected);
    final names = units
        .map(
          (unit) =>
              selectedName != null &&
                  _normalizeAdministrativeName(unit.name) == selectedName
              ? selected!
              : unit.name,
        )
        .toList(growable: true);
    if (selected != null && !names.contains(selected)) {
      names.insert(0, selected);
    }
    return names;
  }

  Future<void> _locate() async {
    if (_locating) return;
    setState(() => _locating = true);
    final service = widget.locationService;
    try {
      final coordinates = await service.getCurrentCoordinates();
      if (!mounted) return;
      setState(() {
        _latitude = coordinates.latitude;
        _longitude = coordinates.longitude;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Đã ghi nhận vị trí hiện tại của bạn.')),
        );
    } on LocationException catch (error) {
      if (!mounted) return;
      final canOpenSettings = service.supportsSettings;
      final action = switch (error.failure) {
        LocationFailure.deniedForever when canOpenSettings => SnackBarAction(
          label: 'Mở cài đặt',
          onPressed: service.openAppSettings,
        ),
        LocationFailure.serviceDisabled when canOpenSettings => SnackBarAction(
          label: 'Bật định vị',
          onPressed: service.openLocationSettings,
        ),
        _ => null,
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(error.failure.message), action: action),
        );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _clearLocation() {
    _latitude = null;
    _longitude = null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _driverNoteController.dispose();
    if (_ownsAdministrativeService) _administrativeService.dispose();
    super.dispose();
  }

  void _changeProvince(String? value) {
    final selected = _findMatchingUnit(_provinces, value);
    _districtRequest++;
    _wardRequest++;
    setState(() {
      _city = selected?.name;
      _provinceCode = selected?.code;
      _district = null;
      _districtCode = null;
      _ward = null;
      _districts = const <AdministrativeUnit>[];
      _wards = const <AdministrativeUnit>[];
      _loadingDistricts = false;
      _loadingWards = false;
      _clearLocation();
    });
    _districtFieldKey.currentState?.didChange(null);
    _wardFieldKey.currentState?.didChange(null);
    _districtFieldKey.currentState?.validate();
    _wardFieldKey.currentState?.validate();
    if (selected != null) _loadDistricts(selected.code);
  }

  void _changeDistrict(String? value) {
    final selected = _findMatchingUnit(_districts, value);
    _wardRequest++;
    setState(() {
      _district = selected?.name;
      _districtCode = selected?.code;
      _ward = null;
      _wards = const <AdministrativeUnit>[];
      _loadingWards = false;
      _clearLocation();
    });
    _wardFieldKey.currentState?.didChange(null);
    _wardFieldKey.currentState?.validate();
    if (selected != null) _loadWards(selected.code);
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
      latitude: _latitude,
      longitude: _longitude,
    );
    Navigator.of(context).pop(draft);
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
              CheckoutSurfaceCard(
                key: const Key('checkout-current-location'),
                color: CheckoutPalette.forest50,
                borderColor: CheckoutPalette.forest100,
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.my_location_rounded,
                      color: CheckoutPalette.forest700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _latitude != null && _longitude != null
                                ? 'Đã xác định vị trí giao hoa'
                                : 'Vị trí giao hoa',
                            style: const TextStyle(
                              color: CheckoutPalette.charcoal900,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Địa chỉ chữ vẫn bắt buộc để tài xế giao hoa chính xác.',
                            style: TextStyle(
                              color: CheckoutPalette.charcoal500,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _locating ? null : _locate,
                      icon: _locating
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.gps_fixed_rounded, size: 17),
                      label: Text(
                        _latitude != null && _longitude != null
                            ? 'Cập nhật'
                            : 'Dùng vị trí hiện tại',
                      ),
                    ),
                  ],
                ),
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
              if (_loadingProvinces || _loadingDistricts || _loadingWards) ...[
                const LinearProgressIndicator(
                  key: Key('administrative-location-loading'),
                  minHeight: 2,
                ),
                const SizedBox(height: 10),
              ],
              if (_administrativeError case final error?) ...[
                CheckoutSurfaceCard(
                  key: const Key('administrative-location-error'),
                  color: CheckoutPalette.petal50,
                  borderColor: CheckoutPalette.petal100,
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.cloud_off_outlined,
                        color: CheckoutPalette.petal500,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          error,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _administrativeRetry?.call(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              LabeledCheckoutDropdown<String>(
                key: _provinceAnchorKey,
                label: 'Tỉnh / Thành phố *',
                value: _city,
                items: _unitNames(_provinces, _city),
                hint: _loadingProvinces
                    ? 'Đang tải Tỉnh/Thành phố…'
                    : 'Chọn Tỉnh/Thành phố',
                prefixIcon: Icons.location_city_outlined,
                onChanged: _loadingProvinces || _provinces.isEmpty
                    ? null
                    : _changeProvince,
                validator: CheckoutValidators.province,
              ),
              const SizedBox(height: 14),
              LabeledCheckoutDropdown<String>(
                key: _districtAnchorKey,
                fieldKey: _districtFieldKey,
                label: 'Quận / Huyện *',
                value: _district,
                items: _unitNames(_districts, _district),
                hint: _loadingDistricts
                    ? 'Đang tải Quận/Huyện…'
                    : 'Chọn Quận/Huyện',
                prefixIcon: Icons.map_outlined,
                onChanged:
                    _provinceCode == null ||
                        _loadingDistricts ||
                        _districts.isEmpty
                    ? null
                    : _changeDistrict,
                validator: CheckoutValidators.district,
              ),
              const SizedBox(height: 14),
              LabeledCheckoutDropdown<String>(
                key: _wardAnchorKey,
                fieldKey: _wardFieldKey,
                label: 'Phường / Xã *',
                value: _ward,
                items: _unitNames(_wards, _ward),
                hint: _loadingWards ? 'Đang tải Phường/Xã…' : 'Chọn Phường/Xã',
                prefixIcon: Icons.place_outlined,
                onChanged:
                    _districtCode == null || _loadingWards || _wards.isEmpty
                    ? null
                    : (value) => setState(() {
                        _ward = value;
                        _clearLocation();
                      }),
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
                onChanged: (_) => setState(_clearLocation),
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
                title: 'Tiêu chuẩn bảo mật Nhà Có Hoa',
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
