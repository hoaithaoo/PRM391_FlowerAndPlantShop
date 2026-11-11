import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/location/current_address_service.dart';
import '../../../core/location/delivery_location.dart';
import '../../../core/location/location_picker_controller.dart';
import '../../../core/location/location_service.dart';
import '../../../core/widgets/street_map_layer.dart';
import '../utils/auth_theme.dart';
import '../widgets/auth_common.dart';

class DeliveryLocationPickerScreen extends StatefulWidget {
  const DeliveryLocationPickerScreen({
    super.key,
    required this.service,
    this.initialLocation,
    this.useCurrentLocation = true,
  });

  final CurrentAddressService service;
  final DeliveryLocation? initialLocation;
  final bool useCurrentLocation;

  @override
  State<DeliveryLocationPickerScreen> createState() =>
      _DeliveryLocationPickerScreenState();
}

class _DeliveryLocationPickerScreenState
    extends State<DeliveryLocationPickerScreen> {
  final _map = MapController();
  final _manualAddress = TextEditingController();
  bool _manualEntry = false;
  late final LocationPickerController _picker;

  @override
  void initState() {
    super.initState();
    _picker = LocationPickerController(
      service: widget.service,
      initialLocation: widget.initialLocation,
    )..addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _picker
      ..removeListener(_refresh)
      ..dispose();
    _map.dispose();
    _manualAddress.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    _clearManualEntry();
    final point = await _picker.findCurrentLocation();
    if (mounted && point != null) {
      _map.move(LatLng(point.latitude, point.longitude), 17);
    }
  }

  LocationCoordinates _point(LatLng value) => LocationCoordinates(
        latitude: value.latitude,
        longitude: value.longitude,
        accuracy: 0,
      );

  void _pickAt(LatLng point) {
    _clearManualEntry();
    _map.move(point, _map.camera.zoom);
    unawaited(_picker.selectCoordinates(_point(point)));
  }

  void _clearManualEntry() {
    if (!_manualEntry) return;
    _manualEntry = false;
    _manualAddress.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialLocation?.coordinates;
    return Scaffold(
      backgroundColor: AuthPalette.background,
      appBar: AppBar(
        backgroundColor: AuthPalette.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Chọn vị trí nhận hàng', style: AuthTextStyles.headerTitle),
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            Padding(
              // Thẳng mép với tiêu đề AppBar (nút back 56 + khoảng 16).
              padding: const EdgeInsetsDirectional.fromSTEB(72, 0, 20, 12),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'Kéo bản đồ để đặt ghim đúng nơi nhận hàng.',
                  style: AuthFonts.sans(fontSize: 13, color: AuthPalette.sage),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    key: const Key('delivery_location_map'),
                    mapController: _map,
                    options: MapOptions(
                      initialCenter: initial == null
                          ? const LatLng(10.7769, 106.7009)
                          : LatLng(initial.latitude, initial.longitude),
                      initialZoom: initial == null ? 12 : 17,
                      minZoom: 4,
                      maxZoom: 19,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onMapReady: () {
                        if (widget.useCurrentLocation) {
                          unawaited(_locate());
                        }
                      },
                      onPositionChanged: (camera, hasGesture) {
                        if (hasGesture) {
                          _clearManualEntry();
                          _picker.moveCenter(_point(camera.center));
                        }
                      },
                      onTap: (_, point) => _pickAt(point),
                    ),
                    children: [
                      const StreetMapLayer(),
                      RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            '© OpenMapTiles',
                            onTap: () => launchUrl(
                              Uri.parse('https://openmaptiles.org/'),
                            ),
                          ),
                          TextSourceAttribution(
                            '© OpenStreetMap contributors',
                            onTap: () => launchUrl(
                              Uri.parse(
                                'https://www.openstreetmap.org/copyright',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Transform.translate(
                          offset: const Offset(0, -24),
                          child: const Icon(
                            Icons.location_pin,
                            size: 48,
                            color: AuthPalette.forest,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (MediaQuery.viewInsetsOf(context).bottom == 0)
                    Positioned(
                      bottom: 52,
                      right: 16,
                      child: Column(
                        children: [
                          _mapButton(
                            key: const Key('delivery_location_recenter'),
                            tooltip: 'Về vị trí hiện tại',
                            icon: Icons.my_location,
                            onPressed: _picker.locating ? null : _locate,
                          ),
                          const SizedBox(height: 8),
                          _mapButton(
                            tooltip: 'Phóng to',
                            icon: Icons.add,
                            onPressed: () => _map.move(
                              _map.camera.center,
                              math.min(19.0, _map.camera.zoom + 1),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _mapButton(
                            tooltip: 'Thu nhỏ',
                            icon: Icons.remove,
                            onPressed: () => _map.move(
                              _map.camera.center,
                              math.max(4.0, _map.camera.zoom - 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight *
                    (MediaQuery.viewInsetsOf(context).bottom > 0 ? .68 : .5),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildConfirmation(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: _confirmationAction(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmation() {
    final busy = _picker.locating || _picker.resolving;
    final status = _picker.locating
        ? 'Đang xác định vị trí của bạn…'
        : _picker.resolving
            ? 'Đang tìm địa chỉ tại ghim…'
            : _picker.address ??
                _picker.error ??
                'Kéo bản đồ hoặc chạm một điểm để chọn nơi nhận hàng.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Địa chỉ tại ghim',
          style: AuthFonts.sans(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Semantics(
          liveRegion: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (busy) ...[
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  status,
                  key: const Key('delivery_location_address'),
                  style: AuthFonts.sans(
                    fontSize: 13,
                    height: 1.6,
                    color: _picker.error == null
                        ? AuthPalette.ink
                        : AuthPalette.error,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_picker.error != null) ...[
          if (widget.service.supportsSettings &&
              (_picker.locationFailure == LocationFailure.deniedForever ||
                  _picker.locationFailure == LocationFailure.serviceDisabled))
            TextButton(
              key: const Key('delivery_location_settings'),
              onPressed:
                  _picker.locationFailure == LocationFailure.deniedForever
                      ? widget.service.openAppSettings
                      : widget.service.openLocationSettings,
              child: Text(
                _picker.locationFailure == LocationFailure.deniedForever
                    ? 'Mở cài đặt quyền vị trí'
                    : 'Bật dịch vụ định vị',
              ),
            )
          else if (_picker.coordinates != null &&
              _picker.locationFailure == null)
            Wrap(
              children: [
                TextButton(
                  onPressed: _picker.retryAddress,
                  child: const Text('Thử lại'),
                ),
                TextButton(
                  key: const Key('delivery_location_enter_address'),
                  onPressed: () => setState(() => _manualEntry = true),
                  child: const Text('Nhập địa chỉ cho ghim này'),
                ),
              ],
            ),
        ],
        if (_manualEntry) ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('delivery_location_manual_address'),
            controller: _manualAddress,
            onChanged: _picker.setManualAddress,
            minLines: 2,
            maxLines: 4,
            style: AuthTextStyles.input,
            decoration: const InputDecoration(
              labelText: 'Địa chỉ tại ghim đã chọn',
              hintText: 'Số nhà, tên đường, phường/xã, tỉnh/thành',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        if (_picker.coordinates != null && _picker.coordinates!.accuracy > 100)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'GPS có thể lệch khoảng ${_picker.coordinates!.accuracy.round()} m. Kéo bản đồ để chỉnh ghim.',
              style: AuthFonts.sans(
                fontSize: 12,
                color: AuthPalette.sage,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _confirmationAction() => AuthPrimaryButton(
        key: const Key('delivery_location_confirm'),
        label: 'Xác nhận vị trí này',
        height: 52,
        radius: 14,
        onPressed: _picker.canConfirm
            ? () => Navigator.of(context).pop(_picker.selection)
            : null,
      );

  Widget _mapButton({
    Key? key,
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: AuthPalette.surface,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      child: IconButton(
        key: key,
        tooltip: tooltip,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        onPressed: onPressed,
        color: AuthPalette.forest,
        icon: Icon(icon, size: 22),
      ),
    );
  }
}
