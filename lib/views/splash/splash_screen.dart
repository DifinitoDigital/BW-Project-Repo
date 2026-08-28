import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  String _statusText = 'Initializing local offline database...';

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animController.forward();
    _startStartupSequence();
  }

  void _startStartupSequence() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() {
        _statusText = 'Loading Gwagwalada retail catalog...';
      });
    }

    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() {
        _statusText = 'Securing offline cryptographic ledger...';
      });
    }

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentRole == UserRole.consumer && auth.currentUser != null) {
        Navigator.pushReplacementNamed(context, '/consumer');
      } else if (auth.currentRole == UserRole.merchant && auth.currentMerchant != null) {
        Navigator.pushReplacementNamed(context, '/merchant');
      } else if (auth.currentRole == UserRole.security) {
        Navigator.pushReplacementNamed(context, '/security');
      } else {
        Navigator.pushReplacementNamed(context, '/consumer');
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF032216), // Deep Forest Emerald
              Color(0xFF021B12), // Dark Slate
              Color(0xFF0B192C), // Deep Midnight
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top subtle badge
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accentGold.withAlpha(80), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded, size: 14, color: AppTheme.accentGold),
                        SizedBox(width: 6),
                        Text(
                          '100% Offline Architecture • Gwagwalada FCT',
                          style: TextStyle(
                            color: AppTheme.accentGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Central Brand Icon & Titles
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Logo Icon Box with Glowing Gradient
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryGreen, Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withAlpha(120),
                                blurRadius: 35,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: AppTheme.accentGold.withAlpha(50),
                                blurRadius: 20,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.qr_code_2_rounded,
                                size: 68,
                                color: Colors.white,
                              ),
                              Positioned(
                                right: 18,
                                bottom: 18,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.accentGold,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.shopping_cart_rounded,
                                    size: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Brand Name
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(text: 'SmartRetail '),
                            TextSpan(
                              text: 'Pay',
                              style: TextStyle(
                                color: AppTheme.accentGold,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'QR Code-Based Smart Retail Payment System',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withAlpha(200),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        'Self-Checkout • Instant Wallet • Exit Security',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryGreenLight.withAlpha(220),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Progress & Status
              Padding(
                padding: const EdgeInsets.only(bottom: 28.0, left: 24, right: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Loading Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 160,
                          height: 3.5,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.white.withAlpha(25),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Dynamic Status Text
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _statusText,
                          key: ValueKey<String>(_statusText),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withAlpha(160),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Footer version & security note
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 12, color: Colors.white.withAlpha(100)),
                          const SizedBox(width: 4),
                          Text(
                            'Encrypted Local SQLite Ledger • v1.0.0',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withAlpha(100),
                              letterSpacing: 0.2,
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
        ),
      ),
    );
  }
}
