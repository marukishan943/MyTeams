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
import '../widgets/crm_ui_constants.dart';
import '../widgets/crm_form_components.dart';

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
              backgroundColor: CrmStyles.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: CrmStyles.background,
        appBar: AppBar(
          backgroundColor: CrmStyles.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (_currentStep == 1) {
                setState(() => _currentStep = 0);
              } else {
                context.pop();
              }
            },
          ),
          title: Text(
            _currentStep == 0 ? 'New Lead: Contact' : 'New Lead: Details',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
        ),
        body: Column(
          children: [
            // Modern Step Progress Indicator
            _buildModernStepIndicator(),

            // Form Content
            Expanded(
              child: Form(
                key: _formKey,
                child: _currentStep == 0
                    ? _buildContactStep()
                    : _buildLeadStep(),
              ),
            ),

            // Pinned Bottom Action Button
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  // ─── Modern Stepper ────────────────────────────────────────────────
  Widget _buildModernStepIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: CrmStyles.border)),
      ),
      child: Row(
        children: [
          _buildStepItem(0, 'Contact Info', Icons.person_outline),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: _currentStep >= 1 ? CrmStyles.primary : CrmStyles.border,
            ),
          ),
          _buildStepItem(1, 'Lead Details', Icons.tune_rounded),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String label, IconData icon) {
    final bool isCompleted = _currentStep > step;
    final bool isActive = _currentStep == step;

    return GestureDetector(
      onTap: () {
        if (step == 0) {
          setState(() => _currentStep = 0);
        } else if (_formKey.currentState?.validate() ?? false) {
          setState(() => _currentStep = 1);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isActive
                  ? CrmStyles.primary
                  : isCompleted
                      ? CrmStyles.success
                      : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? CrmStyles.primary
                    : isCompleted
                        ? CrmStyles.success
                        : CrmStyles.border,
                width: 1.5,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Icon(
                      icon,
                      size: 15,
                      color: isActive ? Colors.white : CrmStyles.textMuted,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? CrmStyles.primary : CrmStyles.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 0: Contact Info ──────────────────────────────────────────
  Widget _buildContactStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Basic Information',
            icon: Icons.person_pin_outlined,
            children: [
              CrmDropdown<String>(
                label: 'Assigned Staff',
                value: _selectedStaff,
                items: _staffList,
                itemLabel: (s) => s,
                prefixIcon: Icons.badge_outlined,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedStaff = val);
                },
              ),
              const SizedBox(height: 16),
              CrmTextField(
                controller: _nameController,
                label: 'Lead Name',
                hint: 'e.g. Bhushan Golecha',
                required: true,
                prefixIcon: Icons.person_outline,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              CrmTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '+919876543210',
                required: true,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (val) =>
                    val == null || val.trim().length < 5 ? 'Valid phone number is required' : null,
              ),
              const SizedBox(height: 16),
              CrmTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'name@company.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              CrmTextField(
                controller: _companyController,
                label: 'Company Name',
                hint: 'e.g. Kalpa Power Pvt Ltd',
                prefixIcon: Icons.business_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSectionCard(
            title: 'Territory & Commercial',
            icon: Icons.map_outlined,
            children: [
              CrmDropdown<String>(
                label: 'Territory',
                value: _selectedTerritory,
                items: _territoryList,
                itemLabel: (t) => t,
                prefixIcon: Icons.location_city_outlined,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTerritory = val);
                },
              ),
              const SizedBox(height: 16),
              CrmTextField(
                controller: _websiteController,
                label: 'Website',
                hint: 'www.example.com',
                keyboardType: TextInputType.url,
                prefixIcon: Icons.language_outlined,
              ),
              const SizedBox(height: 16),
              CrmTextField(
                controller: _gstController,
                label: 'GST Number',
                hint: '24AAAAA0000A1Z5',
                prefixIcon: Icons.receipt_long_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Address Expandable Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(CrmStyles.radiusLarge),
              border: Border.all(color: CrmStyles.border),
              boxShadow: CrmStyles.cardShadow,
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _showAddressDetails = !_showAddressDetails),
                  borderRadius: BorderRadius.circular(CrmStyles.radiusLarge),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: CrmStyles.primary,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Address Details',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: CrmStyles.textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          _showAddressDetails
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: CrmStyles.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showAddressDetails) ...[
                  const Divider(height: 1, color: CrmStyles.borderLight),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CrmTextField(
                          controller: _addressController,
                          label: 'Street Address',
                          hint: 'Flat/Plot, Street Name',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: CrmTextField(
                                controller: _cityController,
                                label: 'City',
                                hint: 'e.g. Rajkot',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CrmTextField(
                                controller: _stateController,
                                label: 'State',
                                hint: 'e.g. Gujarat',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: CrmTextField(
                                controller: _pincodeController,
                                label: 'Pincode',
                                hint: '360001',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CrmTextField(
                                controller: _countryController,
                                label: 'Country',
                                hint: 'India',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── Step 1: Lead Details ──────────────────────────────────────────
  Widget _buildLeadStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Pipeline & Classification',
            icon: Icons.filter_alt_outlined,
            children: [
              // Lead Date
              const Text(
                'Date',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CrmStyles.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(CrmStyles.radiusMedium),
                    border: Border.all(color: CrmStyles.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: CrmStyles.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          DateFormat('dd-MMM-yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: CrmStyles.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: CrmStyles.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Lead Source
              const Text(
                'Source',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CrmStyles.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: LeadSource.values.map((source) {
                  final isSelected = _selectedSource == source;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSource = source),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? CrmStyles.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? CrmStyles.primary : CrmStyles.border,
                        ),
                      ),
                      child: Text(
                        source.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : CrmStyles.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Lead Stage
              const Text(
                'Stage',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CrmStyles.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: LeadStage.values.map((stage) {
                  final isSelected = _selectedStage == stage;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedStage = stage),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? stage.color : stage.backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: stage.color.withOpacity(isSelected ? 1.0 : 0.4),
                          width: 1.5,
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
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Rating
              const Text(
                'Lead Rating',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CrmStyles.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = starNum),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        starNum <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 36,
                        color: starNum <= _rating
                            ? const Color(0xFFFFB300)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSectionCard(
            title: 'Requirement & Commercials',
            icon: Icons.currency_rupee_rounded,
            children: [
              CrmTextField(
                controller: _titleController,
                label: 'Requirement Title',
                hint: 'e.g. 15HP Solar Pump System',
                prefixIcon: Icons.title_rounded,
              ),
              const SizedBox(height: 16),
              CrmTextField(
                controller: _valueController,
                label: 'Estimated Deal Value (₹)',
                hint: 'e.g. 250000',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.currency_rupee_rounded,
              ),
              const SizedBox(height: 16),
              CrmTextField(
                controller: _noteController,
                label: 'Initial Notes / Conversation',
                hint: 'Enter customer requirements or call discussion...',
                maxLines: 3,
                prefixIcon: Icons.note_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Visit Photos Card
          _buildSectionCard(
            title: 'Visit Photos & Attachments',
            icon: Icons.photo_camera_outlined,
            children: [
              _buildImageThumbnailsRow(),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CrmStyles.radiusLarge),
        border: Border.all(color: CrmStyles.border),
        boxShadow: CrmStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: CrmStyles.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: CrmStyles.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: CrmStyles.borderLight),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildImageThumbnailsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(CrmStyles.radiusMedium),
                border: Border.all(
                  color: CrmStyles.primary.withOpacity(0.4),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: CrmStyles.primary, size: 24),
                  SizedBox(height: 4),
                  Text(
                    'Add Photo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CrmStyles.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ..._selectedVisitImages.asMap().entries.map((entry) {
            final index = entry.key;
            final image = entry.value;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  margin: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(CrmStyles.radiusMedium),
                    border: Border.all(color: CrmStyles.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(CrmStyles.radiusMedium),
                    child: Image.memory(
                      image.bytes,
                      fit: BoxFit.cover,
                      cacheWidth: 250,
                    ),
                  ),
                ),
                Positioned(
                  top: -6,
                  right: -4,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedVisitImages.removeAt(index)),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
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

  Future<void> _showImageSourceDialog() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
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
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: CrmStyles.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: CrmStyles.primary),
                  title: const Text('Take Photo (Camera)'),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: CrmStyles.primary),
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
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
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

  Widget _buildBottomActionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: CrmStyles.border)),
      ),
      child: CrmPrimaryButton(
        label: _currentStep == 0 ? 'Next: Lead Details' : 'Create Lead',
        icon: _currentStep == 0 ? Icons.arrow_forward : Icons.check,
        onPressed: _currentStep == 0 ? _goToNextStep : _saveLead,
      ),
    );
  }

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
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: CrmStyles.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
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
