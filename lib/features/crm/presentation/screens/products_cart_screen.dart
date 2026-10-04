import 'package:flutter/material.dart';
import '../../domain/entities/lead_order.dart';

const Color _kPrimaryBlue = Color(0xFF2638B8);

class Product {
  final String id;
  final String name;
  final String subname;
  final String initials;
  final int stock;
  final double price;
  final bool isStockOut;

  const Product({
    required this.id,
    required this.name,
    required this.subname,
    required this.initials,
    required this.stock,
    required this.price,
    this.isStockOut = false,
  });
}

class ProductsCartScreen extends StatefulWidget {
  const ProductsCartScreen({super.key});

  @override
  State<ProductsCartScreen> createState() => _ProductsCartScreenState();
}

class _ProductsCartScreenState extends State<ProductsCartScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  
  // Mock data matching the screenshot
  final List<Product> _allProducts = [
    const Product(
      id: '1',
      name: 'TRANSPORT',
      subname: 'Stock Out',
      initials: 'TR',
      stock: -10,
      price: 0,
      isStockOut: true,
    ),
    const Product(
      id: '2',
      name: 'ZINC SPRAY 200ML',
      subname: 'ZINC SPRAY',
      initials: 'ZS', // Will use image or initials
      stock: 2924,
      price: 112,
    ),
    const Product(
      id: '3',
      name: 'ZINC SPRAY 400ML',
      subname: 'ZINC SPRAY',
      initials: 'ZS',
      stock: 2980,
      price: 159,
    ),
    const Product(
      id: '4',
      name: 'ZINC SPRAY 500ML',
      subname: 'ZINC SPRAY',
      initials: 'ZS',
      stock: 2639,
      price: 177,
    ),
  ];

  List<Product> _filteredProducts = [];
  final Map<String, int> _cartQuantities = {};

  @override
  void initState() {
    super.initState();
    _filteredProducts = List.from(_allProducts);
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filteredProducts = _allProducts.where((p) => p.name.toLowerCase().contains(q)).toList();
      });
    });
  }

  int get _totalCartItems => _cartQuantities.values.fold(0, (sum, q) => sum + q);

  void _addItemsToInvoice() {
    final List<OrderItem> items = [];
    _cartQuantities.forEach((id, qty) {
      if (qty > 0) {
        final p = _allProducts.firstWhere((prod) => prod.id == id);
        items.add(OrderItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_${p.id}',
          product: p.name,
          quantity: qty.toDouble(),
          rate: p.price,
          taxPercent: 18, // Default tax or configurable
          description: p.subname,
        ));
      }
    });
    Navigator.pop(context, items);
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
          'Products',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredProducts.length,
              separatorBuilder: (context, index) => const Divider(height: 32),
              itemBuilder: (context, index) {
                final p = _filteredProducts[index];
                final qty = _cartQuantities[p.id] ?? 0;
                
                return Row(
                  children: [
                    // Icon / Image placeholder
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF6), // Light blue background
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        p.initials,
                        style: const TextStyle(color: _kPrimaryBlue, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 14, color: p.isStockOut ? Colors.red : Colors.grey),
                              const SizedBox(width: 4),
                              if (p.isStockOut)
                                const Text('Stock Out', style: TextStyle(color: Colors.red, fontSize: 12))
                              else
                                Text('${p.stock} | ₹${p.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Add Button / Stepper
                    if (qty == 0)
                      OutlinedButton(
                        onPressed: () {
                          setState(() => _cartQuantities[p.id] = 1);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _kPrimaryBlue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: const Size(80, 36),
                        ),
                        child: const Text('+ ADD', style: TextStyle(color: _kPrimaryBlue, fontWeight: FontWeight.bold)),
                      )
                    else
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(color: _kPrimaryBlue),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _cartQuantities[p.id] = qty - 1;
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Text('-', style: TextStyle(color: _kPrimaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                            Container(
                              width: 1,
                              color: _kPrimaryBlue,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(qty.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            Container(
                              width: 1,
                              color: _kPrimaryBlue,
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _cartQuantities[p.id] = qty + 1;
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Text('+', style: TextStyle(color: _kPrimaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _totalCartItems > 0
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
                ],
              ),
              child: ElevatedButton(
                onPressed: _addItemsToInvoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Add to Cart ($_totalCartItems)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          : null,
    );
  }
}
