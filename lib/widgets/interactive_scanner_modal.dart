import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../data/seed_data.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class InteractiveScannerModal extends StatefulWidget {
  final String title;
  final String prompt;
  final String scanTarget; // 'product', 'consumer', 'receipt'

  const InteractiveScannerModal({
    super.key,
    this.title = 'Scan QR Code',
    this.prompt = 'Align QR code inside the frame to scan',
    this.scanTarget = 'product',
  });

  static Future<String?> show(
    BuildContext context, {
    String title = 'Scan QR Code',
    String prompt = 'Align QR code inside the frame',
    String scanTarget = 'product',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InteractiveScannerModal(
        title: title,
        prompt: prompt,
        scanTarget: scanTarget,
      ),
    );
  }

  @override
  State<InteractiveScannerModal> createState() => _InteractiveScannerModalState();
}

class _InteractiveScannerModalState extends State<InteractiveScannerModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _manualInputController = TextEditingController();
  MobileScannerController? _scannerController;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
      _tabController.addListener(() {
        if (_tabController.index == 0) {
          _scannerController?.start();
        } else {
          _scannerController?.stop();
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _manualInputController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        _hasScanned = true;
        _scannerController?.stop();
        Navigator.pop(context, barcode.rawValue);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 45,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(80),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.prompt,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Tabs: Camera vs Quick Shelf Selector / Manual Input
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryGreen,
            tabs: const [
              Tab(icon: Icon(Icons.qr_code_scanner), text: 'Camera Scan'),
              Tab(icon: Icon(Icons.touch_app), text: 'Quick Shelf / Code'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Camera Scanner
                _buildCameraTab(),

                // Tab 2: Quick Shelf Product Selector / Manual code
                _buildQuickSelectorTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraTab() {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64, color: AppTheme.primaryGreen),
              const SizedBox(height: 16),
              const Text(
                'Live Camera Scanner',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Live camera scanner is optimized for Android/iOS mobile devices. On Windows Desktop, use the "Quick Shelf / Code" tab to test all retail items and receipts instantly!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Switch to Quick Shelf / Code'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        if (_scannerController != null)
          MobileScanner(
            controller: _scannerController!,
            onDetect: _onDetect,
          ),
        // Overlay viewfinder
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.primaryGreenLight, width: 3),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        Positioned(
          bottom: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(160),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Scanning live QR Code...',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSelectorTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Manual input box
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualInputController,
                    decoration: InputDecoration(
                      hintText: widget.scanTarget == 'product'
                          ? 'Enter QR Code (e.g. PROD-GWAG-001)'
                          : widget.scanTarget == 'receipt'
                              ? 'Enter Receipt Code (e.g. RCP-EXIT-...)'
                              : 'Enter Consumer Wallet ID (e.g. 1)',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final text = _manualInputController.text.trim();
                    if (text.isNotEmpty) {
                      Navigator.pop(context, text);
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (widget.scanTarget == 'product') ...[
          const Text(
            'Gwagwalada Supermarket Shelf Items (Tap to simulate scan):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...SeedData.initialProducts.map((prod) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen.withAlpha(30),
                  child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryGreen),
                ),
                title: Text(
                  prod.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  '${CurrencyFormatter.format(prod.price)} • QR: ${prod.qrCodeValue}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.qr_code, color: AppTheme.primaryGreen),
                onTap: () => Navigator.pop(context, prod.qrCodeValue),
              ),
            );
          }),
        ] else if (widget.scanTarget == 'receipt') ...[
          const Text(
            'Demo Exit Receipts for Testing Security Scanner:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: AppTheme.primaryGreen),
              title: const Text('Sample Verified Receipt'),
              subtitle: const Text('RCP-GWAG-8947291 (Paid ₦8,300)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, 'RCP-GWAG-8947291'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: AppTheme.accentGold),
              title: const Text('Sample Unverified Receipt'),
              subtitle: const Text('TXN-GWAG-8947293 (Paid ₦14,500)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, 'TXN-GWAG-8947293'),
            ),
          ),
        ] else if (widget.scanTarget == 'consumer') ...[
          const Text(
            'Sample Consumer QR Codes (Tap to scan customer):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...SeedData.initialUsers.map((u) {
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen.withAlpha(30),
                  child: Text(u.fullName[0], style: const TextStyle(color: AppTheme.primaryGreen)),
                ),
                title: Text(u.fullName),
                subtitle: Text('User ID: ${u.userId} • Phone: ${u.phoneNumber}'),
                trailing: const Icon(Icons.qr_code),
                onTap: () => Navigator.pop(context, 'USER-${u.userId}'),
              ),
            );
          }),
        ],
      ],
    );
  }
}
