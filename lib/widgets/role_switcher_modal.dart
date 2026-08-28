import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class RoleSwitcherModal extends StatelessWidget {
  const RoleSwitcherModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const RoleSwitcherModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Switch Active Role / View',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Seamlessly switch between consumer shopping, store management, and exit security.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Option 1: Consumer Mode
          _buildRoleOption(
            context: context,
            title: 'Customer / Shopper Mode',
            subtitle: 'Scan shelf QR codes, smart cart, preloaded wallet, exit receipt pass.',
            icon: Icons.shopping_bag,
            color: AppTheme.primaryGreen,
            isSelected: auth.currentRole == UserRole.consumer,
            onTap: () async {
              Navigator.pop(context);
              if (auth.currentRole != UserRole.consumer) {
                await auth.selectDemoUser(1);
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/consumer');
                }
              }
            },
          ),
          const SizedBox(height: 10),

          // Option 2: Merchant Mode
          _buildRoleOption(
            context: context,
            title: 'Store Merchant Mode',
            subtitle: 'Revenue dashboard, product QR studio, POS terminal, bank transfers.',
            icon: Icons.store,
            color: const Color(0xFF6366F1),
            isSelected: auth.currentRole == UserRole.merchant,
            onTap: () async {
              Navigator.pop(context);
              if (auth.currentRole != UserRole.merchant) {
                await auth.selectDemoMerchant(1);
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/merchant');
                }
              }
            },
          ),
          const SizedBox(height: 10),

          // Option 3: Exit Gate Security Officer
          _buildRoleOption(
            context: context,
            title: 'Exit Gate Security Checkpoint',
            subtitle: 'Scan and validate customer checkout receipts at store exit doors.',
            icon: Icons.security,
            color: AppTheme.accentGold,
            isSelected: auth.currentRole == UserRole.security,
            onTap: () {
              Navigator.pop(context);
              if (auth.currentRole != UserRole.security) {
                auth.switchRole(UserRole.security);
                Navigator.pushReplacementNamed(context, '/security');
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRoleOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withAlpha(20)
              : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }
}
