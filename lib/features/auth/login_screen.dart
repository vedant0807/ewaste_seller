import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:seller_ewaste/core/services/api_service.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/features/main/main_screen.dart';
import 'package:seller_ewaste/features/auth/widgets/registration_bottom_sheet.dart';
import 'package:seller_ewaste/core/services/session_manager.dart';
import 'package:seller_ewaste/core/utils/validators.dart';

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
  int _resendTimer = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _resendTimer = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_resendTimer > 0) {
          setState(() {
            _resendTimer--;
          });
        } else {
          setState(() {
            _canResend = true;
          });
          _timer?.cancel();
        }
      }
    });
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
          _showToast('Backend login failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Login error: $e');
      if (mounted) {
        setState(() => _loading = false);
        _showToast('Network error: Failed to login');
      }
    }
  }

  void _sendOtp() async {
    final phone = _phoneController.text.trim();

    final error = Validators.validateMobile(phone);
    if (error != null) {
      _showToast(error);
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
          _showToast(e.message ?? 'Verification failed');
        }
      },

      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() {
            _loading = false;
            _otpSent = true;
            _verificationId = verificationId;
          });
          _startTimer();
          _showToast('OTP sent successfully', isError: false);
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
      _showToast('Enter the 6-digit OTP');
      return;
    }

    if (_verificationId == null) {
      _showToast('Please request OTP first');
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
        _showToast('Verification Failed: The code is incorrect. Please try again.');
      }
    } catch (e) {
      debugPrint('OTP verify error: $e');
      if (mounted) {
        setState(() => _loading = false);
        _showToast('Error: Failed to verify OTP');
      }
    }
  }

  void _showToast(String msg, {bool isError = true}) {
    final fToast = FToast();
    fToast.init(context);
    
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32.0),
        color: isError ? Colors.red : Colors.green,
      ),
      child: Text(
        msg,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 3),
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
              const Text('Welcome', style: AppTextStyles.displayMedium),
              const SizedBox(height: 6),
              const Text(
                'Enter mobile number to get started.',
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: 36),
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
                  onTap: (_loading || !_canResend) ? null : _sendOtp,
                  child: Text(
                    _canResend ? 'Resend OTP' : 'Resend OTP in ${_resendTimer}s',
                    style: TextStyle(
                      color: (_loading || !_canResend) ? AppColors.textSecondary : AppColors.primary,
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