import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/checkout_flow_models.dart';
import '../state/checkout_flow_controller.dart';
import '../utils/checkout_assets.dart';
import '../utils/checkout_theme.dart';
import '../utils/checkout_validators.dart';
import '../widgets/checkout_common.dart';

class PickupBranchScreen extends StatefulWidget {
  const PickupBranchScreen({super.key, required this.controller});

  final CheckoutFlowController controller;

  @override
  State<PickupBranchScreen> createState() => _PickupBranchScreenState();
}

class _PickupBranchScreenState extends State<PickupBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  late PickupBranch? _selected = widget.controller.selectedBranch;
  String _filter = 'Gần bạn';
  String _query = '';
  bool _branchTouched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PickupBranch> get _visibleBranches {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) return widget.controller.branches;
    return widget.controller.branches
        .where(
          (branch) =>
              branch.name.toLowerCase().contains(normalized) ||
              branch.address.toLowerCase().contains(normalized),
        )
        .toList();
  }

  void _confirm() {
    final formIsValid = _formKey.currentState?.validate() ?? false;
    final branchError = CheckoutValidators.selectedBranch(_selected);
    setState(() => _branchTouched = true);
    if (!formIsValid || branchError != null || _selected == null) return;
    widget.controller.selectBranch(_selected!);
    Navigator.of(context).pop(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final branchSelectionError = _branchTouched
        ? CheckoutValidators.selectedBranch(_selected)
        : null;
    return CheckoutTheme(
      child: Scaffold(
        appBar: const FleureAppBar(
          title: 'Chọn chi nhánh lấy hoa',
          showProfile: false,
        ),
        body: Form(
          key: _formKey,
          child: CheckoutContent(
            bottom: 132,
            children: <Widget>[
              TextFormField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                maxLength: 60,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      required maxLength,
                    }) => Text(
                      '$currentLength/$maxLength',
                      semanticsLabel:
                          'Đã nhập $currentLength trên $maxLength ký tự',
                    ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) => CheckoutValidators.limitedNote(
                  value,
                  maxLength: 60,
                  message: 'Nội dung tìm kiếm vượt quá số ký tự cho phép.',
                ),
                decoration: const InputDecoration(
                  hintText: 'Tìm theo tên studio hoặc khu vực',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <String>['Gần bạn', 'Mở cửa', 'Nhận nhanh']
                    .map(
                      (filter) => ChoiceChip(
                        label: Text(filter),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                        selectedColor: CheckoutPalette.forest100,
                        side: const BorderSide(color: CheckoutPalette.cream300),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              CheckoutSurfaceCard(
                padding: EdgeInsets.zero,
                child: Stack(
                  children: <Widget>[
                    const CheckoutAssetImage(
                      asset: CheckoutAssets.addressMap,
                      width: double.infinity,
                      height: 176,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CheckoutPalette.forest950.withValues(
                            alpha: 0.92,
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.storefront_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selected == null
                                    ? 'Chưa chọn chi nhánh'
                                    : '${_selected!.name} · ${_selected!.distance}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const CheckoutSectionHeader(
                title: 'Các studio sẵn sàng đón bạn',
                subtitle: 'Hoa sẽ được hoàn thiện trước giờ bạn ghé nhận.',
              ),
              const SizedBox(height: 14),
              if (_visibleBranches.isEmpty)
                const CheckoutInfoBanner(
                  icon: Icons.search_off_rounded,
                  title: 'Chưa tìm thấy studio phù hợp',
                  message: 'Thử tìm bằng tên quận hoặc xóa nội dung tìm kiếm.',
                )
              else
                ..._visibleBranches.map(
                  (branch) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BranchCard(
                      branch: branch,
                      selected: branch.id == _selected?.id,
                      onTap: () => setState(() {
                        _selected = branch;
                        _branchTouched = true;
                      }),
                    ),
                  ),
                ),
              if (branchSelectionError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    branchSelectionError,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const CheckoutInfoBanner(
                icon: Icons.eco_outlined,
                title: 'Nhận tại quán, giảm dấu chân vận chuyển',
                message:
                    'Bạn giúp Fleuré giảm bao bì giao hàng và có thể kiểm tra tác phẩm trước khi mang về.',
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
            decoration: const BoxDecoration(
              color: CheckoutPalette.surface,
              border: Border(top: BorderSide(color: CheckoutPalette.cream200)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  _selected == null
                      ? 'Chưa chọn chi nhánh'
                      : 'Đã chọn: ${_selected!.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CheckoutPalette.charcoal700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
                FilledButton.icon(
                  onPressed: _confirm,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Xác nhận chi nhánh'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.branch,
    required this.selected,
    required this.onTap,
  });

  final PickupBranch branch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CheckoutSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      color: selected ? CheckoutPalette.forest50 : CheckoutPalette.surface,
      borderColor: selected
          ? CheckoutPalette.forest700
          : CheckoutPalette.cream300,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CheckoutAssetImage(
            asset: branch.imageAsset,
            width: 88,
            height: 112,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        branch.name,
                        style: const TextStyle(
                          color: CheckoutPalette.charcoal900,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      width: 19,
                      height: 19,
                      decoration: BoxDecoration(
                        color: selected
                            ? CheckoutPalette.forest800
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: CheckoutPalette.forest700),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 13,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  branch.address,
                  style: const TextStyle(
                    color: CheckoutPalette.charcoal500,
                    fontSize: 10.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  branch.readyTime,
                  style: const TextStyle(
                    color: CheckoutPalette.forest700,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${branch.openingHours} · ${branch.distance}',
                  style: const TextStyle(
                    color: CheckoutPalette.charcoal500,
                    fontSize: 9.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  children: <Widget>[
                    Icon(
                      Icons.directions_outlined,
                      size: 14,
                      color: CheckoutPalette.petal500,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Xem đường đi',
                      style: TextStyle(
                        color: CheckoutPalette.petal500,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
