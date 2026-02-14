import 'package:flutter/foundation.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/block/data/models/block_model.dart';

class BlockProvider extends ChangeNotifier {
  final ApiService _apiService;

  BlockProvider(this._apiService);

  List<BlockModel> _blockList = [];
  final Set<String> _blockedIds = {};
  bool _isLoading = false;
  String? _error;

  List<BlockModel> get blockList => _blockList;
  Set<String> get blockedIds => _blockedIds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isBlocked(String entityId) => _blockedIds.contains(entityId);

  /// Load the list of blocked accounts
  Future<void> loadBlockList() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getBlockList();
      final List<dynamic> blocks = data['blocks'] ?? [];
      _blockList = blocks
          .map((b) => BlockModel.fromJson(b as Map<String, dynamic>))
          .toList();
      _blockedIds.clear();
      for (final block in _blockList) {
        _blockedIds.add(block.entityId);
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('BlockProvider: Error loading block list: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Block/hide an entity
  Future<bool> blockEntity({
    required String entityId,
    required String entityType,
    String? entityName,
    String? entityImage,
  }) async {
    try {
      await _apiService.blockEntity(entityId, entityType);
      _blockedIds.add(entityId);
      // Create a local model to add to the list immediately
      _blockList.add(BlockModel(
        id: '', // Local placeholder
        entityId: entityId,
        entityType: entityType,
        entityName: entityName,
        entityImage: entityImage,
        blockedAt: DateTime.now(),
      ));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('BlockProvider: Error blocking entity: $e');
      return false;
    }
  }

  /// Unblock/unhide an entity
  Future<bool> unblockEntity(String entityId) async {
    try {
      await _apiService.unblockEntity(entityId);
      _blockedIds.remove(entityId);
      _blockList.removeWhere((b) => b.entityId == entityId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('BlockProvider: Error unblocking entity: $e');
      return false;
    }
  }
}
