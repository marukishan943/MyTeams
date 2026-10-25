import 'package:flutter/material.dart';
import '../../domain/entities/lead_order.dart';

const Color _kPrimaryBlue = Color(0xFF3949AB);

class AddItemScreen extends StatefulWidget {
  final OrderItem? existingItem;

  const AddItemScreen({super.key, this.existingItem});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedProduct;
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  bool _showDescription = false;
  bool _isPercentageDiscount = false;

  final List<String> _products = [
    'Software License',
    'Consulting Services',
    'Implementation & Setup',
    'Annual Maintenance',
    'Custom Feature Development',
    'Training Session',
    'Hardware Equipment',
    'Cloud Hosting Plan',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _selectedProduct = item.product;
      _rateController.text = item.rate > 0 ? item.rate.toStringAsFixed(0) : '';
      _quantityController.text =
          item.quantity > 0 ? item.quantity.toStringAsFixed(0) : '1';
      _taxController.text =
          item.taxPercent > 0 ? item.taxPercent.toStringAsFixed(0) : '';
      _descriptionController.text = item.description;
      _showDescription = item.description.isNotEmpty;
      _discountController.text =
          item.discount > 0 ? item.discount.toStringAsFixed(0) : '';
      _isPercentageDiscount = item.isPercentageDiscount;
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    _quantityController.dispose();
    _taxController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  String? get _discountedRateText {
    final rate = double.tryParse(_rateController.text.trim());
    final discount = double.tryParse(_discountController.text.trim());
    if (rate == null || rate <= 0 || discount == null || discount <= 0) {
      return null;
    }

    double finalRate;
    if (_isPercentageDiscount) {
      finalRate = rate - (rate * discount / 100.0);
    } else {
      finalRate = rate - discount;
    }
    if (finalRate < 0) finalRate = 0;

    final formatted = finalRate.truncateToDouble() == finalRate
        ? finalRate.toStringAsFixed(0)
        : finalRate.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');

    return 'after disc. ₹$formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _kPrimaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Item',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product *
              _buildLabel('Product', required: true),
              const SizedBox(height: 6),
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFBDBDBD)),
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedProduct,
                  hint: Text(
                    'Please Select',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: Color(0xFF757575)),
                  items: _products.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(
                        p,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF212121),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedProduct = val),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Please select a product' : null,
                ),
              ),
              const SizedBox(height: 24),

              // Rate *
              _buildLabel('Rate', required: true),
              const SizedBox(height: 4),
              TextFormField(
                controller: _rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 16, color: Color(0xFF212121)),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '',
                  filled: false,
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: _kPrimaryBlue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Rate is required';
                  }
                  if (double.tryParse(val.trim()) == null) {
                    return 'Enter valid rate';
                  }
                  return null;
                },
              ),
              if (_discountedRateText != null) ...[
                const SizedBox(height: 6),
                Text(
                  _discountedRateText!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2E7D32), // Green color matching the screenshot
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Discount field with Dropdown (% / ₹) and Input
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildLabel('Discount'),
                  ),
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF9E9E9E)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<bool>(
                              value: _isPercentageDiscount,
                              items: const [
                                DropdownMenuItem(
                                  value: true,
                                  child: Text('%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                ),
                                DropdownMenuItem(
                                  value: false,
                                  child: Text('₹', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _isPercentageDiscount = val);
                                }
                              },
                              icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF616161)),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 42,
                          color: const Color(0xFF9E9E9E),
                        ),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: _discountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontSize: 16, color: Color(0xFF212121)),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: '',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quantity *
              _buildLabel('Quantity', required: true),
              const SizedBox(height: 4),
              TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 16, color: Color(0xFF212121)),
                decoration: InputDecoration(
                  hintText: '',
                  filled: false,
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: _kPrimaryBlue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Quantity is required';
                  }
                  final q = double.tryParse(val.trim());
                  if (q == null || q <= 0) {
                    return 'Enter valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Tax (%)
              _buildLabel('Tax (%)'),
              const SizedBox(height: 4),
              TextFormField(
                controller: _taxController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 16, color: Color(0xFF212121)),
                decoration: const InputDecoration(
                  hintText: '',
                  filled: false,
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kPrimaryBlue, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              const SizedBox(height: 28),

              // + Add Description
              GestureDetector(
                onTap: () {
                  setState(() => _showDescription = !_showDescription);
                },
                child: Row(
                  children: [
                    Icon(
                      _showDescription
                          ? Icons.remove_circle
                          : Icons.add_circle,
                      color: _kPrimaryBlue,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _showDescription ? 'Remove Description' : 'Add Description',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _kPrimaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showDescription) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Enter item description...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: _kPrimaryBlue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
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
          child: ElevatedButton(
            onPressed: _saveItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF757575),
          fontWeight: FontWeight.w400,
        ),
        children: required
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]
            : null,
      ),
    );
  }

  void _saveItem() {
    if (!_formKey.currentState!.validate()) return;

    final item = OrderItem(
      id: widget.existingItem?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      product: _selectedProduct ?? 'Product',
      rate: double.tryParse(_rateController.text.trim()) ?? 0.0,
      quantity: double.tryParse(_quantityController.text.trim()) ?? 1.0,
      discount: double.tryParse(_discountController.text.trim()) ?? 0.0,
      isPercentageDiscount: _isPercentageDiscount,
      taxPercent: double.tryParse(_taxController.text.trim()) ?? 0.0,
      description: _descriptionController.text.trim(),
    );

    Navigator.pop(context, item);
  }
}
