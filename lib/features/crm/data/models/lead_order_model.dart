import '../../domain/entities/lead_order.dart';

class LeadOrderModel extends LeadOrder {
  const LeadOrderModel({
    required super.id,
    required super.leadId,
    required super.orderNumber,
    required super.staffName,
    required super.date,
    super.dueDate,
    super.status,
    super.taxableAmount,
    super.discountType,
    super.discountValue,
    super.totalDiscount,
    super.roundOff,
    super.totalAmount,
    super.items,
    super.payments,
    required super.createdAt,
    super.type,
  });

  factory LeadOrderModel.fromEntity(LeadOrder order) {
    return LeadOrderModel(
      id: order.id,
      leadId: order.leadId,
      orderNumber: order.orderNumber,
      staffName: order.staffName,
      date: order.date,
      dueDate: order.dueDate,
      status: order.status,
      taxableAmount: order.taxableAmount,
      discountType: order.discountType,
      discountValue: order.discountValue,
      totalDiscount: order.totalDiscount,
      roundOff: order.roundOff,
      totalAmount: order.totalAmount,
      items: order.items,
      payments: order.payments,
      createdAt: order.createdAt,
      type: order.type,
    );
  }

  factory LeadOrderModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'open';
    final status = OrderStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == statusStr.toLowerCase(),
      orElse: () => OrderStatus.open,
    );

    var rawItems = json['items'];
    List<OrderItem> itemsList = [];
    if (rawItems is List) {
      itemsList = rawItems
          .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    var rawPayments = json['order_payments'];
    List<OrderPayment> paymentsList = [];
    if (rawPayments is List) {
      paymentsList = rawPayments
          .map((p) => OrderPayment.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return LeadOrderModel(
      id: json['id']?.toString() ?? '',
      leadId: json['lead_id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? '',
      staffName: json['staff_name']?.toString() ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'].toString())
          : null,
      status: status,
      taxableAmount: (json['taxable_amount'] as num?)?.toDouble() ?? 0.0,
      discountType: json['discount_type']?.toString() ?? 'fixed',
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      totalDiscount: (json['total_discount'] as num?)?.toDouble() ?? 0.0,
      roundOff: json['round_off'] as bool? ?? false,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      items: itemsList,
      payments: paymentsList,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      type: json['type']?.toString() ?? 'order',
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'lead_id': leadId,
      'order_number': orderNumber,
      'staff_name': staffName,
      'date': date.toIso8601String().split('T')[0],
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'status': status.name,
      'taxable_amount': taxableAmount,
      'discount_type': discountType,
      'discount_value': discountValue,
      'total_discount': totalDiscount,
      'round_off': roundOff,
      'total_amount': totalAmount,
      'items': items.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'type': type,
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
}


