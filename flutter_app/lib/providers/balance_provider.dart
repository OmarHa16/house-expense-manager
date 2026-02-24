import 'package:flutter/foundation.dart';
import '../models/balance.dart';
import '../services/api_service.dart';

class BalanceProvider extends ChangeNotifier {
  List<Balance> _balances = [];
  UserBalanceDetail? _myBalance;
  BalanceSummary? _summary;
  bool _isLoading = false;
  String? _error;

  List<Balance> get balances => _balances;
  UserBalanceDetail? get myBalance => _myBalance;
  BalanceSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBalances() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _balances = await apiService.getBalances();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading balances: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyBalance() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myBalance = await apiService.getMyBalance();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading my balance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSummary() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _summary = await apiService.getBalanceSummary();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading summary: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadBalances(),
        loadMyBalance(),
        loadSummary(),
      ]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
