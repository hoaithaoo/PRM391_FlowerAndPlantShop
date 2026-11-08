import 'package:flutter/foundation.dart';

import '../../../core/location/location_service.dart';
import '../../checkout/data/checkout_failure.dart';
import '../../checkout/models/checkout_flow_models.dart';

typedef StoreLoader = Future<List<PickupBranch>> Function({
  double? latitude,
  double? longitude,
});

typedef CurrentCoordinatesLoader = Future<LocationCoordinates> Function();

enum StoreMapStatus { initial, loading, loaded, empty, error }

class StoreMapController extends ChangeNotifier {
  StoreMapController({
    required StoreLoader storeLoader,
    required CurrentCoordinatesLoader currentCoordinatesLoader,
  }) : _storeLoader = storeLoader,
       _currentCoordinatesLoader = currentCoordinatesLoader;

  final StoreLoader _storeLoader;
  final CurrentCoordinatesLoader _currentCoordinatesLoader;

  StoreMapStatus _status = StoreMapStatus.initial;
  List<PickupBranch> _stores = const [];
  PickupBranch? _selectedStore;
  LocationCoordinates? _userLocation;
  LocationFailure? _locationFailure;
  String? _storeError;
  bool _locating = false;
  int _requestId = 0;

  StoreMapStatus get status => _status;
  List<PickupBranch> get stores => _stores;
  PickupBranch? get selectedStore => _selectedStore;
  LocationCoordinates? get userLocation => _userLocation;
  LocationFailure? get locationFailure => _locationFailure;
  String? get storeError => _storeError;
  bool get locating => _locating;
  bool get isRefreshing => _status == StoreMapStatus.loading && _stores.isNotEmpty;

  Future<void> initialize() => _loadStores(clearBeforeLoad: true);

  Future<void> refresh() => _loadStores(clearBeforeLoad: false);

  Future<bool> findCurrentLocation() async {
    if (_locating) return false;
    _locating = true;
    _locationFailure = null;
    notifyListeners();
    try {
      final coordinates = await _currentCoordinatesLoader();
      if (!coordinates.isValid) {
        throw const LocationException(LocationFailure.invalidCoordinates);
      }
      _userLocation = coordinates;
      _locationFailure = null;
      notifyListeners();
      await _loadStores(clearBeforeLoad: false);
      return true;
    } on LocationException catch (error) {
      _locationFailure = error.failure;
      return false;
    } catch (_) {
      _locationFailure = LocationFailure.unavailable;
      return false;
    } finally {
      _locating = false;
      notifyListeners();
    }
  }

  void selectStore(PickupBranch store) {
    _selectedStore = store;
    notifyListeners();
  }

  void clearLocationMessage() {
    if (_locationFailure == null) return;
    _locationFailure = null;
    notifyListeners();
  }

  Future<void> _loadStores({required bool clearBeforeLoad}) async {
    final requestId = ++_requestId;
    if (clearBeforeLoad) _stores = const [];
    _storeError = null;
    _status = StoreMapStatus.loading;
    notifyListeners();
    try {
      final location = _userLocation;
      final result = await _storeLoader(
        latitude: location?.latitude,
        longitude: location?.longitude,
      );
      if (requestId != _requestId) return;
      final unique = <String, PickupBranch>{};
      for (final store in result) {
        unique[store.id] = store;
      }
      _stores = List<PickupBranch>.unmodifiable(unique.values);
      _selectedStore = _stores
          .where((store) => store.id == _selectedStore?.id)
          .firstOrNull;
      _status = _stores.isEmpty ? StoreMapStatus.empty : StoreMapStatus.loaded;
    } on CheckoutFailure catch (error) {
      if (requestId != _requestId) return;
      _storeError = error.message ?? 'Không thể tải danh sách cửa hàng.';
      _status = _stores.isEmpty ? StoreMapStatus.error : StoreMapStatus.loaded;
    } catch (_) {
      if (requestId != _requestId) return;
      _storeError = 'Không thể tải danh sách cửa hàng.';
      _status = _stores.isEmpty ? StoreMapStatus.error : StoreMapStatus.loaded;
    } finally {
      if (requestId == _requestId) notifyListeners();
    }
  }
}
