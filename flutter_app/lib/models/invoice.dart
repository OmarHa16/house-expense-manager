class Invoice {
  final int id;
  final DateTime date;
  final int createdBy;
  final String? createdByName;
  final bool isDone;
  final double totalAmount;
  final bool isDeleted;
  final List<InvoiceItem> items;
  final List<Payment> payments;

  Invoice({
    required this.id,
    required this.date,
    required this.createdBy,
    this.createdByName,
    this.isDone = false,
    required this.totalAmount,
    this.isDeleted = false,
    this.items = const [],
    this.payments = const [],
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      date: DateTime.parse(json['date']),
      createdBy: json['created_by'],
      createdByName: json['created_by_name'],
      isDone: json['is_done'] == 1 || json['is_done'] == true,
      totalAmount: (json['total_amount'] as num).toDouble(),
      isDeleted: json['is_deleted'] == 1 || json['is_deleted'] == true,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => InvoiceItem.fromJson(i)).toList()
          : [],
      payments: json['payments'] != null
          ? (json['payments'] as List).map((p) => Payment.fromJson(p)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'created_by': createdBy,
      'is_done': isDone,
      'total_amount': totalAmount,
      'items': items.map((i) => i.toJson()).toList(),
      'payments': payments.map((p) => p.toJson()).toList(),
    };
  }

  Invoice copyWith({
    int? id,
    DateTime? date,
    int? createdBy,
    String? createdByName,
    bool? isDone,
    double? totalAmount,
    bool? isDeleted,
    List<InvoiceItem>? items,
    List<Payment>? payments,
  }) {
    return Invoice(
      id: id ?? this.id,
      date: date ?? this.date,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      isDone: isDone ?? this.isDone,
      totalAmount: totalAmount ?? this.totalAmount,
      isDeleted: isDeleted ?? this.isDeleted,
      items: items ?? this.items,
      payments: payments ?? this.payments,
    );
  }
}

class InvoiceItem {
  final int id;
  final int? itemId;
  final String itemName;
  final double pricePerUnit;
  final double quantity;
  final List<int> consumers;
  final double totalPrice;

  InvoiceItem({
    required this.id,
    this.itemId,
    required this.itemName,
    required this.pricePerUnit,
    required this.quantity,
    required this.consumers,
    this.totalPrice = 0,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    List<int> consumersList = [];
    if (json['consumers'] is String) {
      // Parse JSON string like "[1,2,3]"
      final consumersStr = json['consumers'] as String;
      consumersList = consumersStr
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(',')
          .where((s) => s.trim().isNotEmpty)
          .map((s) => int.parse(s.trim()))
          .toList();
    } else if (json['consumers'] is List) {
      consumersList = (json['consumers'] as List).map((c) => c as int).toList();
    }

    return InvoiceItem(
      id: json['id'],
      itemId: json['item_id'],
      itemName: json['item_name'] ?? 'Unknown',
      pricePerUnit: (json['price_per_unit'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      consumers: consumersList,
      totalPrice: json['total_price'] != null 
          ? (json['total_price'] as num).toDouble() 
          : (json['price_per_unit'] as num).toDouble() * (json['quantity'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'pricePerUnit': pricePerUnit,
      'quantity': quantity,
      'consumers': consumers,
    };
  }

  double get total => pricePerUnit * quantity;
  double get costPerConsumer => consumers.isNotEmpty ? total / consumers.length : total;
}

class Payment {
  final int id;
  final int userId;
  final String? userName;
  final double amountPaid;

  Payment({
    required this.id,
    required this.userId,
    this.userName,
    required this.amountPaid,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      amountPaid: (json['amount_paid'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amountPaid': amountPaid,
    };
  }
}

// For creating new invoices
class CreateInvoiceRequest {
  final List<CreateInvoiceItem> items;
  final List<CreatePayment> payments;

  CreateInvoiceRequest({
    required this.items,
    required this.payments,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((i) => i.toJson()).toList(),
      'payments': payments.map((p) => p.toJson()).toList(),
    };
  }
}

class CreateInvoiceItem {
  final int? itemId;
  final String itemName;
  final double pricePerUnit;
  final double quantity;
  final List<int> consumers;

  CreateInvoiceItem({
    this.itemId,
    required this.itemName,
    required this.pricePerUnit,
    required this.quantity,
    required this.consumers,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'pricePerUnit': pricePerUnit,
      'quantity': quantity,
      'consumers': consumers,
    };
  }
}

class CreatePayment {
  final int userId;
  final double amountPaid;

  CreatePayment({
    required this.userId,
    required this.amountPaid,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'amountPaid': amountPaid,
    };
  }
}
