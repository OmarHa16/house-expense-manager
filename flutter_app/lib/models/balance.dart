class Balance {
  final int userId;
  final String name;
  final double amountOwed;
  final double amountPaid;
  final double netBalance;

  Balance({
    required this.userId,
    required this.name,
    required this.amountOwed,
    required this.amountPaid,
    required this.netBalance,
  });

  factory Balance.fromJson(Map<String, dynamic> json) {
    return Balance(
      userId: json['userId'],
      name: json['name'],
      amountOwed: (json['amountOwed'] as num).toDouble(),
      amountPaid: (json['amountPaid'] as num).toDouble(),
      netBalance: (json['netBalance'] as num).toDouble(),
    );
  }

  bool get isPositive => netBalance > 0;
  bool get isNegative => netBalance < 0;
  bool get isSettled => netBalance.abs() < 0.01;

  String get displayBalance {
    if (isSettled) return 'Settled';
    if (isPositive) return '+${netBalance.toStringAsFixed(2)}';
    return netBalance.toStringAsFixed(2);
  }

  String get statusText {
    if (isSettled) return 'All settled up';
    if (isPositive) return 'Should receive';
    return 'Owes money';
  }
}

class Transaction {
  final int from;
  final String fromName;
  final int to;
  final String toName;
  final double amount;

  Transaction({
    required this.from,
    required this.fromName,
    required this.to,
    required this.toName,
    required this.amount,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      from: json['from'],
      fromName: json['fromName'],
      to: json['to'],
      toName: json['toName'],
      amount: (json['amount'] as num).toDouble(),
    );
  }

  String get description => '$fromName should pay ${amount.toStringAsFixed(2)} to $toName';
}

class UserBalanceDetail extends Balance {
  final List<Transaction> owesTo;
  final List<Transaction> owedFrom;

  UserBalanceDetail({
    required super.userId,
    required super.name,
    required super.amountOwed,
    required super.amountPaid,
    required super.netBalance,
    required this.owesTo,
    required this.owedFrom,
  });

  factory UserBalanceDetail.fromJson(Map<String, dynamic> json) {
    return UserBalanceDetail(
      userId: json['userId'],
      name: json['name'],
      amountOwed: (json['amountOwed'] as num).toDouble(),
      amountPaid: (json['amountPaid'] as num).toDouble(),
      netBalance: (json['netBalance'] as num).toDouble(),
      owesTo: json['owesTo'] != null
          ? (json['owesTo'] as List).map((t) => Transaction.fromJson(t)).toList()
          : [],
      owedFrom: json['owedFrom'] != null
          ? (json['owedFrom'] as List).map((t) => Transaction.fromJson(t)).toList()
          : [],
    );
  }

  double get totalOwed => owesTo.fold(0, (sum, t) => sum + t.amount);
  double get totalOwedFrom => owedFrom.fold(0, (sum, t) => sum + t.amount);
}

class BalanceSummary {
  final double totalActiveDebt;
  final double totalToBeReceived;
  final int userCount;
  final int activeTransactions;
  final List<Transaction> transactions;

  BalanceSummary({
    required this.totalActiveDebt,
    required this.totalToBeReceived,
    required this.userCount,
    required this.activeTransactions,
    required this.transactions,
  });

  factory BalanceSummary.fromJson(Map<String, dynamic> json) {
    return BalanceSummary(
      totalActiveDebt: (json['totalActiveDebt'] as num).toDouble(),
      totalToBeReceived: (json['totalToBeReceived'] as num).toDouble(),
      userCount: json['userCount'],
      activeTransactions: json['activeTransactions'],
      transactions: json['transactions'] != null
          ? (json['transactions'] as List).map((t) => Transaction.fromJson(t)).toList()
          : [],
    );
  }
}
