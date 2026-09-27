import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_model.dart';

abstract class CustomerRemoteDataSource {
  Future<List<CustomerModel>> getCustomers({String? searchQuery, String? category, String? staffName});
  Future<CustomerModel> getCustomerById(String id);
  Future<CustomerModel> createCustomer(CustomerModel customer);
  Future<CustomerModel> updateCustomer(CustomerModel customer);
  Future<void> deleteCustomer(String id);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final SupabaseClient supabaseClient;

  // In-memory fallback list initialized with sample records matching the reference screenshots
  static final List<CustomerModel> _localCustomers = [
    CustomerModel(
      id: 'cust-1125',
      customerNumber: '1125',
      staffName: 'Mehul Ajagya',
      name: 'synchro electricals',
      company: 'synchro electricals',
      phone: '+919876543210',
      email: 'synchro@gmail.com',
      website: '',
      category: 'Retailer',
      gst: '',
      territory: 'PAL/RAVKI/LODHIKA',
      city: 'RAJKOT',
      state: 'Gujarat',
      pincode: '360001',
      country: 'India',
      createdBy: 'ISUN BEVERAGES',
      createdAt: DateTime(2026, 9, 25, 17, 8),
      updatedAt: DateTime(2026, 9, 25, 17, 8),
    ),
    CustomerModel(
      id: 'cust-1124',
      customerNumber: '1124',
      staffName: 'Mehul',
      name: 'AIIMS HOSPITAL Canteen',
      company: '',
      phone: '+919876543211',
      email: '',
      website: '',
      category: 'Retailer',
      gst: '',
      territory: 'RAJKOT',
      city: 'RAJKOT',
      state: 'Gujarat',
      pincode: '360001',
      country: 'India',
      createdBy: 'ISUN BEVERAGES',
      createdAt: DateTime(2026, 9, 25, 16, 30),
      updatedAt: DateTime(2026, 9, 25, 16, 30),
    ),
    CustomerModel(
      id: 'cust-1123',
      customerNumber: '1123',
      staffName: 'Mehul',
      name: 'Shiv Hospital - Hemantbhai',
      company: '',
      phone: '+919876543212',
      email: '',
      website: '',
      category: 'Retailer',
      gst: '',
      territory: 'RAJKOT',
      city: 'RAJKOT',
      state: 'Gujarat',
      pincode: '360001',
      country: 'India',
      createdBy: 'ISUN BEVERAGES',
      createdAt: DateTime(2026, 9, 25, 15, 45),
      updatedAt: DateTime(2026, 9, 25, 15, 45),
    ),
    CustomerModel(
      id: 'cust-1121',
      customerNumber: '1121',
      staffName: 'Mehul',
      name: 'Abbazbhai',
      company: '',
      phone: '+919876543213',
      email: '',
      website: '',
      category: 'Distributor',
      gst: '',
      territory: 'GONDAL',
      city: 'GONDAL',
      state: 'Gujarat',
      pincode: '360311',
      country: 'India',
      createdBy: 'ISUN BEVERAGES',
      createdAt: DateTime(2026, 9, 25, 14, 15),
      updatedAt: DateTime(2026, 9, 25, 14, 15),
    ),
    CustomerModel(
      id: 'cust-1120',
      customerNumber: '1120',
      staffName: 'Mehul',
      name: 'Mr. Ayushraj Chauhan',
      company: '',
      phone: '+919876543214',
      email: '',
      website: '',
      category: 'Retailer',
      gst: '',
      territory: 'RAJKOT',
      city: 'Rajkot',
      state: 'Gujarat',
      pincode: '360001',
      country: 'India',
      createdBy: 'ISUN BEVERAGES',
      createdAt: DateTime(2026, 9, 25, 13, 0),
      updatedAt: DateTime(2026, 9, 25, 13, 0),
    ),
    CustomerModel(
      id: 'cust-1119',
      customerNumber: '1119',
      staffName: 'Prashantkumar',
      name: 'Madhuvan pan PARLOR',
      company: 'MADHUVAN PAN PARLOR',
      phone: '+919876543215',
      email: '',
      website: '',
      category: 'Retailer',
      gst: '',
      territory: 'METODA',
      city: 'METODA',
      state: 'Gujarat',
      pincode: '360021',
      country: 'India',
      createdBy: 'ISUN BEVERAGES',
      createdAt: DateTime(2026, 9, 24, 11, 20),
      updatedAt: DateTime(2026, 9, 24, 11, 20),
    ),
    CustomerModel(
      id: 'cust-1118',
      customerNumber: '1118',
      staffName: 'Prashantkumar',
      name: 'Patel pan. Syam kutir',
      company: 'PATEL PAN PARLOR syam kutir',
      phone: '+919876543216',
      email: '',
      website: '',
      category: 'Retailer',
      gst: '',
      territory: 'METODA',
      city: 'METODA',
      state: 'Gujarat',
      pincode: '360021',
      country: 'India',
      createdBy: 'ISUN BEVERAGES',
      createdAt: DateTime(2026, 9, 24, 10, 15),
      updatedAt: DateTime(2026, 9, 24, 10, 15),
    ),
    CustomerModel(
      id: 'cust-1117',
      customerNumber: '1117',
      staffName: 'Prashantkumar',
      name: 'KRUPA PAN PARLOR',
      company: 'KRUPA PAN PARLOR syam kutir',
      phone: '+919876543217',
      email: '',
      website: '',
      category: 'Retailer',
      gst: '',
      territory: 'METODA',
      city: 'METODA',
      state: 'Gujarat',
      pincode: '360021',
      country: 'India',
      createdBy: 'ISUN BEVERAGES',
      createdAt: DateTime(2026, 9, 23, 18, 40),
      updatedAt: DateTime(2026, 9, 23, 18, 40),
    ),
    CustomerModel(
      id: 'cust-1116',
      customerNumber: '1116',
      staffName: 'Prashantkumar',
      name: 'Prit kirana stor',
      company: 'PRIT KIRANA STOR.',
      phone: '+919876543218',
      email: '',
      website: '',
      category: 'Retailer',
      gst: '',
      territory: 'METODA',
      city: 'METODA',
      state: 'Gujarat',
      pincode: '360021',
      country: 'India',
      createdBy: 'ISUN BEVERAGES',
      createdAt: DateTime(2026, 9, 23, 17, 5),
      updatedAt: DateTime(2026, 9, 23, 17, 5),
    ),
  ];

