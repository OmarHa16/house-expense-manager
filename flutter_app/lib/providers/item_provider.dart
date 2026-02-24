import 'package:flutter/foundation.dart';
import '../models/item.dart';
import '../services/api_service.dart';

class ItemProvider extends ChangeNotifier {
  List<Item> _items = [];
  bool _isLoading = false;
  String? _error;

  List<Item> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await apiService.getItems();
      _items.sort((a, b) => a.name.compareTo(b.name));
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Item> createItem(String name, {double? defaultPrice, String? category}) async {
    try {
      final item = await apiService.createItem(name, defaultPrice: defaultPrice, category: category);
      _items.add(item);
      _items.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      return item;
    } catch (e) {
      debugPrint('Error creating item: $e');
      rethrow;
    }
  }

  Item? findItemByName(String name) {
    try {
      return _items.firstWhere((item) => item.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
