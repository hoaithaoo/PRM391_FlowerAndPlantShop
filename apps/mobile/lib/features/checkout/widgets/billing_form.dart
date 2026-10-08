import 'package:flutter/material.dart';

import '../utils/checkout_theme.dart';

class BillingForm extends StatelessWidget {
  const BillingForm({
    super.key,
    required this.receiverNameController,
    required this.phoneController,
    required this.addressController,
    required this.latitudeController,
    required this.longitudeController,
    required this.noteController,
    this.enabled = true,
  });

  final TextEditingController receiverNameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final TextEditingController noteController;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextFormField(
          controller: receiverNameController,
          enabled: enabled,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          autofillHints: const <String>[AutofillHints.name],
          decoration: const InputDecoration(
            labelText: 'Họ và tên người nhận',
            hintText: 'Nhập tên người nhận hàng',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) =>
              _requiredTextValidator(value, 'Họ và tên không được để trống.'),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: phoneController,
          enabled: enabled,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.phone,
          autofillHints: const <String>[AutofillHints.telephoneNumber],
          decoration: const InputDecoration(
            labelText: 'Số điện thoại',
            hintText: 'Ví dụ: 090 123 4567',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          validator: _phoneValidator,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: addressController,
          enabled: enabled,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.sentences,
          autofillHints: const <String>[AutofillHints.fullStreetAddress],
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Địa chỉ nhận hàng',
            hintText: 'Số nhà, phường/xã, quận/huyện, tỉnh/thành phố',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          validator: (value) =>
              _requiredTextValidator(value, 'Vui lòng nhập địa chỉ nhận hàng.'),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CheckoutPalette.sage.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.near_me_outlined,
                size: 19,
                color: CheckoutPalette.forest,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Vị trí giao hàng giúp đơn hàng được giao chính xác hơn.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: CheckoutPalette.forest,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // TODO: Tích hợp chọn vị trí trên bản đồ sau khi module Vị trí được merge
        LayoutBuilder(
          builder: (context, constraints) {
            final useSingleColumn = constraints.maxWidth < 360;
            final latitudeField = _CoordinateField(
              controller: latitudeController,
              label: 'Vĩ độ',
              enabled: enabled,
              min: -90,
              max: 90,
              textInputAction: TextInputAction.next,
            );
            final longitudeField = _CoordinateField(
              controller: longitudeController,
              label: 'Kinh độ',
              enabled: enabled,
              min: -180,
              max: 180,
              textInputAction: TextInputAction.next,
            );

            if (useSingleColumn) {
              return Column(
                children: <Widget>[
                  latitudeField,
                  const SizedBox(height: 14),
                  longitudeField,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: latitudeField),
                const SizedBox(width: 14),
                Expanded(child: longitudeField),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: noteController,
          enabled: enabled,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Ghi chú (không bắt buộc)',
            hintText: 'Thời gian giao hàng hoặc chỉ dẫn thêm…',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.notes_outlined),
          ),
        ),
      ],
    );
  }

  static String? _requiredTextValidator(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? _phoneValidator(String? value) {
    final normalizedValue = value?.trim() ?? '';
    if (normalizedValue.isEmpty) {
      return 'Số điện thoại không được để trống.';
    }
    if (!RegExp(r'^\+?[0-9][0-9 .-]{7,14}$').hasMatch(normalizedValue)) {
      return 'Số điện thoại không hợp lệ.';
    }
    return null;
  }
}

class _CoordinateField extends StatelessWidget {
  const _CoordinateField({
    required this.controller,
    required this.label,
    required this.enabled,
    required this.min,
    required this.max,
    required this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final double min;
  final double max;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textInputAction: textInputAction,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          label == 'Vĩ độ'
              ? Icons.swap_vert_circle_outlined
              : Icons.swap_horiz_outlined,
        ),
      ),
      validator: (value) {
        final normalizedValue = value?.trim() ?? '';
        if (normalizedValue.isEmpty) {
          return 'Vui lòng nhập ${label.toLowerCase()}.';
        }
        final coordinate = double.tryParse(normalizedValue);
        if (coordinate == null) {
          return '$label phải là một số.';
        }
        if (coordinate < min || coordinate > max) {
          return label == 'Vĩ độ'
              ? 'Vĩ độ phải nằm trong khoảng -90 đến 90.'
              : 'Kinh độ phải nằm trong khoảng -180 đến 180.';
        }
        return null;
      },
    );
  }
}
