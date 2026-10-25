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
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: DropdownButtonFormField<String>(
                  value: _selectedProduct,
                  hint: Text(
                    'Select a product or service',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: Color(0xFF475569)),
                  items: _products.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              size: 18, color: _kPrimaryBlue),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              p,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedProduct = val),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Please select a product' : null,
                ),
              ),
              const SizedBox(height: 20),

              // Rate *
              _buildLabel('Rate', required: true),
              const SizedBox(height: 6),
              TextFormField(
                controller: _rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 14, right: 8),
                    child: Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: _kPrimaryBlue, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _discountedRateText!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Discount field with Dropdown (% / ₹) and Input
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildLabel('Discount'),
                  ),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      border: Border.all(
                          color: const Color(0xFFCBD5E1), width: 1.2),
                      borderRadius: BorderRadius.circular(8),
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
                                  child: Text('%',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                ),
                                DropdownMenuItem(
                                  value: false,
                                  child: Text('₹',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _isPercentageDiscount = val);
                                }
                              },
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  size: 18, color: Color(0xFF475569)),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 26,
                          color: const Color(0xFFCBD5E1),
                        ),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: _discountController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A)),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: '0',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quantity *
              _buildLabel('Quantity', required: true),
              const SizedBox(height: 6),
              TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: _kPrimaryBlue, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              const SizedBox(height: 20),

              // Tax (%)
              _buildLabel('Tax (%)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _taxController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  suffixIcon: const Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: Text(
                      '%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: _kPrimaryBlue, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),

              // + Add Description
              GestureDetector(
                onTap: () {
                  setState(() => _showDescription = !_showDescription);
                },
                child: Row(
                  children: [
                    Icon(
                      _showDescription
                          ? Icons.remove_circle_outline
                          : Icons.add_circle_outline,
                      color: _kPrimaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _showDescription ? 'Remove Description' : 'Add Description',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Enter item description...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFFCBD5E1), width: 1.2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFFCBD5E1), width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: _kPrimaryBlue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(14),
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
          fontSize: 13,
          color: Color(0xFF475569),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        children: required
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
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
