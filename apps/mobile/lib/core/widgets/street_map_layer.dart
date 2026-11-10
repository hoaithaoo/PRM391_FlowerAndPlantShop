import 'package:flutter/material.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;

/// Lớp đường phố dùng nguồn OpenFreeMap, không phụ thuộc tile.openstreetmap.org.
class StreetMapLayer extends StatefulWidget {
  const StreetMapLayer({super.key, this.styleLoader});

  final Future<vt.Style> Function()? styleLoader;

  static const styleUrl = 'https://tiles.openfreemap.org/styles/liberty';

  @override
  State<StreetMapLayer> createState() => _StreetMapLayerState();
}

class _StreetMapLayerState extends State<StreetMapLayer> {
  vt.Style? _style;
  bool _loading = true;
  bool _failed = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final logger = vt.Logger.custom(onWarn: (message) {
      debugPrint('[StreetMap] $message');
      if (message.startsWith('tile request')) _showFailure(request);
    });
    final pending = Future<vt.Style>.sync(() =>
        widget.styleLoader?.call() ??
        vt.StyleReader(
          uri: StreetMapLayer.styleUrl,
          language: 'vi',
          headers: const {
            'User-Agent':
                'NhaCoHoa/1.0 (com.plantflowershop.plant_flower_mobile)'
          },
          logger: logger,
        ).read());
    vt.Style? loaded;
    try {
      loaded = await pending.timeout(const Duration(seconds: 18));
      if (loaded.providers.providers.isEmpty) {
        throw StateError('Không có dữ liệu bản đồ đường phố.');
      }
      if (!mounted || request != _request) {
        loaded.dispose();
        return;
      }
      final previous = _style;
      setState(() {
        _style = loaded;
        _loading = false;
        _failed = false;
      });
      if (previous != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
      }
    } catch (error) {
      debugPrint('[StreetMap] Không tải được bản đồ: $error');
      loaded?.dispose();
      // Dọn tài nguyên nếu request chỉ hoàn tất sau khi UI đã hết thời gian chờ.
      pending.then((lateStyle) {
        if (lateStyle != loaded) lateStyle.dispose();
      }, onError: (Object _) {});
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  void _showFailure(int request) {
    if (!mounted || _failed || request != _request) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && request == _request) setState(() => _failed = true);
    });
  }

  @override
  void dispose() {
    _request++;
    _style?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final request = _request;
    return Stack(fit: StackFit.expand, children: [
      if (style != null)
        vt.VectorTileLayer(
          key: ObjectKey(style),
          theme: style.theme,
          tileProviders: style.providers,
          rasterSources: style.rasterSources,
          sprites: style.sprites,
          glyphs: style.glyphs,
          labelMode: vt.LabelMode.tile,
          tileFadeDuration: Duration.zero,
          labelFadeDuration: Duration.zero,
          logger: vt.Logger.custom(onWarn: (message) {
            debugPrint('[StreetMap] $message');
            if (message.startsWith('tile request')) _showFailure(request);
          }),
        ),
      if (_loading || _failed)
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(children: [
                if (_loading) ...[
                  const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                ],
                Expanded(
                    child: Text(
                        _loading
                            ? 'Đang tải bản đồ…'
                            : 'Chưa tải được bản đồ. Hãy thử lại.',
                        style: Theme.of(context).textTheme.bodySmall)),
                if (_failed)
                  TextButton(
                      key: const Key('street_map_retry'),
                      onPressed: _load,
                      child: const Text('Thử lại')),
              ]),
            ),
          ),
        ),
    ]);
  }
}
