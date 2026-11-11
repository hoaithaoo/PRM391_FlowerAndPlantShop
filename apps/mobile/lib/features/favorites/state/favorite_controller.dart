import 'package:flutter/foundation.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

import '../data/favorite_repository.dart';

class FavoriteController extends ChangeNotifier {
  FavoriteController({required FavoriteRepository repository})
    : _repository = repository;

  final FavoriteRepository _repository;
  final _ids = <String>{};
  final _pending = <String>{};
  int _generation = 0;
  int _revision = 0;
  int _loadId = 0;
  bool _disposed = false;

  Set<String> get ids => Set.unmodifiable(_ids);
  bool isFavorite(String id) => _ids.contains(id);

  Future<bool> load() async {
    final generation = _generation;
    final revision = _revision;
    final loadId = ++_loadId;
    try {
      final ids = await _repository.listIds();
      if (_disposed || generation != _generation || loadId != _loadId) {
        return false;
      }
      // Không ghi đè thao tác lạc quan bằng kết quả tải về đã cũ.
      if (revision == _revision && _pending.isEmpty) {
        _ids
          ..clear()
          ..addAll(ids);
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<ProductSummary>> listProducts() => _repository.list();

  Future<bool> toggle(String id) async {
    if (_disposed) return false;
    // Bấm tim liên tục khi request trước chưa xong: bỏ qua, không phải lỗi.
    if (!_pending.add(id)) return true;
    final generation = _generation;
    final wasFavorite = isFavorite(id);
    _revision++;
    if (wasFavorite) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    notifyListeners();
    try {
      if (wasFavorite) {
        await _repository.remove(id);
      } else {
        await _repository.add(id);
      }
      return !_disposed && generation == _generation;
    } catch (_) {
      if (!_disposed && generation == _generation) {
        if (wasFavorite) {
          _ids.add(id);
        } else {
          _ids.remove(id);
        }
        _revision++;
        notifyListeners();
      }
      return false;
    } finally {
      if (generation == _generation) _pending.remove(id);
    }
  }

  /// Vô hiệu hoá yêu cầu cũ để dữ liệu không lọt sang tài khoản kế tiếp.
  void reset() {
    _generation++;
    _revision++;
    _ids.clear();
    _pending.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
