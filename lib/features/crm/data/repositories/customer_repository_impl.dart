import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_data_source.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;

  CustomerRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Customer>> getCustomers({String? searchQuery, String? category, String? staffName}) async {
    return await remoteDataSource.getCustomers(
      searchQuery: searchQuery,
      category: category,
      staffName: staffName,
    );
  }

  @override
  Future<Customer> getCustomerById(String id) async {
    return await remoteDataSource.getCustomerById(id);
  }

  @override
  Future<Customer> createCustomer(Customer customer) async {
    final model = CustomerModel.fromEntity(customer);
    return await remoteDataSource.createCustomer(model);
  }

  @override
  Future<Customer> updateCustomer(Customer customer) async {
    final model = CustomerModel.fromEntity(customer);
    return await remoteDataSource.updateCustomer(model);
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await remoteDataSource.deleteCustomer(id);
  }
}
