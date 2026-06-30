import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/core/services/api_service.dart';
import 'package:seller_ewaste/features/main/main_screen.dart';
import 'package:seller_ewaste/core/services/session_manager.dart';

class RegistrationBottomSheet extends StatefulWidget {
  final String phoneNumber;

  const RegistrationBottomSheet({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<RegistrationBottomSheet> createState() => _RegistrationBottomSheetState();
}

class _RegistrationBottomSheetState extends State<RegistrationBottomSheet> {
  final _nameController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _loading = false;
  String? _pincodeError;

  @override
  void dispose() {
    _nameController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final pincode = _pincodeController.text.trim();

    if (name.isEmpty) {
      _showSnack('Please enter your full name');
      return;
    }
    if (pincode.isEmpty || pincode.length < 6) {
      _showSnack('Please enter a valid pincode');
      return;
    }

    setState(() {
      _loading = true;
      _pincodeError = null;
    });

    try {
      // 1. Check Pincode
      final checkRes = await ApiService().checkPincode(pincode);
      if (checkRes.statusCode >= 200 && checkRes.statusCode < 300) {
        final checkData = jsonDecode(checkRes.body);
        if (checkData['serviceAvailable'] == true) {
          // 2. Register User
          final regRes = await ApiService().registerSeller(name, widget.phoneNumber, pincode);
          
          if (regRes.statusCode >= 200 && regRes.statusCode < 300) {
            final regData = jsonDecode(regRes.body);
            if (regData['success'] == true) {
              await SessionManager().saveSession(regData);
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen()),
                (route) => false,
              );
              return;
            } else {
              _showSnack(regData['message'] ?? 'Registration failed');
            }
          } else {
            _showSnack('Failed to register: ${regRes.statusCode}');
          }
        } else {
          setState(() {
            _pincodeError = checkData['message'] ?? 'Service not available in this area';
          });
        }
      } else {
        _showSnack('Failed to check pincode: ${checkRes.statusCode}');
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      _showSnack('Network error: Failed to register');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine bottom padding for keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Green Header
            Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primaryGlow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.black54, size: 20),
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Complete Registration',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Help us set up your profile',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stepper row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepCircle(true, '1'),
                      _buildStepLine(),
                      _buildStepCircle(true, '2'),
                      _buildStepLine(),
                      _buildStepCircle(false, '3'),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Full Name
                  Text('Full Name', style: AppTextStyles.labelMedium),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Amit Patel',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),

                  // Pincode
                  Text('Pincode', style: AppTextStyles.labelMedium),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _pincodeController,
                    hint: 'e.g. 400001',
                    icon: Icons.location_on_outlined,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    hasError: _pincodeError != null,
                  ),
                  if (_pincodeError != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _pincodeError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGlow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Complete Registration',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCircle(bool done, String label) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: done ? AppColors.primaryLight : AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: done 
          ? const Icon(Icons.check, size: 16, color: AppColors.primaryDark)
          : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.border,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    bool hasError = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: hasError ? Colors.red : AppColors.border),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLength: maxLength,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                counterText: '',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
