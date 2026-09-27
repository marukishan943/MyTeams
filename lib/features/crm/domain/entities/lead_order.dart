import 'package:equatable/equatable.dart';

enum OrderStatus {
  open,
  pending,
  cancelled,
  deliveryDone,
  converted;

  String get displayName {
    switch (this) {
      case OrderStatus.open:
        return 'Open';
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.deliveryDone:
        return 'Delivery done';
      case OrderStatus.converted:
        return 'Converted';
    }
  }
}

class OrderPayment extends Equatable {
  final String id;
  final String orderId;
  final double amount;
  final String mode; // 'Online' or 'Cash'
  final DateTime date;
  final DateTime createdAt;

  const OrderPayment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.mode,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'amount': amount,
      'mode': mode,
      'date': date.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    return OrderPayment(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      mode: json['mode']?.toString() ?? 'Online',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, orderId, amount, mode, date, createdAt];
}

class OrderItem extends Equatable {
  final String id;
  final String product;
  final double rate;
  final double quantity;
  final double discount;
  final bool isPercentageDiscount;
  final double taxPercent;
  final String description;

  const OrderItem({
    required this.id,
    required this.product,
    required this.rate,
    required this.quantity,
    this.discount = 0.0,
    this.isPercentageDiscount = false,
    this.taxPercent = 0.0,
    this.description = '',
  });

  double get subtotal => rate * quantity;

  double get discountAmount {
    if (isPercentageDiscount) {
      return (subtotal * discount) / 100.0;
    }
    return discount;
  }

  double get taxableAmount {
    final amt = subtotal - discountAmount;
    return amt > 0 ? amt : 0.0;
  }

  double get taxAmount => (taxableAmount * taxPercent) / 100.0;

  double get total => taxableAmount + taxAmount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product,
      'rate': rate,
      'quantity': quantity,
      'discount': discount,
      'is_percentage_discount': isPercentageDiscount,
      'tax_percent': taxPercent,
      'description': description,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      product: json['product']?.toString() ?? '',
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      isPercentageDiscount: json['is_percentage_discount'] as bool? ?? false,
      taxPercent: (json['tax_percent'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        product,
        rate,
        quantity,
        discount,
        isPercentageDiscount,
        taxPercent,
        description,
      ];
}

class LeadOrder extends Equatable {
  final String id;
  final String leadId;
  final String orderNumber;
  final String staffName;
  final DateTime date;
  final DateTime? dueDate;
  final OrderStatus status;
  final double taxableAmount;
  final String discountType; // 'fixed' or 'percent'
  final double discountValue;
  final double totalDiscount;
  final bool roundOff;
  final double totalAmount;
  final List<OrderItem> items;
  final List<OrderPayment> payments;
  final DateTime createdAt;
  /// 'order' | 'invoice' | 'proforma_invoice'
  final String type;

  const LeadOrder({
    required this.id,
    required this.leadId,
    required this.orderNumber,
    required this.staffName,
    required this.date,
    this.dueDate,
    this.status = OrderStatus.open,
    this.taxableAmount = 0.0,
    this.discountType = 'fixed',
    this.discountValue = 0.0,
    this.totalDiscount = 0.0,
    this.roundOff = false,
    this.totalAmount = 0.0,
    this.items = const [],
    this.payments = const [],
    required this.createdAt,
    this.type = 'order',
  });

  String get typeLabel {
    switch (type) {
      case 'invoice':
        return 'INV';
      case 'proforma_invoice':
        return 'PFI';
      default:
        return 'ORD';
    }
  }

  double get paidAmount {
    return payments.fold(0.0, (sum, p) => sum + p.amount);
  }

  double get dueBalance {
    final bal = totalAmount - paidAmount;
    return bal > 0 ? bal : 0.0;
  }

  bool get isPaid => paidAmount >= totalAmount && totalAmount > 0;

  LeadOrder copyWith({
    String? id,
    String? leadId,
    String? orderNumber,
    String? staffName,
    DateTime? date,
    DateTime? dueDate,
    OrderStatus? status,
    double? taxableAmount,
    String? discountType,
    double? discountValue,
    double? totalDiscount,
    bool? roundOff,
    double? totalAmount,
    List<OrderItem>? items,
    List<OrderPayment>? payments,
    DateTime? createdAt,
    String? type,
  }) {
    return LeadOrder(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      orderNumber: orderNumber ?? this.orderNumber,
      staffName: staffName ?? this.staffName,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      taxableAmount: taxableAmount ?? this.taxableAmount,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      roundOff: roundOff ?? this.roundOff,
      totalAmount: totalAmount ?? this.totalAmount,
      items: items ?? this.items,
      payments: payments ?? this.payments,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [
        id,
        leadId,
        orderNumber,
        staffName,
        date,
        dueDate,
        status,
        taxableAmount,
        discountType,
        discountValue,
        totalDiscount,
        roundOff,
        totalAmount,
        items,
        payments,
        createdAt,
        type,
      ];
}

