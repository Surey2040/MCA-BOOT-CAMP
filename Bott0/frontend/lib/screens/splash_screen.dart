import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOutSine),
      ),
    );

    _controller.forward();
    
    // Repeat glow breathing effect
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.repeat(reverse: true);
      }
    });

    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for the animation to look premium and let session load
    await Future.delayed(const Duration(milliseconds: 2800));
    
    if (!mounted) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.checkTokenExpiry();
    
    if (!mounted) return;
    
    if (auth.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0xFF1E180A), // Extremely subtle dark gold glow in the center
              Color(0xFF0C0C0C), // Deep premium black at edges
            ],
            center: Alignment.center,
            radius: 1.2,
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  // Premium gold/orange corner accent glows
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryGold.withOpacity(0.04 * _glowAnimation.value),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGold.withOpacity(0.04 * _glowAnimation.value),
                            blurRadius: 100,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -120,
                    left: -120,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentOrange.withOpacity(0.04 * _glowAnimation.value),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentOrange.withOpacity(0.04 * _glowAnimation.value),
                            blurRadius: 120,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Main Content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Shawarma Illustration with scaling, fading, and glowing
                        Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGold.withOpacity(0.12 * _glowAnimation.value),
                                    blurRadius: 40,
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: AppTheme.accentOrange.withOpacity(0.08 * _glowAnimation.value),
                                    blurRadius: 60,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: CustomPaint(
                                painter: ShawarmaPainter(glowValue: _glowAnimation.value),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Booto Shawarma Brand Title
                        Opacity(
                          opacity: _fadeAnimation.value,
                          child: Column(
                            children: [
                              Text(
                                'BOOTO SHAWARMA',
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      color: AppTheme.primaryGold,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4.0,
                                      fontSize: 30,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.8),
                                          offset: const Offset(0, 3),
                                          blurRadius: 6,
                                        ),
                                        Shadow(
                                          color: AppTheme.primaryGold.withOpacity(0.3 * _glowAnimation.value),
                                          offset: const Offset(0, 0),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 80,
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppTheme.primaryGold,
                                      AppTheme.accentOrange,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'POS & ORDER SYSTEM',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.6),
                                  letterSpacing: 3.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 64),
                        
                        // Circular Loading Animation
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color.lerp(AppTheme.primaryGold, AppTheme.accentOrange, _glowAnimation.value)!,
                                ),
                              ),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryGold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Footer Version / Info
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'PRODUCTION READY • V1.0.0',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class ShawarmaPainter extends CustomPainter {
  final double glowValue;

  ShawarmaPainter({required this.glowValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw Background glowing rings
    final ringPaint = Paint()
      ..color = AppTheme.primaryGold.withOpacity(0.04 * glowValue)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.45, ringPaint);
    
    ringPaint.color = AppTheme.accentOrange.withOpacity(0.02 * glowValue);
    canvas.drawCircle(center, size.width * 0.5, ringPaint);

    final width = size.width;
    final height = size.height;
    
    // Draw Shawarma wrapping paper (trapezoid at the bottom)
    final wrapPath = Path()
      ..moveTo(width * 0.38, height * 0.55)
      ..lineTo(width * 0.62, height * 0.55)
      ..lineTo(width * 0.56, height * 0.88)
      ..lineTo(width * 0.44, height * 0.88)
      ..close();

    final wrapGradient = LinearGradient(
      colors: [
        const Color(0xFFC5A028),
        AppTheme.primaryGold,
        const Color(0xFFECCB5F),
        const Color(0xFFC5A028),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final wrapPaint = Paint()
      ..shader = wrapGradient.createShader(Rect.fromLTWH(width * 0.38, height * 0.55, width * 0.24, height * 0.33))
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(wrapPath, wrapPaint);

    // Draw wrapper overlay fold lines
    final foldPaint = Paint()
      ..color = const Color(0xFF886A14).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawLine(Offset(width * 0.38, height * 0.55), Offset(width * 0.47, height * 0.88), foldPaint);
    canvas.drawLine(Offset(width * 0.62, height * 0.55), Offset(width * 0.53, height * 0.88), foldPaint);

    // Draw Shawarma Roll Bread (conical cylindrical body in middle)
    final breadPath = Path()
      ..moveTo(width * 0.36, height * 0.30)
      ..quadraticBezierTo(width * 0.5, height * 0.26, width * 0.64, height * 0.30)
      ..lineTo(width * 0.61, height * 0.57)
      ..quadraticBezierTo(width * 0.5, height * 0.61, width * 0.39, height * 0.57)
      ..close();

    final breadGradient = LinearGradient(
      colors: [
        const Color(0xFFE2A154),
        const Color(0xFFF9D18D),
        const Color(0xFFE2A154),
        const Color(0xFFB57022),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final breadPaint = Paint()
      ..shader = breadGradient.createShader(Rect.fromLTWH(width * 0.36, height * 0.26, width * 0.28, height * 0.35))
      ..style = PaintingStyle.fill;

    canvas.drawPath(breadPath, breadPaint);

    // Grill marks on bread
    final grillPaint = Paint()
      ..color = const Color(0xFF6B3A07).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(width * 0.42, height * 0.33), Offset(width * 0.48, height * 0.41), grillPaint);
    canvas.drawLine(Offset(width * 0.52, height * 0.32), Offset(width * 0.58, height * 0.40), grillPaint);
    canvas.drawLine(Offset(width * 0.40, height * 0.45), Offset(width * 0.47, height * 0.54), grillPaint);
    canvas.drawLine(Offset(width * 0.50, height * 0.44), Offset(width * 0.57, height * 0.53), grillPaint);

    // Draw Filling sticking out of the top (Lettuce, Chicken chunks, Sauce drops)
    final fillingPaint = Paint()..style = PaintingStyle.fill;

    // Green lettuce leaves
    fillingPaint.color = const Color(0xFF4CAF50);
    canvas.drawOval(Rect.fromLTWH(width * 0.37, height * 0.25, width * 0.08, height * 0.08), fillingPaint);
    canvas.drawOval(Rect.fromLTWH(width * 0.55, height * 0.24, width * 0.09, height * 0.07), fillingPaint);

    // Orange/Red spicy chicken chunks
    fillingPaint.color = AppTheme.accentOrange;
    final chunk1 = Path()
      ..moveTo(width * 0.45, height * 0.26)
      ..lineTo(width * 0.51, height * 0.20)
      ..lineTo(width * 0.49, height * 0.29)
      ..close();
    canvas.drawPath(chunk1, fillingPaint);

    fillingPaint.color = const Color(0xFFE65100);
    final chunk2 = Path()
      ..moveTo(width * 0.49, height * 0.24)
      ..lineTo(width * 0.56, height * 0.19)
      ..lineTo(width * 0.53, height * 0.28)
      ..close();
    canvas.drawPath(chunk2, fillingPaint);

    // Garlic mayonnaise sauce drop (white/cream)
    fillingPaint.color = Colors.white.withOpacity(0.95);
    canvas.drawOval(Rect.fromLTWH(width * 0.43, height * 0.28, width * 0.05, height * 0.06), fillingPaint);
    canvas.drawOval(Rect.fromLTWH(width * 0.52, height * 0.27, width * 0.06, height * 0.05), fillingPaint);

    // Red chilli sauce drizzle line
    final saucePaint = Paint()
      ..color = AppTheme.accentOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    final saucePath = Path()
      ..moveTo(width * 0.40, height * 0.32)
      ..quadraticBezierTo(width * 0.48, height * 0.36, width * 0.53, height * 0.31)
      ..quadraticBezierTo(width * 0.58, height * 0.27, width * 0.62, height * 0.33);
    canvas.drawPath(saucePath, saucePaint);

    // Draw Steam Waves rising from the top
    final steamPaint = Paint()
      ..color = AppTheme.primaryGold.withOpacity(0.25 * glowValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final steamPath1 = Path()
      ..moveTo(width * 0.45, height * 0.15)
      ..quadraticBezierTo(width * 0.43, height * 0.11, width * 0.46, height * 0.08)
      ..quadraticBezierTo(width * 0.49, height * 0.05, width * 0.45, height * 0.02);

    final steamPath2 = Path()
      ..moveTo(width * 0.53, height * 0.14)
      ..quadraticBezierTo(width * 0.55, height * 0.10, width * 0.51, height * 0.07)
      ..quadraticBezierTo(width * 0.48, height * 0.04, width * 0.52, height * 0.01);

    canvas.drawPath(steamPath1, steamPaint);
    canvas.drawPath(steamPath2, steamPaint);
  }

  @override
  bool shouldRepaint(covariant ShawarmaPainter oldDelegate) {
    return oldDelegate.glowValue != glowValue;
  }
}
