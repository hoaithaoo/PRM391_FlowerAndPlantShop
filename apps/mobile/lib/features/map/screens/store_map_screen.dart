import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/location/location_service.dart';
import '../../checkout/data/checkout_repository.dart';
import '../../checkout/models/checkout_flow_models.dart';
import '../../checkout/utils/currency_formatter.dart';
import '../state/store_map_controller.dart';

class StoreMapScreen extends StatefulWidget {
  const StoreMapScreen({
    super.key,
    required this.repository,
    this.locationService = const LocationService(),
    this.urlLauncher,
  });

  final CheckoutRepository repository;
  final LocationService locationService;
  final Future<bool> Function(Uri url)? urlLauncher;

  @override
  State<StoreMapScreen> createState() => _StoreMapScreenState();
}

class _StoreMapScreenState extends State<StoreMapScreen> {
  static const _defaultCenter = LatLng(16.0, 108.0);
  static const _forest700 = Color(0xFF224A35);
  static const _petal500 = Color(0xFFA84366);

  late final MapController _mapController;
  late final StoreMapController _controller;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _controller = StoreMapController(
      storeLoader: ({latitude, longitude}) => widget.repository.listStores(
        latitude: latitude,
        longitude: longitude,
      ),
      currentCoordinatesLoader: widget.locationService.getCurrentCoordinates,
    )..addListener(_onStateChanged);
    _initialize();
  }

  Future<void> _initialize() async {
    await _controller.initialize();
    if (!mounted) return;
    _fitAvailableMarkers();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onStateChanged)
      ..dispose();
    _mapController.dispose();
    super.dispose();
  }

  List<LatLng> get _storePoints => _controller.stores
      .where((store) => store.hasValidCoordinates)
      .map((store) => LatLng(store.latitude!, store.longitude!))
      .toList(growable: false);

  void _fitAvailableMarkers() {
    if (!_mapReady) return;
    final points = <LatLng>[..._storePoints];
    final user = _controller.userLocation;
    if (user != null) points.add(LatLng(user.latitude, user.longitude));
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 14);
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.fromLTRB(44, 70, 44, 110),
        maxZoom: 15,
      ),
    );
  }

  Future<void> _refreshStores() async {
    await _controller.refresh();
    if (!mounted) return;
    _fitAvailableMarkers();
    final error = _controller.storeError;
    if (error != null && _controller.stores.isNotEmpty) _showMessage(error);
  }

  Future<void> _findCurrentLocation() async {
    final success = await _controller.findCurrentLocation();
    if (!mounted) return;
    if (success) {
      final location = _controller.userLocation!;
      _mapController.move(LatLng(location.latitude, location.longitude), 15);
      if (location.accuracy > 1000) {
        _showMessage(
          'Vị trí hiện tại có độ chính xác thấp. Bạn có thể thử lại.',
        );
      }
      return;
    }
    _showLocationFailure(_controller.locationFailure);
  }

  void _showLocationFailure(LocationFailure? failure) {
    if (failure == null) return;
    final canOpenSettings = widget.locationService.supportsSettings;
    final settingsAction = switch (failure) {
      LocationFailure.deniedForever when canOpenSettings => SnackBarAction(
        label: 'Mở cài đặt',
        onPressed: widget.locationService.openAppSettings,
      ),
      LocationFailure.serviceDisabled when canOpenSettings => SnackBarAction(
        label: 'Bật định vị',
        onPressed: widget.locationService.openLocationSettings,
      ),
      _ => null,
    };
    final webSuffix = kIsWeb && failure == LocationFailure.deniedForever
        ? ' Hãy cho phép vị trí trong cài đặt của trình duyệt.'
        : '';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${failure.message}$webSuffix'),
          action: settingsAction,
        ),
      );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _selectStore(PickupBranch store) {
    _controller.selectStore(store);
    if (store.hasValidCoordinates) {
      _mapController.move(LatLng(store.latitude!, store.longitude!), 15);
    }
  }

  Future<void> _openOsmCopyright() async {
    final opened = await _launchExternalUrl(
      Uri.parse('https://www.openstreetmap.org/copyright'),
    );
    if (!opened && mounted) {
      _showMessage('Không thể mở thông tin bản quyền OpenStreetMap.');
    }
  }

  Future<bool> _launchExternalUrl(Uri url) {
    final launcher = widget.urlLauncher;
    if (launcher != null) return launcher(url);
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _openDirections(PickupBranch store) async {
    if (!store.hasValidCoordinates) return;
    final destination = '${store.latitude},${store.longitude}';
    final url = Uri.https('www.google.com', '/maps/dir/', <String, String>{
      'api': '1',
      'destination': destination,
      'travelmode': 'driving',
    });
    final opened = await _launchExternalUrl(url);
    if (!opened && mounted) {
      _showMessage('Không thể mở ứng dụng chỉ đường.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vị trí cửa hàng'),
        actions: <Widget>[
          IconButton(
            key: const Key('store-map-refresh'),
            tooltip: 'Làm mới',
            onPressed: _controller.isRefreshing ? null : _refreshStores,
            icon: _controller.isRefreshing
                ? const SizedBox.square(
                    dimension: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Expanded(flex: 6, child: _buildMap()),
            Expanded(flex: 4, child: _buildStoreList()),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: <Widget>[
        FlutterMap(
          key: const Key('store-map'),
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: 5.2,
            minZoom: 4,
            maxZoom: 19,
            onMapReady: () {
              _mapReady = true;
              _fitAvailableMarkers();
            },
          ),
          children: <Widget>[
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.plantflowershop.plant_flower_mobile',
              maxNativeZoom: 19,
            ),
            MarkerLayer(markers: _buildMarkers()),
            RichAttributionWidget(
              attributions: <SourceAttribution>[
                TextSourceAttribution(
                  '© OpenStreetMap contributors',
                  onTap: _openOsmCopyright,
                ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Column(
            children: <Widget>[
              _MapActionButton(
                key: const Key('store-map-my-location'),
                tooltip: 'Vị trí của tôi',
                onPressed: _controller.locating ? null : _findCurrentLocation,
                child: _controller.locating
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
              ),
              const SizedBox(height: 8),
              _MapActionButton(
                tooltip: 'Hiện tất cả cửa hàng',
                onPressed: _storePoints.isEmpty ? null : _fitAvailableMarkers,
                child: const Icon(Icons.center_focus_strong_rounded),
              ),
            ],
          ),
        ),
        if (_controller.status == StoreMapStatus.loading &&
            _controller.stores.isEmpty)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x66FFF8FA),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        if (_controller.status == StoreMapStatus.error)
          Positioned.fill(
            child: _MapMessage(
              icon: Icons.cloud_off_outlined,
              message:
                  _controller.storeError ??
                  'Không thể tải danh sách cửa hàng.',
              actionLabel: 'Thử lại',
              onAction: _refreshStores,
            ),
          ),
        if (_controller.status == StoreMapStatus.empty)
          const Positioned.fill(
            child: _MapMessage(
              icon: Icons.store_mall_directory_outlined,
              message: 'Không tìm thấy cửa hàng.',
            ),
          ),
        if (_controller.selectedStore case final store?)
          Positioned(
            left: 12,
            right: 72,
            bottom: 28,
            child: _SelectedStoreCard(
              store: store,
              onDirections: store.hasValidCoordinates
                  ? () => _openDirections(store)
                  : null,
            ),
          ),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[
      for (final store in _controller.stores)
        if (store.hasValidCoordinates)
          Marker(
            point: LatLng(store.latitude!, store.longitude!),
            width: 48,
            height: 54,
            child: Semantics(
              button: true,
              label: 'Cửa hàng ${store.name}',
              child: GestureDetector(
                onTap: () => _selectStore(store),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 46,
                  color: _controller.selectedStore?.id == store.id
                      ? _petal500
                      : AppColors.primary,
                  shadows: const <Shadow>[
                    Shadow(color: Color(0x55000000), blurRadius: 5),
                  ],
                ),
              ),
            ),
          ),
    ];
    final user = _controller.userLocation;
    if (user != null) {
      markers.add(
        Marker(
          point: LatLng(user.latitude, user.longitude),
          width: 34,
          height: 34,
          child: Semantics(
            label: 'Vị trí hiện tại của bạn',
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2D7FF9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Color(0x44000000), blurRadius: 8),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  Widget _buildStoreList() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Color(0xFFE9DDD7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Các cửa hàng gần bạn',
                    style: AppTextStyles.headline2.copyWith(
                      color: const Color(0xFF171C19),
                      fontSize: 20,
                    ),
                  ),
                ),
                Text(
                  '${_controller.stores.length} cửa hàng',
                  style: const TextStyle(
                    color: _forest700,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (_controller.locationFailure case final failure?)
            _LocationNotice(
              message: failure.message,
              onRetry: _findCurrentLocation,
              onDismiss: _controller.clearLocationMessage,
            ),
          Expanded(
            child: _controller.stores.isEmpty
                ? Center(
                    child: Text(
                      _controller.status == StoreMapStatus.loading
                          ? 'Đang tải cửa hàng…'
                          : 'Chưa có cửa hàng để hiển thị.',
                      style: const TextStyle(color: Color(0xFF68716C)),
                    ),
                  )
                : ListView.separated(
                    key: const Key('store-map-list'),
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 20),
                    itemCount: _controller.stores.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final store = _controller.stores[index];
                      return _StoreListTile(
                        store: store,
                        selected: _controller.selectedStore?.id == store.id,
                        onTap: () => _selectStore(store),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: AppColors.primary,
        icon: child,
      ),
    );
  }
}

class _MapMessage extends StatelessWidget {
  const _MapMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xDDFFF8FA),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: AppColors.primary, size: 38),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
              if (actionLabel != null) ...[
                const SizedBox(height: 12),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedStoreCard extends StatelessWidget {
  const _SelectedStoreCard({required this.store, this.onDirections});

  final PickupBranch store;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              store.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              store.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF68716C)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: <Widget>[
                if (store.phone?.trim().isNotEmpty == true)
                  _StoreFact(icon: Icons.phone_outlined, text: store.phone!),
                if (store.openingHours.trim().isNotEmpty)
                  _StoreFact(
                    icon: Icons.schedule_outlined,
                    text: store.openingHours,
                  ),
                if (store.distanceKm != null)
                  _StoreFact(
                    icon: Icons.route_outlined,
                    text: store.distance,
                  ),
                if (store.shippingFee != null)
                  _StoreFact(
                    icon: Icons.local_shipping_outlined,
                    text: 'Phí giao ${formatVnd(store.shippingFee!)}',
                  ),
              ],
            ),
            if (onDirections != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('store-map-directions'),
                  onPressed: onDirections,
                  icon: const Icon(Icons.directions_outlined, size: 17),
                  label: const Text('Chỉ đường'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StoreListTile extends StatelessWidget {
  const _StoreListTile({
    required this.store,
    required this.selected,
    required this.onTap,
  });

  final PickupBranch store;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE2F0E9) : Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : const Color(0xFFE2F0E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  color: selected ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      store.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      store.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF68716C),
                        fontSize: 11,
                      ),
                    ),
                    if (store.distanceKm != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        store.distance,
                        style: const TextStyle(
                          color: Color(0xFFA84366),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.map_outlined, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreFact extends StatelessWidget {
  const _StoreFact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 13, color: const Color(0xFF224A35)),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5),
          ),
        ),
      ],
    );
  }
}

class _LocationNotice extends StatelessWidget {
  const _LocationNotice({
    required this.message,
    required this.onRetry,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEAF0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.location_off_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 11)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
          IconButton(
            tooltip: 'Đóng',
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
