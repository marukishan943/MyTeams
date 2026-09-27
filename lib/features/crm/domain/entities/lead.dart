import 'package:equatable/equatable.dart';
import 'lead_enums.dart';

class Lead extends Equatable {
  final String id;
  final String leadNumber;
  final String staffName;
  final String name;
  final String company;
  final String phone;
  final String email;
  final String website;
  final String gst;
  final String territory;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final DateTime date;
  final LeadSource source;
  final LeadStage stage;
  final int rating;
  final String title;
  final double value;
  final String note;
  final List<String> visitImages;
  final bool isClosed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Lead({
    required this.id,
    required this.leadNumber,
    this.staffName = '',
    required this.name,
    this.company = '',
    required this.phone,
    this.email = '',
    this.website = '',
    this.gst = '',
    this.territory = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.country = 'India',
    required this.date,
    this.source = LeadSource.call,
    this.stage = LeadStage.newLead,
    this.rating = 0,
    this.title = '',
    this.value = 0.0,
    this.note = '',
    this.visitImages = const [],
    this.isClosed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Lead copyWith({
    String? id,
    String? leadNumber,
    String? staffName,
    String? name,
    String? company,
    String? phone,
    String? email,
    String? website,
    String? gst,
    String? territory,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? country,
    DateTime? date,
    LeadSource? source,
    LeadStage? stage,
    int? rating,
    String? title,
    double? value,
    String? note,
    List<String>? visitImages,
    bool? isClosed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Lead(
      id: id ?? this.id,
      leadNumber: leadNumber ?? this.leadNumber,
      staffName: staffName ?? this.staffName,
      name: name ?? this.name,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      gst: gst ?? this.gst,
      territory: territory ?? this.territory,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      date: date ?? this.date,
      source: source ?? this.source,
      stage: stage ?? this.stage,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      value: value ?? this.value,
      note: note ?? this.note,
      visitImages: visitImages ?? this.visitImages,
      isClosed: isClosed ?? this.isClosed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        leadNumber,
        staffName,
        name,
        company,
        phone,
        email,
        website,
        gst,
        territory,
        address,
        city,
        state,
        pincode,
        country,
        date,
        source,
        stage,
        rating,
        title,
        value,
        note,
        visitImages,
        isClosed,
        createdAt,
        updatedAt,
      ];
}
