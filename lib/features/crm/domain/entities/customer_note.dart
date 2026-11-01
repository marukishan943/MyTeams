import 'package:equatable/equatable.dart';

class CustomerNote extends Equatable {
  final String id;
  final String customerId;
  final String content;
  final DateTime createdAt;

  const CustomerNote({
    required this.id,
    required this.customerId,
    required this.content,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, customerId, content, createdAt];
}
