import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/interactive_scanner_modal.dart';
import '../../widgets/digital_receipt_dialog.dart';

class SmartCartTab extends StatelessWidget {
  final Function(int)? onNavigate;

  const SmartCartTab({super.key, this.onNavigate});

  void _handleCheckout(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final wallet = Provider.of<WalletProvider>(context, listen: false);
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);

    if (cart.items.isEmpty) return;

    if (wallet.balance < cart.totalAmount) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.dangerColor),
              SizedBox(width: 8),
              Expanded(
                child: Text('Insufficient Balance'),
              ),
            ],
          ),
          content: Text(
            'Your cart total is ${CurrencyFormatter.format(cart.totalAmount)}, but your current offline wallet balance is only ${CurrencyFormatter.format(wallet.balance)}.\n\nPlease fund your wallet to complete self-checkout.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (onNavigate != null) onNavigate!(0); // Back to Home
              },
              child: const Text('Fund Wallet'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Self-Checkout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items in Cart: ${cart.totalItemCount} items'),
            const SizedBox(height: 8),
            Text(
              'Total Amount: ${CurrencyFormatter.format(cart.totalAmount)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 12),
            const Text(
              'Payment will be debited instantly from your offline wallet, and an Exit Pass QR Code will be issued.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pay & Generate Exit Pass'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final txn = await cart.checkout(
        userId: auth.currentUser!.userId!,
        merchantId: 1, // Gwagwalada Supermarket
        walletProvider: wallet,
      );

      if (txn != null) {
        await txProvider.loadUserTransactions(auth.currentUser!.userId!);
        if (context.mounted) {
          DigitalReceiptDialog.show(context, txn);
        }
      } else if (context.mounted && cart.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cart.errorMessage!),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final wallet = Provider.of<WalletProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Shopping Cart'),
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: AppTheme.dangerColor),
              tooltip: 'Clear Cart',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text('Are you sure you want to remove all items from your cart?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && user != null) {
                  await cart.clearCart(user.userId!);
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Store & Running total header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white.withAlpha(15) : Colors.grey.withAlpha(30),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gwagwalada Supermarket',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'Store ID: GWAG-001 • In-Store Self-Checkout',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryGreen.withAlpha(80)),
                  ),
                  child: Text(
                    '${cart.totalItemCount} Items',
                    style: const TextStyle(
                      color: AppTheme.primaryGreenLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items list or Empty state
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              size: 64,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Your Smart Cart is Empty',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Walk down any aisle and scan the QR code on any product to add it to your cart and see live prices.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final scanned = await InteractiveScannerModal.show(
                                context,
                                title: 'Scan Product to Add',
                                prompt: 'Scan shelf QR code',
                                scanTarget: 'product',
                              );
                              if (scanned != null && user != null && context.mounted) {
                                await cart.scanAndAddToCart(
                                  userId: user.userId!,
                                  qrCode: scanned,
                                );
                              }
                            },
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scan Product QR'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      final prod = item.product;

                      return CustomCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.shopping_bag_outlined,
                                color: AppTheme.primaryGreen,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prod?.productName ?? 'Supermarket Item',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${CurrencyFormatter.format(prod?.price ?? 0)} each',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Subtotal: ${CurrencyFormatter.format(item.totalPrice)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Quantity Controls
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? Colors.white.withAlpha(15) : Colors.grey.withAlpha(40),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    onPressed: () {
                                      if (user != null && item.cartId != null) {
                                        cart.updateQuantity(item.cartId!, item.quantity - 1, user.userId!);
                                      }
                                    },
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    onPressed: () {
                                      if (user != null && item.cartId != null) {
                                        cart.updateQuantity(item.cartId!, item.quantity + 1, user.userId!);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Running Total & Checkout Bar
          if (cart.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'RUNNING CART TOTAL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(cart.totalAmount),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Wallet Balance',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            Text(
                              CurrencyFormatter.format(wallet.balance),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: wallet.balance >= cart.totalAmount
                                    ? AppTheme.successColor
                                    : AppTheme.dangerColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final scanned = await InteractiveScannerModal.show(
                                context,
                                title: 'Scan Another Item',
                                prompt: 'Scan shelf QR code',
                                scanTarget: 'product',
                              );
                              if (scanned != null && user != null && context.mounted) {
                                await cart.scanAndAddToCart(
                                  userId: user.userId!,
                                  qrCode: scanned,
                                );
                              }
                            },
                            icon: const Icon(Icons.qr_code_scanner, size: 18),
                            label: const Text('+ Scan More'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleCheckout(context),
                            icon: const Icon(Icons.lock_outline, size: 18),
                            label: const Text('Self-Checkout'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
