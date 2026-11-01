import 'package:flutter/material.dart';

import '../../checkout/utils/checkout_theme.dart';
import '../../checkout/utils/checkout_validators.dart';
import '../../checkout/widgets/checkout_common.dart';
import '../data/profile_repository.dart';
import '../models/profile_models.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.repository,
    required this.profile,
  });

  final ProfileRepository repository;
  final UserProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.profile.fullName,
  );
  late final _phoneController = TextEditingController(
    text: widget.profile.phone,
  );
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final profile = await widget.repository.updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      navigator.pop(profile);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text(profileErrorMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CheckoutTheme(
      child: Scaffold(
        appBar: const FleureAppBar(
          title: 'Thông tin cá nhân',
          showProfile: false,
        ),
        body: Form(
          key: _formKey,
          child: CheckoutContent(
            children: <Widget>[
              LabeledCheckoutField(
                key: const Key('profile-name'),
                label: 'Họ và tên',
                controller: _nameController,
                validator: CheckoutValidators.recipientName,
              ),
              const SizedBox(height: 14),
              LabeledCheckoutField(
                key: const Key('profile-phone'),
                label: 'Số điện thoại',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: CheckoutValidators.vietnamesePhone,
              ),
              const SizedBox(height: 22),
              FilledButton(
                key: const Key('profile-save'),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Đang lưu...' : 'Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
