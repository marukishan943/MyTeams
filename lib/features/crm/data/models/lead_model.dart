import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_enums.dart';

class LeadModel extends Lead {
  const LeadModel({
    required super.id,
    required super.leadNumber,
    super.staffName,
    required super.name,
    super.company,
    required super.phone,
    super.email,
    super.website,
    super.gst,
    super.territory,
    super.address,
    super.city,
    super.state,
    super.pincode,
    super.country,
    required super.date,
    super.source,
    super.stage,
    super.rating,
    super.title,
    super.value,
    super.note,
    super.visitImages,
    super.isClosed,
    required super.createdAt,
    required super.updatedAt,
  });

  factory LeadModel.fromEntity(Lead lead) {
    return LeadModel(
      id: lead.id,
      leadNumber: lead.leadNumber,
      staffName: lead.staffName,
      name: lead.name,
      company: lead.company,
      phone: lead.phone,
      email: lead.email,
      website: lead.website,
      gst: lead.gst,
      territory: lead.territory,
      address: lead.address,
      city: lead.city,
      state: lead.state,
      pincode: lead.pincode,
      country: lead.country,
      date: lead.date,
      source: lead.source,
      stage: lead.stage,
      rating: lead.rating,
      title: lead.title,
      value: lead.value,
      note: lead.note,
      visitImages: lead.visitImages,
      isClosed: lead.isClosed,
      createdAt: lead.createdAt,
      updatedAt: lead.updatedAt,
    );
  }

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    // Parse source
    final sourceStr = json['source'] as String? ?? 'call';
    final source = LeadSource.values.firstWhere(
      (e) => e.name.toLowerCase() == sourceStr.toLowerCase(),
      orElse: () => LeadSource.call,
    );

    // Parse stage
    final stageStr = json['stage'] as String? ?? 'newLead';
    final stage = LeadStage.values.firstWhere(
      (e) => e.name.toLowerCase() == stageStr.toLowerCase(),
      orElse: () => LeadStage.newLead,
    );

    return LeadModel(
      id: json['id']?.toString() ?? '',
      leadNumber: json['lead_number']?.toString() ?? '',
      staffName: json['staff_name']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      gst: json['gst']?.toString() ?? '',
      territory: json['territory']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      country: json['country']?.toString() ?? 'India',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      source: source,
      stage: stage,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      note: json['note']?.toString() ?? '',
      visitImages: (json['visit_images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isClosed: json['is_closed'] as bool? ?? false,
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
      'lead_number': leadNumber,
      'staff_name': staffName,
      'name': name,
      'company': company,
      'phone': phone,
      'email': email,
      'website': website,
      'gst': gst,
      'territory': territory,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
      'date': date.toIso8601String(),
      'source': source.name,
      'stage': stage.name,
      'rating': rating,
      'title': title,
      'value': value,
      'note': note,
      'visit_images': visitImages,
      'is_closed': isClosed,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
}
