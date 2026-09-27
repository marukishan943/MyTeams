import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_enums.dart';
import '../bloc/lead_detail_bloc.dart';
import '../bloc/lead_detail_event.dart';
import '../bloc/lead_detail_state.dart';

const Color _kPrimaryBlue = Color(0xFF3949AB);

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
    _titleController = TextEditingController(text: widget.lead.title);
    _valueController = TextEditingController(
      text: widget.lead.value > 0 ? widget.lead.value.toString() : '',
    );
  }

  @override
  void dispose() {
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
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
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
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Edit Lead',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Date ────────────────────────────────────────────────
              _buildLabel('Date'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: _kPrimaryBlue, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('dd-MMM-yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 17,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ),
                      const Icon(Icons.calendar_month_outlined,
                          color: _kPrimaryBlue, size: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Source ──────────────────────────────────────────────
              _buildLabel('Source'),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: LeadSource.values.map((source) {
                    final isSelected = _selectedSource == source;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSource = source),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _kPrimaryBlue
                                : const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            source.displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF424242),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),

              // ── Stage ───────────────────────────────────────────────
              _buildLabel('Stage'),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: LeadStage.values.map((stage) {
                    final isSelected = _selectedStage == stage;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedStage = stage),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? stage.color
                                : stage.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: stage.color.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            stage.displayName,
                            style: TextStyle(
                              fontSize: 15,
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
              const SizedBox(height: 28),

              // ── Rating ──────────────────────────────────────────────
              _buildLabel('Rating'),
              const SizedBox(height: 10),
              Row(
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = index + 1),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        size: 44,
                        color: index < _rating
                            ? const Color(0xFFFFC107)
                            : Colors.grey[400],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),

              const Divider(color: Color(0xFFEEEEEE), height: 1),
              const SizedBox(height: 24),

              // ── Title ───────────────────────────────────────────────
              _buildLabel('Title'),
              const SizedBox(height: 4),
              TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 16, color: Color(0xFF212121)),
                decoration: const InputDecoration(
                  hintText: '',
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kPrimaryBlue, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 24),

              // ── Value ───────────────────────────────────────────────
              _buildLabel('Value'),
              const SizedBox(height: 4),
              TextField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16, color: Color(0xFF212121)),
                decoration: const InputDecoration(
                  hintText: '',
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kPrimaryBlue, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
        // ── Bottom Save Button ───────────────────────────────────────
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 12,
          ),
          color: Colors.white,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.check, size: 20),
              label: const Text(
                'Save',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF9E9E9E),
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _kPrimaryBlue),
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
            // Lead-info fields — keep original values
            'staffName': widget.lead.staffName,
            'name': widget.lead.name,
            'company': widget.lead.company,
            'phone': widget.lead.phone,
            'email': widget.lead.email,
            'website': widget.lead.website,
            'gst': widget.lead.gst,
            'territory': widget.lead.territory,
            'address': widget.lead.address,
            'city': widget.lead.city,
            'state': widget.lead.state,
            'pincode': widget.lead.pincode,
            'country': widget.lead.country,
            // Editable fields
            'date': _selectedDate,
            'source': _selectedSource,
            'stage': _selectedStage,
            'rating': _rating,
            'title': _titleController.text.trim(),
            'value': double.tryParse(_valueController.text.trim()) ?? widget.lead.value,
            'note': widget.lead.note,
            'isClosed': widget.lead.isClosed,
          }),
        );
  }
}
