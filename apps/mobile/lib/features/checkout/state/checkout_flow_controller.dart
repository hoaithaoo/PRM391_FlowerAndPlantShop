import 'package:flutter/foundation.dart';

import '../models/checkout_flow_models.dart';

class CheckoutFlowController extends ChangeNotifier {
  CheckoutFlowController({
    List<CheckoutAddress> addresses = const <CheckoutAddress>[],
    List<PickupBranch> branches = const <PickupBranch>[],
  }) : _addresses = List<CheckoutAddress>.of(addresses),
       _branches = List<PickupBranch>.of(branches),
       _selectedAddressId =
           (addresses.where((item) => item.isDefault).firstOrNull ??
                   addresses.firstOrNull)
               ?.id,
       _selectedBranchId = branches.firstOrNull?.id;

  final List<CheckoutAddress> _addresses;
  final List<PickupBranch> _branches;
  String? _selectedAddressId;
  String? _selectedBranchId;
  FulfillmentMode fulfillmentMode = FulfillmentMode.delivery;
  LocalPaymentMethod? deliveryPaymentMethod = LocalPaymentMethod.sepay;
  LocalPaymentMethod? pickupPaymentMethod = LocalPaymentMethod.payAtStore;
  String deliveryNote = '';
  String cardMessage = '';
  String pickupNote = '';
  DateTime pickupDate = DateTime.now().add(const Duration(days: 1));
  String pickupTime = '15:00 – 16:00';

  List<CheckoutAddress> get addresses => List.unmodifiable(_addresses);
  List<PickupBranch> get branches => List.unmodifiable(_branches);
  CheckoutAddress? get selectedAddress =>
      _addresses.where((item) => item.id == _selectedAddressId).firstOrNull;
  PickupBranch? get selectedBranch =>
      _branches.where((item) => item.id == _selectedBranchId).firstOrNull;

  /// Nạp cửa hàng từ server, giữ lựa chọn cũ nếu cửa hàng đó vẫn còn.
  void setBranches(List<PickupBranch> branches) {
    _branches
      ..clear()
      ..addAll(branches);
    _selectedBranchId = (selectedBranch ?? branches.firstOrNull)?.id;
    notifyListeners();
  }

  void setFulfillmentMode(FulfillmentMode value) {
    fulfillmentMode = value;
    notifyListeners();
  }

  /// Nạp sổ địa chỉ từ server, ưu tiên chọn địa chỉ mặc định.
  void setAddresses(List<CheckoutAddress> addresses) {
    _addresses
      ..clear()
      ..addAll(addresses);
    _selectedAddressId =
        (addresses.where((item) => item.isDefault).firstOrNull ??
                addresses.firstOrNull)
            ?.id;
    notifyListeners();
  }

  void selectAddress(CheckoutAddress address) {
    _selectedAddressId = address.id;
    notifyListeners();
  }

  void updateAddress(CheckoutAddress address) {
    final index = _addresses.indexWhere((item) => item.id == address.id);
    if (index == -1) {
      _addresses.add(address);
    } else {
      _addresses[index] = address;
    }
    _selectedAddressId = address.id;
    notifyListeners();
  }

  void removeAddress(String id) {
    _addresses.removeWhere((item) => item.id == id);
    if (_selectedAddressId == id) {
      _selectedAddressId = _addresses.isEmpty ? null : _addresses.first.id;
    }
    notifyListeners();
  }

  void selectBranch(PickupBranch branch) {
    _selectedBranchId = branch.id;
    notifyListeners();
  }

  void setDeliveryPayment(LocalPaymentMethod? method) {
    deliveryPaymentMethod = method;
    notifyListeners();
  }

  void setPickupPayment(LocalPaymentMethod? method) {
    pickupPaymentMethod = method;
    notifyListeners();
  }

  void setPickupSchedule(DateTime date, String time) {
    pickupDate = date;
    pickupTime = time;
    notifyListeners();
  }
}
