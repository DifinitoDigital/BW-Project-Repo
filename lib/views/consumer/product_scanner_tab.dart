import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/interactive_scanner_modal.dart';

class ProductScannerTab extends StatefulWidget {
  final Function(int)? onNavigate;

  const ProductScannerTab({super.key, this.onNavigate});

  @override
  State<ProductScannerTab> createState() => _ProductScannerTabState();
}

class _ProductScannerTabState extends State<ProductScannerTab> {
  ProductModel? _scannedProduct;
  int _selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).loadProducts();
    });
  }

  void _triggerScan() async {
    final scanned = await InteractiveScannerModal.show(
      context,
      title: 'Scan Shelf Product QR',
      prompt: 'Point at product label or choose shelf item',
      scanTarget: 'product',
    );

    if (scanned != null && mounted) {
      final inv = Provider.of<InventoryProvider>(context, listen: false);
      final product = inv.allProductsRaw.firstWhere(
        (p) => p.qrCodeValue.toLowerCase() == scanned.toLowerCase(),
        orElse: () => inv.allProductsRaw.first,
      );

      setState(() {
        _scannedProduct = product;
        _selectedQuantity = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final inv = Provider.of<InventoryProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Scanner & Shelf Explorer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryGreen),
            tooltip: 'Launch Camera Scanner',
            onPressed: _triggerScan,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Launch Scanner Card
          CustomCard(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner, color: AppTheme.primaryGreenLight, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Scan Supermarket Product QR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Point your device camera at the QR code on any product shelf in Gwagwalada Supermarket.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _triggerScan,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Open QR Scanner'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Scanned Product Details Card (if scanned)
          if (_scannedProduct != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryGreen, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withAlpha(30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _scannedProduct!.category,
                          style: const TextStyle(
                            color: AppTheme.primaryGreenLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        'QR: ${_scannedProduct!.qrCodeValue}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _scannedProduct!.productName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _scannedProduct!.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        CurrencyFormatter.format(_scannedProduct!.price),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      Text(
                        'Stock: ${_scannedProduct!.stockQuantity} units available',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quantity to add:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _selectedQuantity > 1
                                ? () => setState(() => _selectedQuantity--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$_selectedQuantity',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _selectedQuantity++),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (auth.currentUser != null) {
                              final messenger = ScaffoldMessenger.of(context);
                              await cart.addProductToCart(
                                auth.currentUser!.userId!,
                                _scannedProduct!,
                                quantity: _selectedQuantity,
                              );
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Added $_selectedQuantity x "${_scannedProduct!.productName}" to Smart Cart!'),
                                  backgroundColor: AppTheme.primaryGreen,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: Text('Add to Cart (${CurrencyFormatter.format(_scannedProduct!.price * _selectedQuantity)})'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // In-Store Supermarket Shelf Catalog
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Store Products',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${inv.allProductsRaw.length} Items',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: inv.categories.map((cat) {
                final isSelected = inv.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryGreen.withAlpha(40),
                    checkmarkColor: AppTheme.primaryGreen,
                    onSelected: (selected) {
                      inv.setCategory(cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Product List Cards
          ...inv.products.map((p) {
            return CustomCard(
              margin: const EdgeInsets.only(bottom: 8),
              onTap: () {
                setState(() {
                  _scannedProduct = p;
                  _selectedQuantity = 1;
                });
              },
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '${p.category} • QR: ${p.qrCodeValue}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                        Text(
                          CurrencyFormatter.format(p.price),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_shopping_cart, color: AppTheme.primaryGreen),
                    tooltip: 'Add to Cart',
                    onPressed: () async {
                      if (auth.currentUser != null) {
                        await cart.addProductToCart(auth.currentUser!.userId!, p, quantity: 1);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added "${p.productName}" to Smart Cart!'),
                              backgroundColor: AppTheme.primaryGreen,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      }
                    },
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
