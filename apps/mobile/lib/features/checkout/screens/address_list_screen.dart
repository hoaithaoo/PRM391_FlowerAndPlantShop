import 'package:flutter/material.dart';

import '../models/checkout_flow_models.dart';
import '../state/checkout_flow_controller.dart';
import '../utils/checkout_assets.dart';
import '../utils/checkout_theme.dart';
import '../utils/checkout_validators.dart';
import '../widgets/checkout_common.dart';
import 'edit_address_screen.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key, required this.controller});

  final CheckoutFlowController controller;

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  late CheckoutAddress? _selectedAddress = widget.controller.selectedAddress;
  bool _selectionTouched = false;

  Future<void> _editAddress(CheckoutAddress address) async {
    final edited = await Navigator.of(context).push<CheckoutAddress>(
      MaterialPageRoute<CheckoutAddress>(
        builder: (_) => EditAddressScreen(address: address),
      ),
    );
    if (edited == null || !mounted) return;
    widget.controller.updateAddress(edited);
    setState(() {
      _selectedAddress = edited;
      _selectionTouched = true;
    });
  }

  Future<void> _addAddress() async {
    final created = await Navigator.of(context).push<CheckoutAddress>(
      MaterialPageRoute<CheckoutAddress>(
        builder: (_) => const EditAddressScreen(
          address: CheckoutAddress(
            id: 'new-address',
            label: 'Nhà riêng',
            recipientName: '',
            phone: '',
            addressLine: '',
            ward: '',
            district: '',
            city: 'TP. Hồ Chí Minh',
          ),
          isCreating: true,
        ),
      ),
    );
    if (created == null || !mounted) return;
    widget.controller.updateAddress(created);
    setState(() {
      _selectedAddress = created;
      _selectionTouched = true;
    });
  }

  void _confirm() {
    final error = CheckoutValidators.selectedAddress(_selectedAddress);
    setState(() => _selectionTouched = true);
    if (error != null || _selectedAddress == null) return;
    widget.controller.selectAddress(_selectedAddress!);
    Navigator.of(context).pop(_selectedAddress);
  }

  @override
  Widget build(BuildContext context) {
    final selectionError = _selectionTouched
        ? CheckoutValidators.selectedAddress(_selectedAddress)
        : null;
    return CheckoutTheme(
      child: Scaffold(
        appBar: const FleureAppBar(
          title: 'Địa chỉ nhận hàng',
          showProfile: false,
        ),
        body: CheckoutContent(
          bottom: 112,
          children: <Widget>[
            const CheckoutInfoBanner(
              icon: Icons.local_florist_outlined,
              title: 'Giao hoa tận tay, trọn vẹn cảm xúc',
              message:
                  'Fleuré sẽ xác nhận người nhận và chăm chút từng chi tiết trước khi giao.',
              color: CheckoutPalette.petal50,
              iconColor: CheckoutPalette.petal500,
            ),
            const SizedBox(height: 24),
            const CheckoutSectionHeader(
              title: 'Sổ địa chỉ của bạn',
              subtitle: 'Chọn nơi Fleuré sẽ mang tác phẩm đến.',
            ),
            const SizedBox(height: 14),
            ...widget.controller.addresses.map(
              (address) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AddressSelectionCard(
                  address: address,
                  selected: address.id == _selectedAddress?.id,
                  onSelected: () => setState(() {
                    _selectedAddress = address;
                    _selectionTouched = true;
                  }),
                  onEdit: () => _editAddress(address),
                ),
              ),
            ),
            if (selectionError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  selectionError,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _addAddress,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm địa chỉ mới'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: CheckoutPalette.forest800,
                side: const BorderSide(color: CheckoutPalette.forest100),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            CheckoutSurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  Stack(
                    children: <Widget>[
                      const CheckoutAssetImage(
                        asset: CheckoutAssets.addressMap,
                        width: double.infinity,
                        height: 112,
                        fit: BoxFit.cover,
                      ),
                      Positioned.fill(
                        child: Container(
                          color: CheckoutPalette.forest950.withValues(
                            alpha: 0.36,
                          ),
                          alignment: Alignment.center,
                          child: FilledButton.icon(
                            onPressed: _selectedAddress == null
                                ? null
                                : () => _editAddress(_selectedAddress!),
                            icon: const Icon(
                              Icons.my_location_rounded,
                              size: 17,
                            ),
                            label: const Text('Cập nhật vị trí trên bản đồ'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      children: <Widget>[
                        CheckoutAssetImage(
                          asset: CheckoutAssets.packaging,
                          width: 58,
                          height: 48,
                          borderRadius: BorderRadius.all(Radius.circular(9)),
                        ),
                        SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'Hoa được đóng gói chống sốc và giữ ẩm chuyên dụng trong suốt hành trình.',
                            style: TextStyle(
                              color: CheckoutPalette.charcoal500,
                              fontSize: 11,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            color: CheckoutPalette.surface,
            child: FilledButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Giao đến địa chỉ này'),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressSelectionCard extends StatelessWidget {
  const _AddressSelectionCard({
    required this.address,
    required this.selected,
    required this.onSelected,
    required this.onEdit,
  });

  final CheckoutAddress address;
  final bool selected;
  final VoidCallback onSelected;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return CheckoutSurfaceCard(
      onTap: onSelected,
      color: selected ? CheckoutPalette.forest50 : CheckoutPalette.surface,
      borderColor: selected
          ? CheckoutPalette.forest700
          : CheckoutPalette.cream300,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? CheckoutPalette.forest800 : Colors.transparent,
              border: Border.all(
                color: selected
                    ? CheckoutPalette.forest800
                    : CheckoutPalette.charcoal400,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      address.label,
                      style: const TextStyle(
                        color: CheckoutPalette.charcoal900,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (address.isDefault)
                      const CheckoutStatusBadge(text: 'Mặc định'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${address.recipientName} · ${address.phone}',
                  style: const TextStyle(
                    color: CheckoutPalette.charcoal700,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  address.fullAddress,
                  style: const TextStyle(
                    color: CheckoutPalette.charcoal500,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onEdit, child: const Text('Sửa')),
        ],
      ),
    );
  }
}
