import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/customer.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';

const Color _kPrimaryBlue = Color(0xFF3949AB);

class CustomerImageData {
  final String path;
  final Uint8List bytes;

  CustomerImageData({required this.path, required this.bytes});
}

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedStaff = 'Mehul Ajagya';
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  String _selectedCategory = 'Retailer'; // 'Retailer', 'Distributor', 'Other'
  final _gstController = TextEditingController();
  String _selectedTerritory = 'Please Select';

  bool _showAddressDetails = false;
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');

  final ImagePicker _picker = ImagePicker();
  final List<CustomerImageData> _selectedVisitImages = [];

  final List<String> _staffList = [
    'Mehul Ajagya',
    'Bhavin Prajapati',
    'Prashantkumar',
    'Kishan Maru',
    'Rahul Sharma',
  ];

  final List<String> _territoryList = [
    'Please Select',
    'PAL/RAVKI/LODHIKA',
    'METODA',
    'RAJKOT',
    'GONDAL',
    'AHMEDABAD',
    'SURAT',
    'VADODARA',
    'BHAVNAGAR',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceDialog() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Image Source',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: _kPrimaryBlue),
                  title: const Text('Take Photo (Camera)'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: _kPrimaryBlue),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source != null && mounted) {
      try {
        final picked = await _picker.pickImage(source: source);
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          if (mounted) {
            setState(() {
              _selectedVisitImages.add(CustomerImageData(
                path: picked.path,
                bytes: bytes,
              ));
            });
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pick image: $e')),
          );
        }
      }
    }
  }

  void _saveCustomer() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final rawPhone = _phoneController.text.trim();
    final formattedPhone = rawPhone.startsWith('+91') ? rawPhone : '+91$rawPhone';

    final customer = Customer(
      id: '',
      customerNumber: '',
      staffName: _selectedStaff,
      name: _nameController.text.trim(),
      company: _companyController.text.trim(),
      phone: formattedPhone,
      email: _emailController.text.trim(),
      website: _websiteController.text.trim(),
      category: _selectedCategory,
      gst: _gstController.text.trim(),
      territory: _selectedTerritory == 'Please Select' ? '' : _selectedTerritory,
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      country: _countryController.text.trim(),
      visitImages: _selectedVisitImages.map((e) => e.path).toList(),
      createdBy: 'ISUN BEVERAGES',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    context.read<CustomerBloc>().add(CreateCustomerEvent(customer));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerBloc, CustomerState>(
      listener: (context, state) {
        if (state is CustomerOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          context.pop();
        } else if (state is CustomerError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: _kPrimaryBlue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Add Customer',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Staff ───────────────────────────────────────────────
                _buildLabel('Staff'),
                const SizedBox(height: 4),
                _buildBoxedDropdown(
                  value: _selectedStaff,
                  items: _staffList,
                  onChanged: (val) => setState(() => _selectedStaff = val!),
                ),
                const SizedBox(height: 16),

                // ─── Name * ──────────────────────────────────────────────
                _buildLabel('Name', required: true),
                _buildUnderlineField(
                  controller: _nameController,
                  suffixIcon: Icons.perm_contact_calendar_outlined,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                // ─── Company ─────────────────────────────────────────────
                _buildLabel('Company'),
                _buildUnderlineField(
                  controller: _companyController,
                ),
                const SizedBox(height: 16),

                // ─── Phone * ─────────────────────────────────────────────
                _buildLabel('Phone', required: true),
                _buildUnderlineField(
                  controller: _phoneController,
                  prefixText: '+91 ',
                  suffixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Phone is required';
                    }
                    if (val.trim().length < 5) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ─── Email ───────────────────────────────────────────────
                _buildLabel('Email'),
                _buildUnderlineField(
                  controller: _emailController,
                  suffixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // ─── Website ─────────────────────────────────────────────
                _buildLabel('Website'),
                _buildUnderlineField(
                  controller: _websiteController,
                  suffixIcon: Icons.public,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),

                // ─── Category ────────────────────────────────────────────
                _buildLabel('Category'),
                const SizedBox(height: 6),
                _buildCategorySelector(),
                const SizedBox(height: 16),

                // ─── GST ─────────────────────────────────────────────────
                _buildLabel('GST'),
                _buildUnderlineField(
                  controller: _gstController,
                ),
                const SizedBox(height: 16),

                // ─── Territory ───────────────────────────────────────────
                _buildLabel('Territory'),
                const SizedBox(height: 4),
                _buildBoxedDropdown(
                  value: _selectedTerritory,
                  items: _territoryList,
                  onChanged: (val) => setState(() => _selectedTerritory = val!),
                ),
                const SizedBox(height: 20),

                // ─── Address Details (Expandable) ────────────────────────
                Container(
                  color: const Color(0xFFF6F8FA),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: InkWell(
                    onTap: () => setState(() => _showAddressDetails = !_showAddressDetails),
                    child: Row(
                      children: [
                        Icon(
                          _showAddressDetails ? Icons.remove_circle : Icons.add_circle,
                          color: _kPrimaryBlue,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Address Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kPrimaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showAddressDetails) ...[
                  const SizedBox(height: 12),
                  _buildLabel('Address'),
                  _buildUnderlineField(controller: _addressController, hint: 'Street address'),
                  const SizedBox(height: 12),
                  _buildLabel('City'),
                  _buildUnderlineField(controller: _cityController, hint: 'City'),
                  const SizedBox(height: 12),
                  _buildLabel('State'),
                  _buildUnderlineField(controller: _stateController, hint: 'State'),
                  const SizedBox(height: 12),
                  _buildLabel('Pincode'),
                  _buildUnderlineField(
                    controller: _pincodeController,
                    hint: 'Pincode',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _buildLabel('Country'),
                  _buildUnderlineField(controller: _countryController, hint: 'Country'),
                ],
                const SizedBox(height: 24),

                // ─── ADDITIONAL DETAIL ───────────────────────────────────
                const Text(
                  'ADDITIONAL DETAIL',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF212121),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Visit Image',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(height: 10),
                _buildImagePickerRow(),
                const SizedBox(height: 36),

                // ─── Save Button ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimaryBlue,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _saveCustomer,
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _buildLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF757575),
          fontWeight: FontWeight.w500,
        ),
        children: required
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildUnderlineField({
    required TextEditingController controller,
    String? hint,
    String? prefixText,
    IconData? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF212121)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
        prefixText: prefixText,
        prefixStyle: const TextStyle(fontSize: 15, color: Color(0xFF212121), fontWeight: FontWeight.w500),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: const Color(0xFF757575), size: 22)
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFD6D6D6)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _kPrimaryBlue, width: 2),
        ),
      ),
    );
  }

  Widget _buildBoxedDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFBDBDBD)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF757575)),
          style: const TextStyle(fontSize: 15, color: Color(0xFF212121)),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Row(
      children: [
        _buildCategoryChip('Retailer'),
        const SizedBox(width: 10),
        _buildCategoryChip('Distributor'),
        const SizedBox(width: 10),
        _buildCategoryChip('Other'),
      ],
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;

    Color bg;
    Color textColor;

    if (isSelected) {
      bg = _kPrimaryBlue;
      textColor = Colors.white;
    } else {
      if (label == 'Distributor') {
        bg = const Color(0xFFE0F7FA);
        textColor = const Color(0xFF00838F);
      } else if (label == 'Other') {
        bg = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
      } else {
        bg = const Color(0xFFE1F5FE);
        textColor = const Color(0xFF0288D1);
      }
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Square Box with +
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
              ),
              child: const Icon(
                Icons.add,
                size: 36,
                color: _kPrimaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Thumbnails
          ..._selectedVisitImages.asMap().entries.map((entry) {
            final index = entry.key;
            final img = entry.value;
            return Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.memory(img.bytes, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedVisitImages.removeAt(index)),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
