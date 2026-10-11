import 'package:flutter/foundation.dart';

import '../data/checkout_mock_data.dart';
import '../models/checkout_flow_models.dart';

class CheckoutFlowController extends ChangeNotifier {
  CheckoutFlowController({
    List<CheckoutAddress> addresses = CheckoutMockData.addresses,
    List<PickupBranch> branches = CheckoutMockData.branches,
  }) : _addresses = List<CheckoutAddress>.of(addresses),
       _branches = List<PickupBranch>.of(branches),
       _selectedAddressId = addresses.first.id,
       _selectedBranchId = branches.first.id;

  final List<CheckoutAddress> _addresses;
  final List<PickupBranch> _branches;
  String _selectedAddressId;
  String _selectedBranchId;
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
  CheckoutAddress get selectedAddress =>
      _addresses.firstWhere((item) => item.id == _selectedAddressId);
  PickupBranch get selectedBranch =>
      _branches.firstWhere((item) => item.id == _selectedBranchId);

  void setFulfillmentMode(FulfillmentMode value) {
    fulfillmentMode = value;
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
