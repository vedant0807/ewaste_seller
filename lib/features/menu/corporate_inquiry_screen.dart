import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/core/services/api_service.dart';

class CorporateInquiryScreen extends StatefulWidget {
  const CorporateInquiryScreen({super.key});

  @override
  State<CorporateInquiryScreen> createState() => _CorporateInquiryScreenState();
}

class _CorporateInquiryScreenState extends State<CorporateInquiryScreen> {
  final _companyController = TextEditingController();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _messageController = TextEditingController();

  String? _uploadedFileUrl;
  String? _fileName;
  bool _isUploading = false;
  bool _isSubmitting = false;

  bool _otpSent = false;
  bool _otpVerified = false;
  bool _isOtpLoading = false;
  String? _verificationId;

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker  .pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xls', 'xlsx'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File is too large. Max 10MB allowed.')),
            );
          }
          return;
        }

        setState(() => _isUploading = true);

        final ext = file.extension ?? 'csv';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(' ', '_')}';
        
        final contentType = ext == 'csv' 
            ? 'text/csv' 
            : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

        // 1. Get presigned URL
        final presignedRes = await ApiService().getPresignedUrl(fileName, contentType);
        final uploadUrl = presignedRes['uploadUrl'] as String;
        final fileUrl = presignedRes['fileUrl'] as String;

        // 2. Upload directly to S3
        final bytes = file.bytes;
        if (bytes != null) {
          await ApiService().uploadImageToS3(uploadUrl, bytes, contentType);
          
          if (mounted) {
            setState(() {
              _uploadedFileUrl = fileUrl;
              _fileName = file.name;
              _isUploading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File uploaded successfully!')),
            );
          }
        } else {
          throw Exception('Could not read file bytes');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _sendOtp() async {
    final phone = _mobileController.text.trim();
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid 10-digit phone number')));
      return;
    }

    setState(() => _isOtpLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91$phone',
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        setState(() {
          _otpVerified = true;
          _isOtpLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number auto-verified!')));
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() => _isOtpLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Verification failed')));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() {
            _isOtpLoading = false;
            _otpSent = true;
            _verificationId = verificationId;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent successfully')));
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the 6-digit OTP')));
      return;
    }

    setState(() => _isOtpLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        setState(() {
          _otpVerified = true;
          _isOtpLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone verified successfully!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isOtpLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP. Please try again.')));
      }
    }
  }

  Future<void> _submitEnquiry() async {
    if (_companyController.text.isEmpty ||
        _mobileController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _stateController.text.isEmpty ||
        _pincodeController.text.isEmpty ||
        _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (!_otpVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your phone number first')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'companyName': _companyController.text.trim(),
        'mobileNumber': _mobileController.text.trim(),
        'email': _emailController.text.trim(),
        'addressLine': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'postalCode': _pincodeController.text.trim(),
        'message': _messageController.text.trim(),
        if (_uploadedFileUrl != null) 'fileUrl': _uploadedFileUrl,
      };

      debugPrint('=== BULK ENQUIRY PAYLOAD ===');
      debugPrint(const JsonEncoder.withIndent('  ').convert(payload));
      debugPrint('============================');

      await ApiService().submitBulkEnquiry(payload);

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 16),
              const Text('Enquiry Submitted!', style: AppTextStyles.headingLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'We have received your bulk e-waste disposal request and will contact you shortly.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // dismiss dialog
                    Navigator.of(context).pop(); // go back
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _companyController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Corporate Enquiry'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: AppTextStyles.headingMedium.copyWith(fontSize: 22),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'For bulk e-waste disposal requirements.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.black.withValues(alpha: 0.02)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.business_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Business Details',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  _buildTextField('Company Name *', 'Acme Corp', controller: _companyController),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    'Mobile *', 
                    'e.g. 9876543210',
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    suffix: _isOtpLoading && !_otpSent
                        ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                        : _otpVerified
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : TextButton(
                                onPressed: _sendOtp,
                                child: const Text('Send OTP', style: TextStyle(fontSize: 12)),
                              ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_otpSent && !_otpVerified) ...[
                    _buildTextField(
                      'Enter OTP *', 
                      '6-digit code',
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      suffix: _isOtpLoading && _otpSent
                          ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                          : TextButton(
                              onPressed: _verifyOtp,
                              child: const Text('Verify', style: TextStyle(fontSize: 12)),
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildTextField('Email *', 'john@acme.com', controller: _emailController, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  
                  _buildTextField('Address Line *', '123 Corporate Ave', controller: _addressController),
                  const SizedBox(height: 16),

                  _buildTextField('City *', 'Mumbai', controller: _cityController),
                  const SizedBox(height: 16),
                  
                  _buildTextField('State *', 'Maharashtra', controller: _stateController),
                  const SizedBox(height: 16),
                  
                  _buildTextField('PinCode *', '400001', controller: _pincodeController, keyboardType: TextInputType.number),
                  const SizedBox(height: 24),

                  const Text(
                    'Upload Inventory List (Excel / CSV)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _isUploading ? null : _pickAndUploadFile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          if (_isUploading)
                            const CircularProgressIndicator(color: AppColors.primary)
                          else if (_fileName != null) ...[
                            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 32),
                            const SizedBox(height: 12),
                            Text(
                              _fileName!,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            const Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 32),
                            const SizedBox(height: 12),
                            const Text(
                              'Tap to upload file',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Excel, CSV up to 10MB',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildTextField(
                    'Message *',
                    'Describe your e-waste disposal needs, volume, types of items...',
                    controller: _messageController,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitEnquiry,
                icon: _isSubmitting 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_isSubmitting ? 'Submitting...' : 'Verify phone to submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    String hint, {
    int maxLines = 1, 
    Widget? suffix, 
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
