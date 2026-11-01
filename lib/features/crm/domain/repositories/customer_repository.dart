import '../entities/customer.dart';
import '../entities/customer_note.dart';

abstract class CustomerRepository {
  Future<List<Customer>> getCustomers({String? searchQuery, String? category, String? staffName});
  Future<Customer> getCustomerById(String id);
  Future<Customer> createCustomer(Customer customer);
  Future<Customer> updateCustomer(Customer customer);
  Future<void> deleteCustomer(String id);

  // Customer Notes
  Future<List<CustomerNote>> getCustomerNotes(String customerId);
  Future<CustomerNote> addCustomerNote(CustomerNote note);
  Future<void> deleteCustomerNote(String noteId);
}
