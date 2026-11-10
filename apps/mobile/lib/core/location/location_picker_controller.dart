import 'dart:async';

import 'package:flutter/foundation.dart';

import 'current_address_service.dart';
import 'delivery_location.dart';
import 'location_service.dart';

/// Chỉ địa chỉ của tâm bản đồ mới nhất mới được dùng để xác nhận.
class LocationPickerController extends ChangeNotifier {
  LocationPickerController({
    required this.service,
    DeliveryLocation? initialLocation,
    this.debounce = const Duration(milliseconds: 550),
  })  : _coordinates = initialLocation?.coordinates,
        _address = initialLocation?.address;

  final CurrentAddressService service;
  final Duration debounce;
  LocationCoordinates? _coordinates;
  String? _address;
  String? _error;
  LocationFailure? _locationFailure;
  bool _locating = false;
  bool _resolving = false;
  bool _disposed = false;
  int _revision = 0;
  Timer? _timer;

  LocationCoordinates? get coordinates => _coordinates;
  String? get address => _address;
  String? get error => _error;
  LocationFailure? get locationFailure => _locationFailure;
  bool get locating => _locating;
  bool get resolving => _resolving;
  bool get canConfirm =>
      !_locating &&
      !_resolving &&
      _coordinates?.isValid == true &&
      _address?.isNotEmpty == true;

  DeliveryLocation? get selection => canConfirm
      ? DeliveryLocation(coordinates: _coordinates!, address: _address!)
      : null;

  Future<LocationCoordinates?> findCurrentLocation() async {
    if (_disposed || _locating) return null;
    final request = ++_revision;
    _timer?.cancel();
    _locating = true;
    _resolving = false;
    _address = null;
    _error = null;
    _locationFailure = null;
    notifyListeners();
    try {
      final point = await service.getCurrentCoordinates();
      if (_disposed || request != _revision) return null;
      unawaited(selectCoordinates(point));
      return point;
    } on LocationException catch (error) {
      if (_disposed || request != _revision) return null;
      _locationFailure = error.failure;
      _error =
          '${error.failure.message} Bạn có thể kéo bản đồ để chọn nơi nhận.';
    } catch (_) {
      if (_disposed || request != _revision) return null;
      _error = 'Chưa lấy được vị trí. Bạn có thể kéo bản đồ để chọn nơi nhận.';
    }
    if (!_disposed && request == _revision) {
      _locating = false;
      notifyListeners();
    }
    return null;
  }

  /// Đánh dấu địa chỉ cũ hết hiệu lực ngay lúc kéo, chỉ tra khi bản đồ dừng.
  void moveCenter(LocationCoordinates point) {
    if (_disposed || !point.isValid) return;
    final request = _beginSelection(point);
    _timer = Timer(debounce, () => _resolve(point, request));
  }

  Future<void> selectCoordinates(LocationCoordinates point) async {
    if (_disposed || !point.isValid) return;
    final request = _beginSelection(point);
    await _resolve(point, request);
  }

  int _beginSelection(LocationCoordinates point) {
    final request = ++_revision;
    _timer?.cancel();
    _coordinates = point;
    _address = null;
    _error = null;
    _locationFailure = null;
    _locating = false;
    _resolving = true;
    notifyListeners();
    return request;
  }

  Future<void> _resolve(LocationCoordinates point, int request) async {
    try {
      final result = await service.getAddressForCoordinates(point);
      if (_disposed || request != _revision) return;
      if (result.trim().isEmpty) throw const AddressLookupException();
      _address = result;
    } catch (_) {
      if (_disposed || request != _revision) return;
      _error =
          'Chưa tìm được địa chỉ tại ghim này. Bạn có thể thử lại hoặc nhập địa chỉ cho ghim đã chọn.';
    } finally {
      if (!_disposed && request == _revision) {
        _resolving = false;
        notifyListeners();
      }
    }
  }

  Future<void> retryAddress() async {
    final point = _coordinates;
    if (point != null && !_locating && !_resolving) {
      await selectCoordinates(point);
    }
  }

  void setManualAddress(String value) {
    if (_disposed || _locating || _resolving || _coordinates == null) return;
    _address = value.trim().length >= 5 ? value.trim() : null;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    _timer?.cancel();
    super.dispose();
  }
}
