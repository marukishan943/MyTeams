import '../../domain/entities/customer_note.dart';

class CustomerNoteModel extends CustomerNote {
  const CustomerNoteModel({
    required super.id,
    required super.customerId,
    required super.content,
    required super.createdAt,
  });

  factory CustomerNoteModel.fromEntity(CustomerNote note) {
    return CustomerNoteModel(
      id: note.id,
      customerId: note.customerId,
      content: note.content,
      createdAt: note.createdAt,
    );
  }

  factory CustomerNoteModel.fromJson(Map<String, dynamic> json) {
    return CustomerNoteModel(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'customer_id': customerId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
}
