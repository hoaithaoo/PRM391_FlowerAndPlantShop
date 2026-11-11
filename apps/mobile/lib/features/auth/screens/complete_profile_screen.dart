import 'package:flutter/material.dart';

import '../../../core/location/current_address_service.dart';
import '../../../core/location/delivery_location.dart';
import '../auth_routes.dart';
import '../data/auth_scope.dart';
import '../state/complete_profile_controller.dart';
import '../state/complete_profile_state.dart';
import '../utils/auth_theme.dart';
import '../widgets/auth_common.dart';
import '../widgets/register_widgets.dart';
import 'delivery_location_picker_screen.dart';

/// Hoàn thiện người nhận và địa chỉ giao hàng sau khi liên kết Google.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({
    super.key,
    this.currentAddressService = const CurrentAddressService(),
  });

  final CurrentAddressService currentAddressService;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  late final CompleteProfileController _controller;
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _agreementFocus = FocusNode();
  bool _showAddressDetails = false;

  @override
  void initState() {
    super.initState();
    _controller = CompleteProfileController(
      repository: AuthScope.of(context),
      currentAddressService: widget.currentAddressService,
    );
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _agreementFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    final result = await _controller.submit();
    if (!mounted) return;
    switch (result.outcome) {
      case CompleteProfileOutcome.success:
        AuthRoutes.completeAuth(context);
      case CompleteProfileOutcome.failed:
        showAuthError(context, result.message ?? 'Đã có lỗi xảy ra.');
      case CompleteProfileOutcome.invalid:
        final errors = _controller.state.errors;
        final focus = errors.fullName != null
            ? _nameFocus
            : errors.phone != null
                ? _phoneFocus
                : errors.address != null
                    ? _addressFocus
                    : _agreementFocus;
        focus.requestFocus();
        final target = focus.context;
        if (target != null && target.mounted) {
          Scrollable.ensureVisible(target);
        }
      case CompleteProfileOutcome.busy:
        break;
    }
  }

  void _showTermsPlaceholder() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Đang cập nhật')));
  }

  Future<void> _openLocationPicker({required bool useCurrentLocation}) async {
    if (_controller.state.isBusy) return;
    FocusScope.of(context).unfocus();
    final result = await Navigator.of(context).push<DeliveryLocation>(
      MaterialPageRoute(
        builder: (_) => AuthTheme(
          child: DeliveryLocationPickerScreen(
            service: widget.currentAddressService,
            initialLocation: _controller.state.selectedLocation,
            useCurrentLocation: useCurrentLocation,
          ),
        ),
      ),
    );
    if (mounted && result != null) _controller.selectDeliveryLocation(result);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;
        return Scaffold(
          backgroundColor: AuthPalette.background,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _buildContent(state),
                ),
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
                      key: const Key('complete_profile_submit_button'),
                      label: 'Lưu và tiếp tục',
                      height: 52,
                      radius: 12,
                      color: AuthPalette.forestButton,
                      shadows: const [],
                      trailingIcon: Icons.arrow_forward,
                      isLoading: state.isSubmitting,
                      onPressed: state.isBusy ? null : _onSubmit,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(CompleteProfileState state) {
    final errors = state.errors;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Nhà Có Hoa', style: AuthTextStyles.brandLogo),
              ),
              TextButton(
                key: const Key('complete_profile_sign_out_button'),
                onPressed: state.isBusy ? null : _controller.signOut,
                child: Text(
                  'Đăng xuất',
                  style: AuthFonts.sans(fontSize: 12, color: AuthPalette.sage),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(
              'Hoàn thiện thông tin',
              style: AuthFonts.serif(fontSize: 30, height: 1.15),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tên, số điện thoại và địa chỉ để giao hoa đến bạn.',
            style: AuthFonts.sans(
              fontSize: 13,
              color: AuthPalette.sage,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          _buildLinkedAccount(state),
          const SizedBox(height: 22),
          _input(
            id: 'complete_profile_fullname_field',
            label: 'Họ và tên',
            hint: 'Nhập họ và tên người nhận',
            controller: _controller.fullNameController,
            focusNode: _nameFocus,
            icon: Icons.person_outline,
            autofillHints: const [AutofillHints.name],
            capitalization: TextCapitalization.words,
            error: state.showErrors ? errors.fullName : null,
            errorKey: 'complete_profile_fullname_error',
            onSubmitted: (_) => _phoneFocus.requestFocus(),
          ),
          const SizedBox(height: 16),
          _input(
            id: 'complete_profile_phone_field',
            label: 'Số điện thoại',
            hint: 'Nhập số điện thoại nhận hàng',
            controller: _controller.phoneController,
            focusNode: _phoneFocus,
            icon: Icons.phone_outlined,
            keyboard: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            error: state.showErrors ? errors.phone : null,
            errorKey: 'complete_profile_phone_error',
            onSubmitted: (_) {
              if (state.selectedLocation == null) {
                _addressFocus.requestFocus();
              } else {
                FocusScope.of(context).unfocus();
              }
            },
          ),
          const SizedBox(height: 22),
          _buildAddress(state),
          if (_showAddressDetails || state.addressDetails.isNotEmpty) ...[
            const SizedBox(height: 16),
            _input(
              id: 'complete_profile_address_details_field',
              label: 'Tầng, căn hộ (không bắt buộc)',
              hint: 'Tầng, căn hộ, tên tòa nhà',
              controller: _controller.addressDetailsController,
              icon: Icons.apartment_outlined,
              action: TextInputAction.done,
            ),
            const SizedBox(height: 20),
          ] else ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('complete_profile_expand_details'),
                onPressed: state.isSubmitting
                    ? null
                    : () => setState(() => _showAddressDetails = true),
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
            const SizedBox(height: 12),
          ],
          Focus(
            focusNode: _agreementFocus,
            child: KeyedSubtree(
              key: const Key('complete_profile_agreement_checkbox'),
              child: RegisterAgreementRow(
                checked: state.agreed,
                errorLayout: true,
                onToggle:
                    state.isSubmitting ? () {} : _controller.toggleAgreement,
                onOpenLink: _showTermsPlaceholder,
                errorMessage: state.showErrors ? errors.agreement : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedAccount(CompleteProfileState state) {
    return Row(
      children: [
        const GoogleLogo(size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tài khoản Google đã liên kết',
                style: AuthFonts.sans(
                  fontSize: 11,
                  color: AuthPalette.sage,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                state.email.isEmpty ? 'Chưa có email' : state.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AuthFonts.sans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.check_circle_outline,
          size: 16,
          color: AuthPalette.sage,
        ),
      ],
    );
  }

  Widget _buildAddress(CompleteProfileState state) {
    final error = state.showErrors ? state.errors.address : null;
    final selected = state.selectedLocation != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('Địa chỉ nhận hàng'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('complete_profile_map_button'),
                onPressed: state.isBusy
                    ? null
                    : () => _openLocationPicker(useCurrentLocation: false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AuthPalette.forest,
                  backgroundColor:
                      selected ? AuthPalette.sageSoft : AuthPalette.surface,
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
                  textAlign: TextAlign.center,
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
                key: const Key('complete_profile_location_button'),
                tooltip: 'Dùng vị trí hiện tại',
                onPressed: state.isBusy
                    ? null
                    : () => _openLocationPicker(useCurrentLocation: true),
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
        _input(
          id: 'complete_profile_address_field',
          hint: 'Số nhà, tên đường, phường/xã, tỉnh/thành',
          controller: _controller.addressController,
          focusNode: _addressFocus,
          icon: Icons.location_on_outlined,
          keyboard: TextInputType.multiline,
          capitalization: TextCapitalization.sentences,
          action: TextInputAction.newline,
          autofillHints: const [AutofillHints.fullStreetAddress],
          minLines: 2,
          maxLines: 4,
          readOnly: selected,
          // Đã ghim trên bản đồ: ô khoá, nền nhạt; chạm để chỉnh lại ghim.
          fillColor: selected ? AuthPalette.surfaceMuted : null,
          onTap: selected && !state.isBusy
              ? () => _openLocationPicker(useCurrentLocation: false)
              : null,
          semanticLabel: 'Địa chỉ nhận hàng',
          error: error,
          errorKey: 'complete_profile_address_error',
        ),
        if (selected)
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
                  key: const Key('complete_profile_manual_address'),
                  onPressed: state.isBusy ? null : _controller.useManualAddress,
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
      ],
    );
  }

  Widget _input({
    required String id,
    String? label,
    String? semanticLabel,
    required String hint,
    required TextEditingController controller,
    FocusNode? focusNode,
    IconData? icon,
    TextInputType? keyboard,
    Iterable<String>? autofillHints,
    TextCapitalization capitalization = TextCapitalization.none,
    TextInputAction action = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
    int minLines = 1,
    int maxLines = 1,
    bool readOnly = false,
    Color? fillColor,
    VoidCallback? onTap,
    String? error,
    String? errorKey,
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
        Stack(children: [
        Semantics(
          label: semanticLabel ?? label,
          child: TextField(
            key: Key(id),
            controller: controller,
            focusNode: focusNode,
            enabled: !_controller.state.isSubmitting,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboard,
            autofillHints: autofillHints,
            textCapitalization: capitalization,
            textInputAction: action,
            onSubmitted: onSubmitted,
            minLines: minLines,
            maxLines: maxLines,
            style: AuthFonts.sans(fontSize: 14, height: 1.5),
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
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              prefixIcon: icon == null || multiline
                  ? null
                  : Icon(icon, size: 18, color: AuthPalette.sage),
              suffixIcon: readOnly
                  ? const Icon(
                      Icons.edit_location_alt_outlined,
                      size: 18,
                      color: AuthPalette.forest,
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 42,
                minHeight: 48,
              ),
              enabledBorder: border,
              disabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(
                  color: error == null ? AuthPalette.forest : AuthPalette.error,
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
        ]),
        if (error != null) _fieldError(errorKey!, error),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AuthFonts.sans(fontSize: 13, fontWeight: FontWeight.w600),
      );

  Widget _fieldError(String key, String message) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Semantics(
          liveRegion: true,
          child: AuthFieldError(key: Key(key), message: message),
        ),
      );
}
