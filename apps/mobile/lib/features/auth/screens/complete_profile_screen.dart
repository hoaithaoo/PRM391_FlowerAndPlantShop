import 'package:flutter/material.dart';

import '../auth_routes.dart';
import '../data/auth_scope.dart';
import '../state/complete_profile_controller.dart';
import '../state/complete_profile_state.dart';
import '../utils/auth_theme.dart';
import '../widgets/auth_common.dart';

/// Màn hình hoàn thiện thông tin còn thiếu sau khi đăng ký / đăng nhập Google.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  late final CompleteProfileController _controller;

  @override
  void initState() {
    super.initState();
    final repository = AuthScope.of(context);
    _controller = CompleteProfileController(repository: repository);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    final result = await _controller.submit();
    if (!mounted) return;

    switch (result.outcome) {
      case CompleteProfileOutcome.success:
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text(
              'Cập nhật thông tin thành công! Chào mừng bạn đến Fleuré.',
            ),
          ),
        );
        AuthRoutes.completeAuth(context);
      case CompleteProfileOutcome.failed:
        showAuthError(context, result.message ?? 'Đã có lỗi xảy ra.');
      case CompleteProfileOutcome.invalid:
      case CompleteProfileOutcome.busy:
        break;
    }
  }

  Future<void> _onSignOut() async {
    await _controller.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthPalette.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final state = _controller.state;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildForm(state),
                  const SizedBox(height: 24),
                  _buildAgreement(state),
                  const SizedBox(height: 24),
                  AuthPrimaryButton(
                    key: const Key('complete_profile_submit_button'),
                    label: 'Hoàn tất thông tin',
                    isLoading: state.isSubmitting,
                    onPressed: state.isSubmitting ? null : _onSubmit,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      key: const Key('complete_profile_sign_out_button'),
                      onPressed: state.isSubmitting ? null : _onSignOut,
                      child: Text(
                        'Đăng xuất',
                        style: AuthFonts.sans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AuthPalette.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AuthPalette.sageSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GoogleLogo(size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'GOOGLE SIGN-IN',
                    style: AuthFonts.sans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AuthPalette.forest,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Hoàn thiện thông tin',
          style: AuthTextStyles.heading1.copyWith(color: AuthPalette.ink),
        ),
        const SizedBox(height: 8),
        Text(
          'Vui lòng cập nhật số điện thoại và địa chỉ giao hàng để hoàn tất đăng ký tài khoản tại Fleuré.',
          style: AuthTextStyles.body,
        ),
      ],
    );
  }

  Widget _buildForm(CompleteProfileState state) {
    final errors = state.errors;
    final showErrors = state.showErrors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email (Read-only từ Google)
        _buildFieldLabel('Email Google đã liên kết'),
        const SizedBox(height: 6),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AuthPalette.border.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AuthPalette.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, size: 20, color: AuthPalette.forest),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.email.isEmpty ? 'Chưa có email' : state.email,
                  style: AuthFonts.sans(
                    fontSize: 15,
                    color: AuthPalette.ink,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.lock_outline, size: 18, color: AuthPalette.muted),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Họ và tên
        _buildFieldLabel('Họ và tên'),
        const SizedBox(height: 6),
        AuthTextField(
          key: const Key('complete_profile_fullname_field'),
          controller: _controller.fullNameController,
          hintText: 'Nhập họ và tên của bạn',
          prefixIcon: Icons.person_outline,
          height: 54,
          radius: 14,
          status: showErrors && errors.fullName != null
              ? AuthFieldStatus.error
              : AuthFieldStatus.normal,
          enabled: !state.isSubmitting,
          textInputAction: TextInputAction.next,
        ),
        if (showErrors && errors.fullName != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: AuthFieldError(
              key: const Key('complete_profile_fullname_error'),
              message: errors.fullName!,
            ),
          ),
        const SizedBox(height: 16),

        // Số điện thoại
        _buildFieldLabel('Số điện thoại'),
        const SizedBox(height: 6),
        AuthTextField(
          key: const Key('complete_profile_phone_field'),
          controller: _controller.phoneController,
          hintText: 'Ví dụ: 0912345678 hoặc (+84) 912345678',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          height: 54,
          radius: 14,
          status: showErrors && errors.phone != null
              ? AuthFieldStatus.error
              : AuthFieldStatus.normal,
          enabled: !state.isSubmitting,
          textInputAction: TextInputAction.next,
        ),
        if (showErrors && errors.phone != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: AuthFieldError(
              key: const Key('complete_profile_phone_error'),
              message: errors.phone!,
            ),
          ),
        const SizedBox(height: 16),

        // Địa chỉ nhận hàng
        _buildFieldLabel('Địa chỉ nhận hàng'),
        const SizedBox(height: 6),
        AuthTextField(
          key: const Key('complete_profile_address_field'),
          controller: _controller.addressController,
          hintText: 'Số nhà, tên đường, phường/xã, quận/huyện, tỉnh/thành...',
          prefixIcon: Icons.location_on_outlined,
          height: 54,
          radius: 14,
          status: showErrors && errors.address != null
              ? AuthFieldStatus.error
              : AuthFieldStatus.normal,
          enabled: !state.isSubmitting,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _onSubmit(),
        ),
        if (showErrors && errors.address != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: AuthFieldError(
              key: const Key('complete_profile_address_error'),
              message: errors.address!,
            ),
          ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AuthFonts.sans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AuthPalette.ink,
      ),
    );
  }

  Widget _buildAgreement(CompleteProfileState state) {
    final showErrors = state.showErrors;
    final error = state.errors.agreement;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              key: const Key('complete_profile_agreement_checkbox'),
              value: state.agreed,
              activeColor: AuthPalette.forest,
              onChanged: state.isSubmitting ? null : (_) => _controller.toggleAgreement(),
            ),
            Expanded(
              child: GestureDetector(
                onTap: state.isSubmitting ? null : _controller.toggleAgreement,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: RichText(
                    text: TextSpan(
                      style: AuthFonts.sans(
                        fontSize: 13,
                        color: AuthPalette.ink,
                        height: 1.4,
                      ),
                      children: const [
                        TextSpan(text: 'Tôi đồng ý với '),
                        TextSpan(
                          text: 'Điều khoản dịch vụ',
                          style: TextStyle(
                            color: AuthPalette.forest,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: ' và '),
                        TextSpan(
                          text: 'Chính sách bảo mật',
                          style: TextStyle(
                            color: AuthPalette.forest,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: ' của Fleuré.'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showErrors && error != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 2),
            child: AuthFieldError(
              key: const Key('complete_profile_agreement_error'),
              message: error,
            ),
          ),
      ],
    );
  }
}

