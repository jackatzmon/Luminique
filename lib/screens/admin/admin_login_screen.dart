import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app/config/theme.dart';
import '../../app/config/routes.dart';
import '../../services/auth_service.dart';
import '../../providers/app_state_provider.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        final user = await _authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (user != null && mounted) {
          context.read<AppStateProvider>().setCurrentUser(user);
          Navigator.of(context).pushReplacementNamed(AppRoutes.adminDashboard);
        }
      } else {
        final user = await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (user != null && mounted) {
          context.read<AppStateProvider>().setCurrentUser(user);
          Navigator.of(context).pushReplacementNamed(AppRoutes.adminDashboard);
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = _authService.getErrorMessage(e);
      });
    } catch (e) {
      setState(() {
        _error = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminiqueTheme.darkBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand
                    Text(
                      'LUMINIQUE',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 12,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(duration: 600.ms),

                    const SizedBox(height: 8),

                    Text(
                      'DJ CONTROL PANEL',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.raleway(
                        fontSize: 12,
                        letterSpacing: 4,
                        color: Colors.white54,
                      ),
                    ).animate(delay: 200.ms).fadeIn(duration: 500.ms),

                    const SizedBox(height: 60),

                    // Title
                    Text(
                      _isSignUp ? 'CREATE ACCOUNT' : 'SIGN IN',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4,
                        color: Colors.white,
                      ),
                    ).animate(delay: 300.ms).fadeIn(duration: 500.ms),

                    const SizedBox(height: 32),

                    // Error message
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: LuminiqueTheme.errorColor.withOpacity(0.1),
                          border: Border.all(
                            color: LuminiqueTheme.errorColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: LuminiqueTheme.errorColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: GoogleFonts.raleway(
                                  color: LuminiqueTheme.errorColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.raleway(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: GoogleFonts.montserrat(
                          letterSpacing: 1,
                          color: Colors.white54,
                        ),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Colors.white54,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ).animate(delay: 400.ms).fadeIn(duration: 500.ms),

                    const SizedBox(height: 20),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.raleway(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: GoogleFonts.montserrat(
                          letterSpacing: 1,
                          color: Colors.white54,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.white54,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (_isSignUp && value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ).animate(delay: 500.ms).fadeIn(duration: 500.ms),

                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LuminiqueTheme.accentColor,
                          disabledBackgroundColor:
                              LuminiqueTheme.accentColor.withOpacity(0.3),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                _isSignUp ? 'CREATE ACCOUNT' : 'SIGN IN',
                                style: GoogleFonts.montserrat(
                                  letterSpacing: 2,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ).animate(delay: 600.ms).fadeIn(duration: 500.ms),

                    const SizedBox(height: 24),

                    // Toggle sign up / sign in
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                          _error = null;
                        });
                      },
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign in'
                            : "Don't have an account? Create one",
                        style: GoogleFonts.raleway(
                          color: LuminiqueTheme.accentColor,
                        ),
                      ),
                    ).animate(delay: 700.ms).fadeIn(duration: 500.ms),

                    if (!_isSignUp) ...[
                      TextButton(
                        onPressed: () {
                          // TODO: Implement forgot password
                        },
                        child: Text(
                          'Forgot password?',
                          style: GoogleFonts.raleway(
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
