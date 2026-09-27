import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/lead_enums.dart';
import '../bloc/lead_bloc.dart';
import '../bloc/lead_event.dart';
import '../bloc/lead_state.dart';

const Color _kPrimaryBlue = Color(0xFF3949AB);

class LeadImageData {
  final String path;
  final Uint8List bytes;

  LeadImageData({required this.path, required this.bytes});
}

class AddLeadScreen extends StatefulWidget {
  const AddLeadScreen({super.key});

  @override
  State<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends State<AddLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0; // 0 = Contact, 1 = Lead

  // ─── Contact step fields ────────────────────────────────────────────
  String _selectedStaff = 'Bhavin Prajapati';
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController(text: '+91');
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _gstController = TextEditingController();
  String _selectedTerritory = 'METODA';
  bool _showAddressDetails = false;
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');

  // ─── Lead step fields ──────────────────────────────────────────────
  DateTime _selectedDate = DateTime.now();
  LeadSource _selectedSource = LeadSource.call;
  LeadStage _selectedStage = LeadStage.newLead;
  int _rating = 0;
  final _titleController = TextEditingController();
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();
  bool _showNoteField = false;

  final ImagePicker _picker = ImagePicker();
  final List<LeadImageData> _selectedVisitImages = [];

  final List<String> _staffList = [
    'Bhavin Prajapati',
    'Mehul Ajagya',
    'Kishan Maru',
    'Rahul Sharma',
  ];

  final List<String> _territoryList = [
    'METODA',
    'AHMEDABAD',
    'RAJKOT',
    'GONDAL',
    'SURAT',
    'VADODARA',
    'BHAVNAGAR',
    'PETLAD',
  ];

  @override
  void initState() {
    super.initState();
    _retrieveLostData();
  }

