import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_visit.dart';
import '../bloc/lead_detail_bloc.dart';
import '../bloc/lead_detail_event.dart';
import 'add_visit_screen.dart';

const Color _kPrimaryBlue = Color(0xFF3949AB);

class VisitDetailScreen extends StatefulWidget {
  final Lead lead;
  final LeadVisit visit;

  const VisitDetailScreen({
    super.key,
    required this.lead,
    required this.visit,
  });

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  late LeadVisit _currentVisit;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentVisit = widget.visit;
  }

  Future<void> _attachImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        setState(() => _isSaving = true);
        
        final newImages = List<String>.from(_currentVisit.images)..add(picked.path);
        
        final updatedVisit = LeadVisit(
          id: _currentVisit.id,
          leadId: _currentVisit.leadId,
          staffName: _currentVisit.staffName,
          purpose: _currentVisit.purpose,
          date: _currentVisit.date,
          startTime: _currentVisit.startTime,
          endTime: _currentVisit.endTime,
          subject: _currentVisit.subject,
          description: _currentVisit.description,
          images: newImages,
          createdAt: _currentVisit.createdAt,
        );

        if (mounted) {
          context.read<LeadDetailBloc>().add(UpdateVisitEvent(updatedVisit));
          setState(() {
            _currentVisit = updatedVisit;
            _isSaving = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortId = _currentVisit.id.length >= 4
        ? _currentVisit.id.substring(_currentVisit.id.length - 4)
        : _currentVisit.id;

    final dateStr = DateFormat('dd MMM yyyy').format(_currentVisit.date);
    final timeStr = DateFormat('hh:mm a').format(_currentVisit.startTime);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _kPrimaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Visit #$shortId',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) => AlertDialog(
                  title: const Text('Cancel Visit'),
                  content: const Text('Are you sure you want to cancel (delete) this visit?'),
                  actions: [
                    TextButton(
                      child: const Text('No'),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                    TextButton(
                      child: const Text('Yes', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        Navigator.pop(dialogContext); // Close dialog
                        context.read<LeadDetailBloc>().add(
                              DeleteVisitEvent(_currentVisit.id, widget.lead.id),
                            );
                        Navigator.pop(context); // Go back to lead detail
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () async {
              final updatedVisit = await Navigator.push<LeadVisit>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddVisitScreen(lead: widget.lead, visit: _currentVisit),
                ),
              );
              if (updatedVisit != null && mounted) {
                context.read<LeadDetailBloc>().add(UpdateVisitEvent(updatedVisit));
                setState(() {
                  _currentVisit = updatedVisit;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: const Color(0xFFE8EAF6),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            dateStr == DateFormat('dd MMM yyyy').format(DateTime.now())
                                ? 'TODAY'
                                : dateStr.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeStr,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: _kPrimaryBlue),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _currentVisit.purpose.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          color: _kPrimaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pending',
                        style: TextStyle(
                          color: _kPrimaryBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _currentVisit.staffName,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_alt, color: Colors.black87),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.lead.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.lead.territory.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.lead.territory,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (widget.lead.phone.isNotEmpty) ...[
                        _buildCircleActionButton(
                          icon: Icons.phone_outlined,
                          onTap: () => _makeCall(widget.lead.phone),
                        ),
                        const SizedBox(width: 12),
                        _buildCircleActionButton(
                          icon: Icons.chat_outlined,
                          onTap: () => _openWhatsApp(widget.lead.phone),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ADDITIONAL DETAIL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Visit Image *',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isSaving)
                    const Center(child: CircularProgressIndicator())
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ..._currentVisit.images.map((path) => _buildImageThumbnail(path)),
                        _buildAddImageButton(),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _kPrimaryBlue, width: 1.5),
        ),
        child: Icon(icon, color: _kPrimaryBlue, size: 20),
      ),
    );
  }

  Widget _buildImageThumbnail(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(path),
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 90,
          height: 90,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: () => _attachImage(ImageSource.camera),
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          color: Colors.white,
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            color: _kPrimaryBlue,
            size: 32,
          ),
        ),
      ),
    );
  }
}
