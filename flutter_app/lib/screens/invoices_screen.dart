import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/auth_provider.dart';
import '../models/invoice.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    await Provider.of<InvoiceProvider>(context, listen: false).loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = Provider.of<InvoiceProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Invoices'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active', icon: Icon(Icons.pending)),
              Tab(text: 'Done', icon: Icon(Icons.check_circle)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInvoiceList(
              invoiceProvider.activeInvoices,
              invoiceProvider,
              authProvider,
              isActive: true,
            ),
            _buildInvoiceList(
              invoiceProvider.doneInvoices,
              invoiceProvider,
              authProvider,
              isActive: false,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/add-invoice'),
          icon: const Icon(Icons.add),
          label: const Text('Add Invoice'),
        ),
      ),
    );
  }

  Widget _buildInvoiceList(
    List<Invoice> invoices,
    InvoiceProvider provider,
    AuthProvider authProvider, {
    required bool isActive,
  }) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.pending : Icons.check_circle,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active invoices' : 'No done invoices',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/add-invoice'),
                child: const Text('Add Invoice'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInvoices,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          final invoice = invoices[index];
          return _buildInvoiceCard(invoice, provider, authProvider);
        },
      ),
    );
  }

  Widget _buildInvoiceCard(
    Invoice invoice,
    InvoiceProvider provider,
    AuthProvider authProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: invoice.isDone
                ? AppTheme.successColor.withOpacity(0.1)
                : AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            invoice.isDone ? Icons.check_circle : Icons.receipt,
            color: invoice.isDone ? AppTheme.successColor : AppTheme.primaryColor,
          ),
        ),
        title: Text('Invoice #${invoice.id}'),
        subtitle: Text(
          '${invoice.items.length} items • Total: ${AppConstants.currencySymbol}${invoice.totalAmount.toStringAsFixed(2)}',
        ),
        trailing: !invoice.isDone
            ? PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'done') {
                    await _markAsDone(invoice.id);
                  } else if (value == 'delete') {
                    await _deleteInvoice(invoice);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'done',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.successColor),
                        SizedBox(width: 8),
                        Text('Mark as Done'),
                      ],
                    ),
                  ),
                  if (authProvider.isAdmin)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppTheme.errorColor),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                ],
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items
                const Text(
                  'Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...invoice.items.map((item) => _buildItemRow(item)),
                const Divider(height: 24),
                // Payments
                const Text(
                  'Payments',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...invoice.payments.map((payment) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.payment),
                      title: Text(payment.userName ?? 'User ${payment.userId}'),
                      trailing: Text(
                        '${AppConstants.currencySymbol}${payment.amountPaid.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(dynamic item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(item.itemName),
          ),
          Text(
            '${item.quantity} × ${AppConstants.currencySymbol}${item.pricePerUnit.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(width: 16),
          Text(
            '${AppConstants.currencySymbol}${item.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsDone(int invoiceId) async {
    try {
      final provider = Provider.of<InvoiceProvider>(context, listen: false);
      await provider.markAsDone(invoiceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice marked as done'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: Text('Are you sure you want to delete Invoice #${invoice.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final provider = Provider.of<InvoiceProvider>(context, listen: false);
        final result = await provider.deleteInvoice(invoice.id);
        
        if (mounted) {
          // Show undo option
          final undoExpiresAt = DateTime.parse(result['undoExpiresAt']);
          final remainingSeconds = undoExpiresAt.difference(DateTime.now()).inSeconds;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invoice deleted. Undo available for $remainingSeconds seconds'),
              backgroundColor: AppTheme.warningColor,
              duration: const Duration(seconds: 10),
              action: SnackBarAction(
                label: 'UNDO',
                textColor: Colors.white,
                onPressed: () async {
                  try {
                    await provider.undoDelete(invoice.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invoice restored'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Undo failed: ${e.toString()}'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }
}
