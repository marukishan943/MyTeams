import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_enums.dart';
import '../bloc/lead_detail_bloc.dart';
import '../bloc/lead_detail_event.dart';
import '../bloc/lead_detail_state.dart';
import '../widgets/crm_ui_constants.dart';
import '../widgets/crm_form_components.dart';

class EditLeadScreen extends StatefulWidget {
  final Lead lead;

  const EditLeadScreen({super.key, required this.lead});

  @override
  State<EditLeadScreen> createState() => _EditLeadScreenState();
}

class _EditLeadScreenState extends State<EditLeadScreen> {
  late DateTime _selectedDate;
  late LeadSource _selectedSource;
  late LeadStage _selectedStage;
  late int _rating;
  late final TextEditingController _nameController;
  late final TextEditingController _companyController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _titleController;
  late final TextEditingController _valueController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.lead.date;
    _selectedSource = widget.lead.source;
    _selectedStage = widget.lead.stage;
    _rating = widget.lead.rating;
    _nameController = TextEditingController(text: widget.lead.name);
    _companyController = TextEditingController(text: widget.lead.company);
    _phoneController = TextEditingController(text: widget.lead.phone);
    _emailController = TextEditingController(text: widget.lead.email);
    _titleController = TextEditingController(text: widget.lead.title);
    _valueController = TextEditingController(
      text: widget.lead.value > 0 ? widget.lead.value.toString() : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _titleController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeadDetailBloc, LeadDetailState>(
      listener: (context, state) {
        if (state is LeadDetailOperationSuccess) {
          setState(() => _isSaving = false);
          Navigator.pop(context);
        } else if (state is LeadDetailError) {
          setState(() => _isSaving = false);
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
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Edit Lead',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Contact Information
              _buildSectionWrapper(
                title: 'Contact Details',
                icon: Icons.person_outline,
                children: [
                  CrmTextField(
                    controller: _nameController,
                    label: 'Contact Name',
                    hint: 'e.g. John Doe',
                    required: true,
                    prefixIcon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),
                  CrmTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'e.g. 9876543210',
                    required: true,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: 16),
                  CrmTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'e.g. name@company.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),
                  CrmTextField(
                    controller: _companyController,
                    label: 'Company Name',
                    hint: 'e.g. Acme Corp',
                    prefixIcon: Icons.business_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 2: Pipeline & Stage Details
              _buildSectionWrapper(
                title: 'Lead Pipeline',
                icon: Icons.tune_rounded,
                children: [
                  // Stage selection chips
                  const Text(
                    'Lead Stage',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CrmStyles.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LeadStage.values.map((stage) {
                      final isSelected = _selectedStage == stage;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedStage = stage),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? stage.color : stage.backgroundColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: stage.color.withOpacity(isSelected ? 1.0 : 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(Icons.check, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                stage.displayName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : stage.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Source selection chips
                  const Text(
                    'Lead Source',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CrmStyles.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LeadSource.values.map((source) {
                      final isSelected = _selectedSource == source;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSource = source),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? CrmStyles.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? CrmStyles.primary : CrmStyles.border,
                              width: 1.5,
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
                  const SizedBox(height: 20),

                  // Date Picker Card
                  const Text(
                    'Lead Date',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CrmStyles.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
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
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: CrmStyles.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Rating Section
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

              // Section 3: Commercial & Scope
              _buildSectionWrapper(
                title: 'Commercial & Scope',
                icon: Icons.currency_rupee_rounded,
                children: [
                  CrmTextField(
                    controller: _titleController,
                    label: 'Requirement / Title',
                    hint: 'e.g. Solar rooftop 10kW',
                    prefixIcon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 16),
                  CrmTextField(
                    controller: _valueController,
                    label: 'Estimated Value (₹)',
                    hint: 'e.g. 50000',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.currency_rupee_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
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
            label: 'Save Changes',
            icon: Icons.check,
            isLoading: _isSaving,
            onPressed: _save,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionWrapper({
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: CrmStyles.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() {
    setState(() => _isSaving = true);
    context.read<LeadDetailBloc>().add(
          UpdateLeadStageEvent(widget.lead.id, {
            'staffName': widget.lead.staffName,
            'name': _nameController.text.trim().isEmpty
                ? widget.lead.name
                : _nameController.text.trim(),
            'company': _companyController.text.trim(),
            'phone': _phoneController.text.trim().isEmpty
                ? widget.lead.phone
                : _phoneController.text.trim(),
            'email': _emailController.text.trim(),
            'website': widget.lead.website,
            'gst': widget.lead.gst,
            'territory': widget.lead.territory,
            'address': widget.lead.address,
            'city': widget.lead.city,
            'state': widget.lead.state,
            'pincode': widget.lead.pincode,
            'country': widget.lead.country,
            'date': _selectedDate,
            'source': _selectedSource,
            'stage': _selectedStage,
            'rating': _rating,
            'title': _titleController.text.trim(),
            'value': double.tryParse(_valueController.text.trim()) ??
                widget.lead.value,
            'note': widget.lead.note,
            'isClosed': widget.lead.isClosed,
          }),
        );
  }
}
