import 'package:flutter/foundation.dart';
import '../models/invoice.dart';
import '../services/api_service.dart';

class InvoiceProvider extends ChangeNotifier {
  List<Invoice> _invoices = [];
  bool _isLoading = false;
  String? _error;

  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Invoice> get activeInvoices => _invoices.where((i) => !i.isDone).toList();
  List<Invoice> get doneInvoices => _invoices.where((i) => i.isDone).toList();

  Future<void> loadInvoices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _invoices = await apiService.getInvoices();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading invoices: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Invoice> createInvoice(CreateInvoiceRequest request) async {
    try {
      final invoice = await apiService.createInvoice(request);
      _invoices.insert(0, invoice);
      notifyListeners();
      return invoice;
    } catch (e) {
      debugPrint('Error creating invoice: $e');
      rethrow;
    }
  }

  Future<void> markAsDone(int invoiceId) async {
    try {
      await apiService.markInvoiceDone(invoiceId);
      final index = _invoices.indexWhere((i) => i.id == invoiceId);
      if (index != -1) {
        _invoices[index] = _invoices[index].copyWith(isDone: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking invoice as done: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteInvoice(int invoiceId) async {
    try {
      final result = await apiService.deleteInvoice(invoiceId);
      final index = _invoices.indexWhere((i) => i.id == invoiceId);
      if (index != -1) {
        _invoices[index] = _invoices[index].copyWith(isDeleted: true);
        notifyListeners();
      }
      return result;
    } catch (e) {
      debugPrint('Error deleting invoice: $e');
      rethrow;
    }
  }

  Future<void> undoDelete(int invoiceId) async {
    try {
      await apiService.undoDeleteInvoice(invoiceId);
      final index = _invoices.indexWhere((i) => i.id == invoiceId);
      if (index != -1) {
        _invoices[index] = _invoices[index].copyWith(isDeleted: false);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error undoing delete: $e');
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
