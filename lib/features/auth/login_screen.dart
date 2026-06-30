import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seller_ewaste/core/services/api_service.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/features/main/main_screen.dart';
import 'package:seller_ewaste/features/auth/widgets/registration_bottom_sheet.dart';
import 'package:seller_ewaste/core/services/session_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _callBackendLogin(User user) async {
    try {
      final idToken = await user.getIdToken();
      if (idToken == null) throw Exception("Failed to get Firebase token");

      final response = await ApiService().firebaseLogin(idToken);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['isRegistered'] == false) {
          if (mounted) {
            setState(() => _loading = false);
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => RegistrationBottomSheet(
                phoneNumber: _phoneController.text.trim(),
              ),
            );
          }
        } else {
          await SessionManager().saveSession(data);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          }
        }
      } else if (response.statusCode == 404) {
        if (mounted) {
          setState(() => _loading = false);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => RegistrationBottomSheet(
              phoneNumber: _phoneController.text.trim(),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() => _loading = false);
          _showSnack('Backend login failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Login error: $e');
      if (mounted) {
        setState(() => _loading = false);
        _showSnack('Network error: Failed to login');
      }
    }
  }

  void _sendOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.length != 10) {
      _showSnack('Enter a valid 10-digit phone number');
      return;
    }

    setState(() => _loading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91$phone',
      timeout: const Duration(seconds: 60),

      // Auto-retrieval or instant verification (Android only)
      verificationCompleted: (PhoneAuthCredential credential) async {
        final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
        if (userCred.user != null) {
          await _callBackendLogin(userCred.user!);
        }
      },

      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() => _loading = false);
          _showSnack(e.message ?? 'Verification failed');
        }
      },

      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() {
            _loading = false;
            _otpSent = true;
            _verificationId = verificationId;
          });
          _showSnack('OTP sent successfully');
        }
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  void _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      _showSnack('Enter the 6-digit OTP');
      return;
    }

    if (_verificationId == null) {
      _showSnack('Please request OTP first');
      return;
    }

    setState(() => _loading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCred.user != null) {
        await _callBackendLogin(userCred.user!);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack(e.message ?? 'Invalid OTP');
      }
    } catch (e) {
      debugPrint('OTP verify error: $e');
      if (mounted) {
        setState(() => _loading = false);
        _showSnack('Error: Failed to verify OTP');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.recycling_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              const Text('Welcome Back 👋', style: AppTextStyles.displayMedium),
              const SizedBox(height: 6),
              const Text(
                'Sign in to your ReCircle Sell account',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 36),

              // Phone Field
              Text(
                'Phone Number',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: const Text(
                        '+91',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(width: 1, height: 40, color: AppColors.border),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        enabled: !_otpSent, // lock after OTP sent
                        decoration: const InputDecoration(
                          hintText: '10-digit mobile number',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          counterText: '',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_otpSent) ...[
                Text(
                  'Enter OTP',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: '6-digit OTP',
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.bgCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _loading ? null : _sendOtp,
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : (_otpSent ? _verifyOtp : _sendOtp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                      : Text(
                    _otpSent ? 'Verify & Login' : 'Send OTP',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'By continuing, you agree to our ',
                    style: AppTextStyles.bodySmall,
                    children: [
                      TextSpan(
                        text: 'Terms',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}