import '../../domain/entities/customer.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    required super.customerNumber,
    super.staffName,
    required super.name,
    super.company,
    required super.phone,
    super.email,
    super.website,
    super.category,
    super.status,
    super.gst,
    super.territory,
    super.address,
    super.city,
    super.state,
    super.pincode,
    super.country,
    super.visitImages,
    super.createdBy,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CustomerModel.fromEntity(Customer customer) {
    return CustomerModel(
      id: customer.id,
      customerNumber: customer.customerNumber,
      staffName: customer.staffName,
      name: customer.name,
      company: customer.company,
      phone: customer.phone,
      email: customer.email,
      website: customer.website,
      category: customer.category,
      status: customer.status,
      gst: customer.gst,
      territory: customer.territory,
      address: customer.address,
      city: customer.city,
      state: customer.state,
      pincode: customer.pincode,
      country: customer.country,
      visitImages: customer.visitImages,
      createdBy: customer.createdBy,
      createdAt: customer.createdAt,
      updatedAt: customer.updatedAt,
    );
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString() ?? '',
      customerNumber: json['customer_number']?.toString() ?? '',
      staffName: json['staff_name']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Retailer',
      status: json['status']?.toString() ?? 'Active',
      gst: json['gst']?.toString() ?? '',
      territory: json['territory']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      country: json['country']?.toString() ?? 'India',
      visitImages: (json['visit_images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdBy: json['created_by']?.toString() ?? 'ISUN BEVERAGES',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'customer_number': customerNumber,
      'staff_name': staffName,
      'name': name,
      'company': company,
      'phone': phone,
      'email': email,
      'website': website,
      'category': category,
      'status': status,
      'gst': gst,
      'territory': territory,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
      'visit_images': visitImages,
      'created_by': createdBy,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
}
