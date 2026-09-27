import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String customerNumber;
  final String staffName;
  final String name;
  final String company;
  final String phone;
  final String email;
  final String website;
  final String category; // 'Retailer', 'Distributor', 'Other'
  final String status; // 'Active', 'Inactive'
  final String gst;
  final String territory;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final List<String> visitImages;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.customerNumber,
    this.staffName = '',
    required this.name,
    this.company = '',
    required this.phone,
    this.email = '',
    this.website = '',
    this.category = 'Retailer',
    this.status = 'Active',
    this.gst = '',
    this.territory = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.country = 'India',
    this.visitImages = const [],
    this.createdBy = 'ISUN BEVERAGES',
    required this.createdAt,
    required this.updatedAt,
  });

  Customer copyWith({
    String? id,
    String? customerNumber,
    String? staffName,
    String? name,
    String? company,
    String? phone,
    String? email,
    String? website,
    String? category,
    String? status,
    String? gst,
    String? territory,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? country,
    List<String>? visitImages,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      customerNumber: customerNumber ?? this.customerNumber,
      staffName: staffName ?? this.staffName,
      name: name ?? this.name,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      category: category ?? this.category,
      status: status ?? this.status,
      gst: gst ?? this.gst,
      territory: territory ?? this.territory,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      visitImages: visitImages ?? this.visitImages,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerNumber,
        staffName,
        name,
        company,
        phone,
        email,
        website,
        category,
        status,
        gst,
        territory,
        address,
        city,
        state,
        pincode,
        country,
        visitImages,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
