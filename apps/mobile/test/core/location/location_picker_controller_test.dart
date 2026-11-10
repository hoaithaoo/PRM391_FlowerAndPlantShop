import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/core/location/location_picker_controller.dart';
import 'package:plant_flower_mobile/core/location/location_service.dart';
import 'package:plant_flower_mobile/core/location/current_address_service.dart';

import '../../features/auth/support/current_address_test_service.dart';

const _first =
    LocationCoordinates(latitude: 10.77, longitude: 106.69, accuracy: 0);
const _second =
    LocationCoordinates(latitude: 10.78, longitude: 106.70, accuracy: 0);

void main() {
  test('không tự chọn tâm mặc định và không tự xin GPS', () {
    final service = TestCurrentAddressService();
    final controller = LocationPickerController(service: service);
    addTearDown(controller.dispose);
    expect(controller.canConfirm, isFalse);
    expect(controller.selection, isNull);
    expect(service.coordinateCalls, 0);
  });

  test('địa chỉ cũ trả về trễ không thay đổi ghim và địa chỉ mới', () async {
    final oldResult = Completer<String>();
    final newResult = Completer<String>();
    final service = TestCurrentAddressService()
      ..reverse = (point) => point.latitude == _first.latitude
          ? oldResult.future
          : newResult.future;
    final controller = LocationPickerController(service: service);
    addTearDown(controller.dispose);
    final oldRequest = controller.selectCoordinates(_first);
    final newRequest = controller.selectCoordinates(_second);
    expect(controller.canConfirm, isFalse);
    newResult.complete('Địa chỉ ở ghim mới');
    await newRequest;
    expect(controller.selection?.coordinates.latitude, _second.latitude);
    oldResult.complete('Địa chỉ cũ đến trễ');
    await oldRequest;
    expect(controller.selection?.address, 'Địa chỉ ở ghim mới');
  });

  test('kéo liên tục chỉ tra địa chỉ ở tâm cuối sau khi dừng', () {
    fakeAsync((clock) {
      final service = TestCurrentAddressService();
      final controller = LocationPickerController(service: service);
      controller.moveCenter(_first);
      clock.elapse(const Duration(milliseconds: 300));
      controller.moveCenter(_second);
      clock.elapse(const Duration(milliseconds: 300));
      expect(service.lookups, isEmpty);
      expect(controller.canConfirm, isFalse);
      clock.elapse(const Duration(milliseconds: 300));
      clock.flushMicrotasks();
      expect(service.lookups, hasLength(1));
      expect(service.lookups.single.latitude, _second.latitude);
      expect(controller.canConfirm, isTrue);
      controller.dispose();
    });
  });

  test('kéo map khi GPS còn chờ thì không bị GPS kéo về lại', () async {
    final gps = Completer<LocationCoordinates>();
    final service = TestCurrentAddressService()..locate = () => gps.future;
    final controller = LocationPickerController(service: service);
    addTearDown(controller.dispose);
    final locating = controller.findCurrentLocation();
    await controller.selectCoordinates(_second);
    gps.complete(_first);
    expect(await locating, isNull);
    expect(controller.selection?.coordinates.latitude, _second.latitude);
  });

  test('từ chối GPS vẫn chọn được điểm trên bản đồ', () async {
    final service = TestCurrentAddressService()
      ..locate =
          () async => throw const LocationException(LocationFailure.denied);
    final controller = LocationPickerController(service: service);
    addTearDown(controller.dispose);
    await controller.findCurrentLocation();
    expect(controller.locationFailure, LocationFailure.denied);
    expect(controller.canConfirm, isFalse);
    await controller.selectCoordinates(_second);
    expect(controller.locationFailure, isNull);
    expect(controller.canConfirm, isTrue);
  });

  test('lỗi đổi địa chỉ khoá xác nhận và có thể thử lại', () async {
    final service = TestCurrentAddressService()
      ..resolve = () async => throw const AddressLookupException();
    final controller = LocationPickerController(service: service);
    addTearDown(controller.dispose);
    await controller.selectCoordinates(_first);
    expect(controller.canConfirm, isFalse);
    expect(controller.error, isNotNull);
    service.resolve = () async => 'Địa chỉ đã tìm lại';
    await controller.retryAddress();
    expect(controller.selection?.address, 'Địa chỉ đã tìm lại');
    expect(controller.error, isNull);
  });

  test('nhập địa chỉ tại ghim khi tra tên đường thất bại vẫn giữ đúng tọa độ',
      () async {
    final service = TestCurrentAddressService()
      ..resolve = () async => throw const AddressLookupException();
    final controller = LocationPickerController(service: service);
    addTearDown(controller.dispose);
    await controller.selectCoordinates(_second);
    controller.setManualAddress('12');
    expect(controller.canConfirm, isFalse);
    controller.setManualAddress('12 Đường Hoa, TP. Hồ Chí Minh');
    expect(controller.selection?.coordinates.latitude, _second.latitude);
    expect(controller.selection?.address, '12 Đường Hoa, TP. Hồ Chí Minh');
    controller.moveCenter(_first);
    expect(controller.canConfirm, isFalse);
    expect(controller.address, isNull);
  });

  test('rời màn không cập nhật controller đã dispose khi địa chỉ về trễ',
      () async {
    final pending = Completer<String>();
    final controller = LocationPickerController(
      service: TestCurrentAddressService()..resolve = () => pending.future,
    );
    final request = controller.selectCoordinates(_first);
    controller.dispose();
    pending.complete('Địa chỉ về sau khi đã rời map');
    await expectLater(request, completes);
  });
}
