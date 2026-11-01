import 'package:flutter/material.dart';

import '../../auth/data/auth_failure.dart';
import '../../auth/data/auth_scope.dart';
import '../../auth/utils/auth_validators.dart';
import '../../checkout/utils/checkout_theme.dart';
import '../../checkout/widgets/checkout_common.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final auth = AuthScope.of(context);
    setState(() => _saving = true);
    try {
      await auth.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      messenger.showSnackBar(const SnackBar(content: Text('Đã đổi mật khẩu.')));
      navigator.pop();
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CheckoutTheme(
      child: Scaffold(
        appBar: const FleureAppBar(title: 'Đổi mật khẩu', showProfile: false),
        body: Form(
          key: _formKey,
          child: CheckoutContent(
            children: <Widget>[
              _PasswordField(
                label: 'Mật khẩu hiện tại',
                controller: _currentController,
                validator: (value) => AuthValidators.loginPassword(value ?? ''),
              ),
              const SizedBox(height: 14),
              _PasswordField(
                label: 'Mật khẩu mới',
                controller: _newController,
                validator: (value) => AuthValidators.password(value ?? ''),
              ),
              const SizedBox(height: 14),
              _PasswordField(
                label: 'Nhập lại mật khẩu mới',
                controller: _confirmController,
                validator: (value) => AuthValidators.confirmPassword(
                  value ?? '',
                  _newController.text,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                key: const Key('password-save'),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Đang lưu...' : 'Đổi mật khẩu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.validator,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      validator: validator,
      decoration: InputDecoration(labelText: label),
    );
  }
}