  /// Recover photos if Android OS killed the activity while camera was active
  Future<void> _retrieveLostData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) return;
      if (response.file != null) {
        final bytes = await response.file!.readAsBytes();
        if (mounted) {
          setState(() {
            _selectedVisitImages.add(LeadImageData(
              path: response.file!.path,
              bytes: bytes,
            ));
          });
        }
      }
    } catch (_) {}
  }

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
    _titleController.dispose();
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeadBloc, LeadState>(
      listener: (context, state) {
        if (state is LeadOperationSuccess) {
          context.pop();
        } else if (state is LeadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
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
            'Add Lead',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Column(
          children: [
            // Step indicator
            _buildStepIndicator(),
            // Form content
            Expanded(
              child: Form(
                key: _formKey,
                child: _currentStep == 0
                    ? _buildContactStep()
                    : _buildLeadStep(),
              ),
            ),
            // Bottom button
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // ─── Step Indicator ────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      child: Row(
        children: [
          _buildStepCircle(0, 'Contact'),
          Expanded(
            child: Container(
              height: 3,
              color: _currentStep >= 1
                  ? _kPrimaryBlue
                  : const Color(0xFFDCDCDC),
            ),
          ),
          _buildStepCircle(1, 'Lead'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    return GestureDetector(
      onTap: () {
        if (step == 0) {
          setState(() => _currentStep = 0);
        } else if (_formKey.currentState?.validate() ?? false) {
          setState(() => _currentStep = 1);
        }
      },
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? _kPrimaryBlue : const Color(0xFFBDBDBD),
              border: isCurrent
                  ? Border.all(color: _kPrimaryBlue.withOpacity(0.3), width: 4)
                  : null,
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent ? _kPrimaryBlue : const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Contact Step ──────────────────────────────────────────────────
  Widget _buildContactStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Staff dropdown
          _buildLabel('Staff'),
          _buildDropdown(
            value: _selectedStaff,
            items: _staffList,
            onChanged: (val) => setState(() => _selectedStaff = val!),
          ),
          const SizedBox(height: 16),

          // Name
          _buildLabel('Name', required: true),
          _buildUnderlineField(
            controller: _nameController,
            hint: 'Enter name',
            suffixIcon: Icons.person_outline,
            validator: (val) =>
                val == null || val.isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),

          // Company
          _buildLabel('Company'),
          _buildUnderlineField(
            controller: _companyController,
            hint: 'Enter company name',
          ),
          const SizedBox(height: 16),

          // Phone
          _buildLabel('Phone', required: true),
          _buildUnderlineField(
            controller: _phoneController,
            hint: '+911234567891',
            suffixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (val) =>
                val == null || val.length < 5 ? 'Phone is required' : null,
          ),
          const SizedBox(height: 16),

          // Email
          _buildLabel('Email'),
          _buildUnderlineField(
            controller: _emailController,
            hint: 'Enter email',
            suffixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Website
          _buildLabel('Website'),
          _buildUnderlineField(
            controller: _websiteController,
            hint: 'www.example.com',
            suffixIcon: Icons.language,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),

          // GST
          _buildLabel('GST'),
          _buildUnderlineField(
            controller: _gstController,
            hint: 'Enter GST number',
          ),
          const SizedBox(height: 16),

          // Territory
          _buildLabel('Territory'),
          _buildDropdown(
            value: _selectedTerritory,
            items: _territoryList,
            onChanged: (val) => setState(() => _selectedTerritory = val!),
          ),
          const SizedBox(height: 24),

          // Address Details (Expandable)
          const Divider(height: 1, color: Color(0xFFE8EAF6)),
          InkWell(
            onTap: () =>
                setState(() => _showAddressDetails = !_showAddressDetails),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Icon(
                    _showAddressDetails ? Icons.remove_circle : Icons.add_circle,
                    color: _kPrimaryBlue,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Address Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _kPrimaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showAddressDetails) ...[
            const Divider(height: 1, color: Color(0xFFE8EAF6)),
            const SizedBox(height: 12),
            _buildLabel('Address'),
            _buildUnderlineField(
              controller: _addressController,
              hint: 'Street address',
            ),
            const SizedBox(height: 12),
            _buildLabel('City'),
            _buildUnderlineField(
              controller: _cityController,
              hint: 'City',
            ),
            const SizedBox(height: 12),
            _buildLabel('State'),
            _buildUnderlineField(
              controller: _stateController,
              hint: 'State',
            ),
            const SizedBox(height: 12),
            _buildLabel('Pincode'),
            _buildUnderlineField(
              controller: _pincodeController,
              hint: 'Pincode',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _buildLabel('Country'),
            _buildUnderlineField(
              controller: _countryController,
              hint: 'Country',
            ),
          ],
          const SizedBox(height: 24),

          // Additional Detail
          const Divider(height: 1, color: Color(0xFFE8EAF6)),
          const SizedBox(height: 16),
          const Text(
            'ADDITIONAL DETAIL',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Visit Image',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 8),
          _buildImageThumbnailsRow(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Lead Step ─────────────────────────────────────────────────────
  Widget _buildLeadStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date
          _buildLabel('Date'),
          GestureDetector(
            onTap: _selectDate,
            child: AbsorbPointer(
              child: _buildUnderlineField(
                controller: TextEditingController(
                  text: DateFormat('dd-MMM-yyyy').format(_selectedDate),
                ),
                suffixIcon: Icons.calendar_month,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Source
          _buildLabel('Source'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: LeadSource.values.map((source) {
                final isSelected = _selectedSource == source;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(source.displayName),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedSource = source),
                    selectedColor: _kPrimaryBlue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF424242),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    backgroundColor: const Color(0xFFF5F5F5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(
                        color: isSelected
                            ? _kPrimaryBlue
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Stage
          _buildLabel('Stage'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: LeadStage.values.map((stage) {
                final isSelected = _selectedStage == stage;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedStage = stage),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? stage.color
                            : stage.backgroundColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: stage.color.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        stage.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : stage.color,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Rating
          _buildLabel('Rating'),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _rating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: index < _rating
                        ? const Color(0xFFFFC107)
                        : Colors.grey[400],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Divider
          const Divider(height: 1, color: Color(0xFFE8EAF6)),
          const SizedBox(height: 16),

          // Title + Add Note
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Title',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _kPrimaryBlue,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showNoteField = !_showNoteField),
                child: Text(
                  'Add Note',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _kPrimaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildUnderlineField(
            controller: _titleController,
            hint: 'Enter title',
          ),
          const SizedBox(height: 16),

          // Value
          _buildLabel('Value'),
          _buildUnderlineField(
            controller: _valueController,
            hint: 'Enter value',
            keyboardType: TextInputType.number,
          ),

          // Note (conditional)
          if (_showNoteField) ...[
            const SizedBox(height: 16),
            _buildLabel('Note'),
            _buildUnderlineField(
              controller: _noteController,
              hint: 'Add a note...',
              maxLines: 3,
            ),
          ],
          const SizedBox(height: 24),

          // Visit Image section
          _buildLabel('Visit Image'),
          const SizedBox(height: 8),
          _buildImageThumbnailsRow(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildImageThumbnailsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildImagePicker(),
          ..._selectedVisitImages.asMap().entries.map((entry) {
            final index = entry.key;
            final image = entry.value;
            return Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  margin: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      image.bytes,
                      fit: BoxFit.cover,
                      cacheWidth: 300,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _selectedVisitImages.removeAt(index)),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFBDBDBD)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.add_a_photo_outlined,
          size: 28,
          color: Color(0xFF757575),
        ),
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    final outerContext = context;
    final source = await showModalBottomSheet<ImageSource>(
      context: outerContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: _kPrimaryBlue),
                  title: const Text('Take Photo (Camera)'),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: _kPrimaryBlue),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (source != null && mounted) {
      await _pickImage(source);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
      );
      if (picked != null) {
        // Read bytes immediately — works on all Android versions (scoped storage safe)
        final bytes = await picked.readAsBytes();
        if (mounted) {
          setState(() {
            _selectedVisitImages.add(LeadImageData(
              path: picked.path,
              bytes: bytes,
            ));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: $e')),
        );
      }
    }
  }

  // ─── Shared Widgets ────────────────────────────────────────────────
  Widget _buildLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF9E9E9E),
            fontWeight: FontWeight.w400,
          ),
          children: required
              ? [
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  Widget _buildUnderlineField({
    TextEditingController? controller,
    String? hint,
    IconData? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF212121),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 15,
          color: Colors.grey[400],
          fontWeight: FontWeight.w400,
        ),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: Colors.grey[400], size: 22)
            : null,
        filled: false,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _kPrimaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF212121),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF757575)),
      ),
    );
  }

  // ─── Bottom Button ─────────────────────────────────────────────────
  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _currentStep == 0 ? _goToNextStep : _saveLead,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: _currentStep == 0
              ? const Text('Next')
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, size: 20),
                    SizedBox(width: 8),
                    Text('Save'),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────
  void _goToNextStep() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _currentStep = 1);
    }
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kPrimaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveLead() {
    final leadData = {
      'staffName': _selectedStaff,
      'name': _nameController.text.trim(),
      'company': _companyController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'website': _websiteController.text.trim(),
      'gst': _gstController.text.trim(),
      'territory': _selectedTerritory,
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'country': _countryController.text.trim(),
      'date': _selectedDate,
      'source': _selectedSource,
      'stage': _selectedStage,
      'rating': _rating,
      'title': _titleController.text.trim(),
      'value': double.tryParse(_valueController.text.trim()) ?? 0.0,
      'note': _noteController.text.trim(),
      'visitImages': _selectedVisitImages.map((e) => e.path).toList(),
    };

    context.read<LeadBloc>().add(CreateLeadEvent(leadData));
  }
}
