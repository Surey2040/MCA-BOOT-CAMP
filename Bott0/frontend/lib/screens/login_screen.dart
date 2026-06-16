import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPinObscured = true;
  bool _rememberMe = false;
  late AnimationController _btnController;
  late Animation<double> _btnScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _btnScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.easeInOut),
    );

    // Populate saved PIN if Remember Me is enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.rememberMe) {
        setState(() {
          _pinController.text = auth.savedPin;
          _rememberMe = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    _btnController.forward().then((_) => _btnController.reverse());
    
    final pin = _pinController.text;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(pin, rememberMe: _rememberMe);
    
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Access Granted. Welcome!', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: AppTheme.statusReady,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  auth.errorMessage.isNotEmpty ? auth.errorMessage : 'Incorrect PIN. Try again.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.statusCancelled,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D0D0D),
              Color(0xFF1B160B), // Subtle warm glow from bottom right
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Golden glowing top logo/icon
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surfaceLight,
                            border: Border.all(color: AppTheme.primaryGold.withOpacity(0.35), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGold.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_fire_department,
                            size: 50,
                            color: AppTheme.primaryGold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Title
                      Center(
                        child: Text(
                          'BOOTO SHAWARMA',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: 28,
                                letterSpacing: 4.0,
                              ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'ADMINISTRATOR ACCESS',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Card containing input fields
                      Card(
                        color: AppTheme.surface.withOpacity(0.85),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: AppTheme.primaryGold.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        elevation: 10,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Secure Authentication',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Please enter your administrator credential PIN code to proceed.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // PIN Input Field
                              TextFormField(
                                controller: _pinController,
                                keyboardType: TextInputType.number,
                                obscureText: _isPinObscured,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4.0,
                                  color: Colors.white,
                                ),
                                maxLength: 6,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'PIN cannot be empty';
                                  }
                                  if (value.length < 4) {
                                    return 'PIN must be at least 4 digits';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: 'ADMIN PIN',
                                  hintText: '••••',
                                  counterText: '',
                                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryGold),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPinObscured ? Icons.visibility : Icons.visibility_off,
                                      color: AppTheme.primaryGold.withOpacity(0.8),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPinObscured = !_isPinObscured;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Remember Me Switch
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppTheme.primaryGold,
                                      checkColor: AppTheme.background,
                                      side: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          _rememberMe = val ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _rememberMe = !_rememberMe;
                                      });
                                    },
                                    child: const Text(
                                      'Remember Admin PIN',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              
                              // Login Button
                              AnimatedBuilder(
                                animation: _btnScaleAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _btnScaleAnimation.value,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppTheme.primaryGold,
                                        AppTheme.accentOrange,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.accentOrange.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: auth.isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: auth.isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'AUTHENTICATE',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward_rounded, size: 18),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
