import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/balance_provider.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/item.dart';
import '../models/invoice.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class AddInvoiceScreen extends StatefulWidget {
  const AddInvoiceScreen({super.key});

  @override
  State<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  final List<InvoiceItemForm> _items = [];
  final List<PaymentForm> _payments = [];
  List<User> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Add initial empty item
    _addItem();
  }

  Future<void> _loadData() async {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    await itemProvider.loadItems();
    
    // Load users for selection
    try {
      final users = await apiService.getUsers();
      setState(() {
        _users = users;
      });
    } catch (e) {
      // If not admin, at least add current user
      if (authProvider.user != null) {
        setState(() {
          _users = [authProvider.user!];
        });
      }
    }
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceItemForm(
        itemNameController: TextEditingController(),
        priceController: TextEditingController(),
        quantityController: TextEditingController(text: '1'),
        selectedConsumers: [],
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  void _addPayment() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _payments.add(PaymentForm(
        userId: authProvider.user?.id ?? 0,
        amountController: TextEditingController(),
      ));
    });
  }

  void _removePayment(int index) {
    setState(() {
      _payments[index].dispose();
      _payments.removeAt(index);
    });
  }

  double get _totalAmount {
    return _items.fold(0, (sum, item) {
      final price = double.tryParse(item.priceController.text) ?? 0;
      final quantity = double.tryParse(item.quantityController.text) ?? 1;
      return sum + (price * quantity);
    });
  }

  double get _totalPayments {
    return _payments.fold(0, (sum, payment) {
      return sum + (double.tryParse(payment.amountController.text) ?? 0);
    });
  }

  Future<void> _submit() async {
    // Validate
    if (_items.isEmpty) {
      _showError('Add at least one item');
      return;
    }

    for (var item in _items) {
      if (item.itemNameController.text.isEmpty) {
        _showError('Item name is required');
        return;
      }
      if (item.selectedConsumers.isEmpty) {
        _showError('Select at least one consumer for each item');
        return;
      }
    }

    if (_payments.isEmpty) {
      _showError('Add at least one payment');
      return;
    }

    if ((_totalAmount - _totalPayments).abs() > 0.01) {
      _showError('Total payments (${AppConstants.currencySymbol}${_totalPayments.toStringAsFixed(2)}) must equal total amount (${AppConstants.currencySymbol}${_totalAmount.toStringAsFixed(2)})');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
      final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
      
      final request = CreateInvoiceRequest(
        items: _items.map((item) => CreateInvoiceItem(
          itemId: item.selectedItem?.id,
          itemName: item.itemNameController.text,
          pricePerUnit: double.parse(item.priceController.text),
          quantity: double.parse(item.quantityController.text),
          consumers: item.selectedConsumers,
        )).toList(),
        payments: _payments.map((payment) => CreatePayment(
          userId: payment.userId,
          amountPaid: double.parse(payment.amountController.text),
        )).toList(),
      );

      await invoiceProvider.createInvoice(request);
      await balanceProvider.loadBalances();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice created successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  void dispose() {
    for (var item in _items) {
      item.dispose();
    }
    for (var payment in _payments) {
      payment.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Invoice'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Items Section
                  _buildSectionTitle('Items', Icons.shopping_cart),
                  const SizedBox(height: 12),
                  ..._items.asMap().entries.map((entry) {
                    return _buildItemCard(entry.key, entry.value, itemProvider);
                  }),
                  _buildAddButton('Add Item', _addItem),
                  const SizedBox(height: 24),

                  // Payments Section
                  _buildSectionTitle('Payments', Icons.payments),
                  const SizedBox(height: 12),
                  ..._payments.asMap().entries.map((entry) {
                    return _buildPaymentCard(entry.key, entry.value);
                  }),
                  _buildAddButton('Add Payment', _addPayment),
                  const SizedBox(height: 24),

                  // Summary
                  _buildSummaryCard(),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text(
                        'Create Invoice',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(int index, InvoiceItemForm item, ItemProvider itemProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return itemProvider.items.map((i) => i.name);
                      }
                      return itemProvider.items
                          .where((i) => i.name.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              ))
                          .map((i) => i.name);
                    },
                    onSelected: (String selection) {
                      final selected = itemProvider.findItemByName(selection);
                      if (selected != null) {
                        setState(() {
                          item.selectedItem = selected;
                          item.itemNameController.text = selected.name;
                          if (selected.defaultPrice != null) {
                            item.priceController.text = selected.defaultPrice.toString();
                          }
                        });
                      }
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      // Sync with our controller
                      if (controller.text != item.itemNameController.text) {
                        controller.text = item.itemNameController.text;
                      }
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          hintText: 'Enter or select item',
                        ),
                        onChanged: (value) {
                          item.itemNameController.text = value;
                        },
                      );
                    },
                  ),
                ),
                if (_items.length > 1) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                    onPressed: () => _removeItem(index),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Price per unit',
                      prefixText: AppConstants.currencySymbol,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: item.quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Consumers:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _users.map((user) {
                final isSelected = item.selectedConsumers.contains(user.id);
                return FilterChip(
                  label: Text(user.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        item.selectedConsumers.add(user.id);
                      } else {
                        item.selectedConsumers.remove(user.id);
                      }
                    });
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  checkmarkColor: AppTheme.primaryColor,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(int index, PaymentForm payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<int>(
                value: payment.userId,
                decoration: const InputDecoration(
                  labelText: 'Paid by',
                ),
                items: _users.map((user) {
                  return DropdownMenuItem(
                    value: user.id,
                    child: Text(user.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    payment.userId = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: payment.amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: AppConstants.currencySymbol,
                ),
              ),
            ),
            if (_payments.length > 1) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                onPressed: () => _removePayment(index),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final difference = _totalAmount - _totalPayments;
    final isBalanced = difference.abs() < 0.01;

    return Card(
      color: isBalanced ? AppTheme.successColor.withOpacity(0.1) : AppTheme.warningColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '${AppConstants.currencySymbol}${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Payments:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '${AppConstants.currencySymbol}${_totalPayments.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isBalanced ? 'Balanced ✓' : 'Difference:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isBalanced ? AppTheme.successColor : AppTheme.warningColor,
                  ),
                ),
                if (!isBalanced)
                  Text(
                    '${AppConstants.currencySymbol}${difference.abs().toStringAsFixed(2)} ${difference > 0 ? "underpaid" : "overpaid"}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warningColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InvoiceItemForm {
  final TextEditingController itemNameController;
  final TextEditingController priceController;
  final TextEditingController quantityController;
  List<int> selectedConsumers;
  Item? selectedItem;

  InvoiceItemForm({
    required this.itemNameController,
    required this.priceController,
    required this.quantityController,
    required this.selectedConsumers,
    this.selectedItem,
  });

  void dispose() {
    itemNameController.dispose();
    priceController.dispose();
    quantityController.dispose();
  }
}

class PaymentForm {
  int userId;
  final TextEditingController amountController;

  PaymentForm({
    required this.userId,
    required this.amountController,
  });

  void dispose() {
    amountController.dispose();
  }
}
