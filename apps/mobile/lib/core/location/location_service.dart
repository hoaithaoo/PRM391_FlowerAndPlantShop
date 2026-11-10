import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

// trạng thái thất bại khi lấy vị trí
enum LocationFailure {
  serviceDisabled,
  denied,
  deniedForever,
  timeout,
  unavailable,
  invalidCoordinates,
}

extension LocationFailureMessage on LocationFailure {
  String get message => switch (this) {
    LocationFailure.serviceDisabled =>
      'Vui lòng bật dịch vụ định vị để tiếp tục.',
    LocationFailure.denied => 'Bạn chưa cấp quyền truy cập vị trí.',
    LocationFailure.deniedForever =>
      'Quyền vị trí đã bị tắt. Vui lòng bật lại trong phần cài đặt.',
    LocationFailure.timeout =>
      'Không thể xác định vị trí. Vui lòng thử lại.',
    LocationFailure.unavailable =>
      'Thiết bị hiện không cung cấp được vị trí.',
    LocationFailure.invalidCoordinates =>
      'Tọa độ nhận được không hợp lệ. Vui lòng thử lại.',
  };
}

class LocationException implements Exception {
  const LocationException(this.failure);
  final LocationFailure failure;
}

class LocationCoordinates {
  const LocationCoordinates({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  final double latitude;
  final double longitude;
  final double accuracy;

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

class LocationService {
  const LocationService();

  bool get supportsSettings => !kIsWeb;

  // hàm getCurrentLocation trả về một Future<Position> để xác định xem vị trí hiện tại có được lấy thành công hay không.
  Future<Position> getCurrentLocation() async {
    // dùng await để chờ kết quả của các hàm bất đồng bộ
    //! await Geolocator.isLocationServiceEnabled() kiểm tra xem dịch vụ định vị có được bật hay không. Nếu không, ném ra LocationException với LocationFailure.serviceDisabled.
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationException(LocationFailure.serviceDisabled);
      }
    } on LocationException {
      rethrow;
    } catch (_) {
      throw const LocationException(LocationFailure.unavailable);
    }
    LocationPermission permission;
    try {
      permission = await Geolocator.checkPermission();
    } catch (_) {
      throw const LocationException(LocationFailure.unavailable);
    }
    // dùng denied để xác định xem quyền truy cập vị trí
    // always và whileInUse là quyền truy cập vị trí được phép, trong khi denied và deniedForever là quyền truy cập vị trí bị từ chối.

    if (permission == LocationPermission.denied) {
      try {
        permission = await Geolocator.requestPermission();
      } catch (_) {
        throw const LocationException(LocationFailure.unavailable);
      }
      if (permission == LocationPermission.denied) {
        throw const LocationException(LocationFailure.denied);
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationFailure.deniedForever);
    }
    // lấy toạ độ
    try {
      // 2. Sửa chữ 'Try' thành 'try' viết thường
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _validate(position);
      return position;
    } on TimeoutException {
      // getLastKnownPosition không được hỗ trợ trên Flutter Web.
      if (!kIsWeb) {
        try {
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) {
            _validate(last);
            return last;
          }
        } catch (_) {
          // Giữ lỗi timeout gốc để UI cho phép người dùng thử lại.
        }
      }
      throw const LocationException(LocationFailure.timeout);
    } on LocationException {
      rethrow;
    } catch (_) {
      throw const LocationException(LocationFailure.unavailable);
    }
  }

  Future<LocationCoordinates> getCurrentCoordinates() async {
    final position = await getCurrentLocation();
    return LocationCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );
  }

  Future<bool> openAppSettings() async =>
      kIsWeb ? false : Geolocator.openAppSettings();

  Future<bool> openLocationSettings() async =>
      kIsWeb ? false : Geolocator.openLocationSettings();

  void _validate(Position position) {
    final coordinates = LocationCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );
    if (!coordinates.isValid) {
      throw const LocationException(LocationFailure.invalidCoordinates);
    }
  }
}