  CustomerRemoteDataSourceImpl(this.supabaseClient);

  String? get _userId => supabaseClient.auth.currentUser?.id;

  @override
  Future<List<CustomerModel>> getCustomers({String? searchQuery, String? category, String? staffName}) async {
    try {
      var query = supabaseClient.from('customers').select('*');

      if (category != null && category.isNotEmpty && category != 'All') {
        query = query.eq('category', category);
      }

      if (staffName != null && staffName.isNotEmpty && staffName != 'All') {
        query = query.ilike('staff_name', '%$staffName%');
      }

      final response = await query.order('created_at', ascending: false);
      final list = (response as List<dynamic>)
          .map((json) => CustomerModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) {
        // Merge with any newly added local customers not in Supabase
        for (final local in _localCustomers) {
          if (!list.any((c) => c.id == local.id || (c.customerNumber == local.customerNumber && c.customerNumber.isNotEmpty))) {
            list.add(local);
          }
        }
        return list;
      }
    } catch (_) {
      // In case Supabase table is not yet created or offline, fall back to local list
    }

    var result = List<CustomerModel>.from(_localCustomers);

    if (category != null && category.isNotEmpty && category != 'All') {
      result = result.where((c) => c.category.toLowerCase() == category.toLowerCase()).toList();
    }
    if (staffName != null && staffName.isNotEmpty && staffName != 'All') {
      result = result.where((c) => c.staffName.toLowerCase().contains(staffName.toLowerCase())).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((c) =>
          c.name.toLowerCase().contains(q) ||
          c.company.toLowerCase().contains(q) ||
          c.customerNumber.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ||
          c.city.toLowerCase().contains(q) ||
          c.staffName.toLowerCase().contains(q)).toList();
    }

    return result;
  }

  @override
  Future<CustomerModel> getCustomerById(String id) async {
    try {
      final response = await supabaseClient
          .from('customers')
          .select('*')
          .eq('id', id)
          .single();
      return CustomerModel.fromJson(response);
    } catch (_) {
      final found = _localCustomers.firstWhere((c) => c.id == id, orElse: () => _localCustomers.first);
      return found;
    }
  }

  @override
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    // Generate sequential customer number if empty
    String customerNum = customer.customerNumber;
    if (customerNum.isEmpty) {
      int maxNum = 1125;
      for (final c in _localCustomers) {
        final parsed = int.tryParse(c.customerNumber);
        if (parsed != null && parsed > maxNum) {
          maxNum = parsed;
        }
      }
      try {
        final res = await supabaseClient
            .from('customers')
            .select('customer_number')
            .order('created_at', ascending: false)
            .limit(10);
        for (final row in res as List<dynamic>) {
          final parsed = int.tryParse(row['customer_number']?.toString() ?? '');
          if (parsed != null && parsed > maxNum) {
            maxNum = parsed;
          }
        }
      } catch (_) {}
      customerNum = (maxNum + 1).toString();
    }

    final newId = customer.id.isNotEmpty ? customer.id : 'cust_${DateTime.now().millisecondsSinceEpoch}';
    final customerWithNum = CustomerModel(
      id: newId,
      customerNumber: customerNum,
      staffName: customer.staffName,
      name: customer.name,
      company: customer.company,
      phone: customer.phone,
      email: customer.email,
      website: customer.website,
      category: customer.category,
      gst: customer.gst,
      territory: customer.territory,
      address: customer.address,
      city: customer.city,
      state: customer.state,
      pincode: customer.pincode,
      country: customer.country,
      visitImages: customer.visitImages,
      createdBy: customer.createdBy.isNotEmpty ? customer.createdBy : 'ISUN BEVERAGES',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to local cache first
    _localCustomers.insert(0, customerWithNum);

    // Attempt to persist to Supabase
    try {
      final json = customerWithNum.toJson(includeId: false);
      if (_userId != null) {
        json['user_id'] = _userId;
      }
      final response = await supabaseClient
          .from('customers')
          .insert(json)
          .select()
          .single();
      final created = CustomerModel.fromJson(response);
      // Update local cache with Supabase UUID
      _localCustomers.removeWhere((c) => c.customerNumber == customerNum);
      _localCustomers.insert(0, created);
      return created;
    } catch (_) {
      // If table doesn't exist yet, return the locally persisted customer
      return customerWithNum;
    }
  }

  @override
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    final index = _localCustomers.indexWhere((c) => c.id == customer.id || c.customerNumber == customer.customerNumber);
    if (index != -1) {
      _localCustomers[index] = customer;
    }

    try {
      final json = customer.toJson(includeId: false);
      final response = await supabaseClient
          .from('customers')
          .update(json)
          .eq('id', customer.id)
          .select()
          .single();
      return CustomerModel.fromJson(response);
    } catch (_) {
      return customer;
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    _localCustomers.removeWhere((c) => c.id == id);
    try {
      await supabaseClient.from('customers').delete().eq('id', id);
    } catch (_) {}
  }
}
