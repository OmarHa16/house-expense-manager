import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/balance_provider.dart';
import '../providers/invoice_provider.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import 'change_password_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    
    await Future.wait([
      balanceProvider.loadMyBalance(),
      balanceProvider.loadSummary(),
      invoiceProvider.loadInvoices(),
    ]);
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final balanceProvider = Provider.of<BalanceProvider>(context);
    final invoiceProvider = Provider.of<InvoiceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          if (authProvider.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => Navigator.pushNamed(context, '/admin'),
            ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'change_password') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              } else if (value == 'logout') {
                await authProvider.logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'change_password',
                child: Row(
                  children: [
                    Icon(Icons.lock_outline),
                    SizedBox(width: 8),
                    Text('Change Password'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              _buildWelcomeCard(authProvider.user?.name ?? 'User'),
              const SizedBox(height: 20),
              
              // Balance Card
              _buildBalanceCard(balanceProvider),
              const SizedBox(height: 20),
              
              // Detailed Debts - Who to pay / Who owes you
              _buildDetailedDebts(balanceProvider),
              const SizedBox(height: 20),
              
              // Summary Cards
              _buildSummaryCards(balanceProvider),
              const SizedBox(height: 20),
              
              // Recent Invoices
              _buildRecentInvoices(invoiceProvider),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-invoice'),
        icon: const Icon(Icons.add),
        label: const Text('Add Invoice'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            Navigator.pushNamed(context, '/invoices');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/change-password');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Invoices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock_outline),
            label: 'Password',
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(String name) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                size: 30,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BalanceProvider provider) {
    final myBalance = provider.myBalance;
    
    if (provider.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (myBalance == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No balance data available')),
        ),
      );
    }

    final isPositive = myBalance.netBalance > 0;
    final isNegative = myBalance.netBalance < 0;
    final isSettled = myBalance.netBalance.abs() < 0.01;

    Color balanceColor = AppTheme.successColor;
    String balanceText = 'Settled Up';
    IconData balanceIcon = Icons.check_circle;

    if (isPositive) {
      balanceColor = AppTheme.secondaryColor;
      balanceText = 'You should receive';
      balanceIcon = Icons.arrow_downward;
    } else if (isNegative) {
      balanceColor = AppTheme.errorColor;
      balanceText = 'You owe';
      balanceIcon = Icons.arrow_upward;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(balanceIcon, color: balanceColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  balanceText,
                  style: TextStyle(
                    fontSize: 16,
                    color: balanceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${AppConstants.currencySymbol}${myBalance.netBalance.abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: balanceColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceDetail(
                    'Total Paid',
                    myBalance.amountPaid,
                    AppTheme.secondaryColor,
                    Icons.payments,
                  ),
                ),
                Container(width: 1, height: 50, color: Colors.grey.shade300),
                Expanded(
                  child: _buildBalanceDetail(
                    'Total Owed',
                    myBalance.amountOwed,
                    AppTheme.errorColor,
                    Icons.shopping_cart,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceDetail(String label, double amount, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          '${AppConstants.currencySymbol}${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedDebts(BalanceProvider provider) {
    final myBalance = provider.myBalance;
    
    if (provider.isLoading || myBalance == null) {
      return const SizedBox.shrink();
    }

    final owesTo = myBalance.owesTo ?? [];
    final owedFrom = myBalance.owedFrom ?? [];
    
    if (owesTo.isEmpty && owedFrom.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // You owe section
        if (owesTo.isNotEmpty) ...[
          Card(
            color: AppTheme.errorColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_upward, color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      Text(
                        'You Need to Pay',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  ...owesTo.map((debt) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.person,
                            color: AppTheme.errorColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                debt.toName ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Pay ${AppConstants.currencySymbol}${debt.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: AppTheme.errorColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${AppConstants.currencySymbol}${debt.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  if (owesTo.length > 1) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Total to Pay: ',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${AppConstants.currencySymbol}${owesTo.fold<double>(0, (sum, d) => sum + d.amount).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // You are owed section
        if (owedFrom.isNotEmpty) ...[
          Card(
            color: AppTheme.secondaryColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_downward, color: AppTheme.secondaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'You Should Receive',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  ...owedFrom.map((debt) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.person,
                            color: AppTheme.secondaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                debt.fromName ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Owes you ${AppConstants.currencySymbol}${debt.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: AppTheme.secondaryColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${AppConstants.currencySymbol}${debt.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  if (owedFrom.length > 1) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Total to Receive: ',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${AppConstants.currencySymbol}${owedFrom.fold<double>(0, (sum, d) => sum + d.amount).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCards(BalanceProvider provider) {
    final summary = provider.summary;
    
    if (summary == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Active\nTransactions',
            summary.activeTransactions.toString(),
            AppTheme.primaryColor,
            Icons.swap_horiz,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Total\nUsers',
            summary.userCount.toString(),
            AppTheme.secondaryColor,
            Icons.people,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentInvoices(InvoiceProvider provider) {
    final recentInvoices = provider.invoices.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Invoices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/invoices'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recentInvoices.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No invoices yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/add-invoice'),
                      child: const Text('Add First Invoice'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentInvoices.length,
            itemBuilder: (context, index) {
              final invoice = recentInvoices[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
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
                    '${invoice.items.length} items • ${invoice.createdByName ?? 'Unknown'}',
                  ),
                  trailing: Text(
                    '${AppConstants.currencySymbol}${invoice.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
