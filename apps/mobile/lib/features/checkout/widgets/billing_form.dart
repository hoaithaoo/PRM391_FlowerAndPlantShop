import 'package:flutter/material.dart';

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
        Text(
          'Delivery information',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: receiverNameController,
          enabled: enabled,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          autofillHints: const <String>[AutofillHints.name],
          decoration: const InputDecoration(
            labelText: 'Receiver name',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          validator: _requiredTextValidator,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: phoneController,
          enabled: enabled,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.phone,
          autofillHints: const <String>[AutofillHints.telephoneNumber],
          decoration: const InputDecoration(
            labelText: 'Phone number',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
          validator: _phoneValidator,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: addressController,
          enabled: enabled,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.sentences,
          autofillHints: const <String>[AutofillHints.fullStreetAddress],
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Delivery address',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
          ),
          validator: _requiredTextValidator,
        ),
        const SizedBox(height: 12),
        // TODO: Tích hợp chọn vị trí bản đồ sau khi module location được merge
        LayoutBuilder(
          builder: (context, constraints) {
            final useSingleColumn = constraints.maxWidth < 360;
            final latitudeField = _CoordinateField(
              controller: latitudeController,
              label: 'Latitude',
              enabled: enabled,
              min: -90,
              max: 90,
              textInputAction: TextInputAction.next,
            );
            final longitudeField = _CoordinateField(
              controller: longitudeController,
              label: 'Longitude',
              enabled: enabled,
              min: -180,
              max: 180,
              textInputAction: TextInputAction.next,
            );

            if (useSingleColumn) {
              return Column(
                children: <Widget>[
                  latitudeField,
                  const SizedBox(height: 12),
                  longitudeField,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: latitudeField),
                const SizedBox(width: 12),
                Expanded(child: longitudeField),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: noteController,
          enabled: enabled,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Delivery note (optional)',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.notes_outlined),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  static String? _requiredTextValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  static String? _phoneValidator(String? value) {
    final normalizedValue = value?.trim() ?? '';
    if (normalizedValue.isEmpty) {
      return 'Phone number is required.';
    }
    if (!RegExp(r'^\+?[0-9][0-9 .-]{7,14}$').hasMatch(normalizedValue)) {
      return 'Enter a valid phone number.';
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
      textInputAction: textInputAction,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final normalizedValue = value?.trim() ?? '';
        if (normalizedValue.isEmpty) {
          return 'Required.';
        }
        final coordinate = double.tryParse(normalizedValue);
        if (coordinate == null) {
          return 'Enter a number.';
        }
        if (coordinate < min || coordinate > max) {
          return '$min to $max only.';
        }
        return null;
      },
    );
  }
}
