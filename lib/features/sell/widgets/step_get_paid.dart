import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:seller_ewaste/core/services/api_service.dart';
import 'package:seller_ewaste/core/services/session_manager.dart';
import 'package:seller_ewaste/features/sell/models/sell_request_model.dart';

class StepGetPaid extends StatefulWidget {
  final SellRequestModel requestData;
  final VoidCallback onUpdate;
  final Widget? bottomAction;

  const StepGetPaid({
    super.key,
    required this.requestData,
    required this.onUpdate,
    this.bottomAction,
  });

  @override
  State<StepGetPaid> createState() => StepGetPaidState();
}

class StepGetPaidState extends State<StepGetPaid> {
  List<dynamic> _savedUpiAccounts = [];
  List<dynamic> _savedBankAccounts = [];

  Map<String, dynamic>? _selectedUpi;
  Map<String, dynamic>? _selectedBank;

  late TextEditingController _voucherEmailController;
  late TextEditingController _voucherMobileController;
  late TextEditingController _upiController;
  late TextEditingController _bankAccountController;
  late TextEditingController _bankHolderController;
  late TextEditingController _bankIfscController;
  late TextEditingController _bankNameController;

  @override
  void initState() {
    super.initState();

    // Default to 'voucher' as shown in mockup
    if (widget.requestData.paymentMethod.isEmpty) {
      widget.requestData.paymentMethod = 'voucher';
    }

    _voucherEmailController = TextEditingController(text: widget.requestData.voucherEmail);
    _voucherMobileController = TextEditingController(text: widget.requestData.voucherMobile);
    _upiController = TextEditingController(text: widget.requestData.upiId);
    _bankAccountController = TextEditingController(text: widget.requestData.accountNumber);
    _bankHolderController = TextEditingController(text: widget.requestData.accountName);
    _bankIfscController = TextEditingController(text: widget.requestData.ifscCode);
    _bankNameController = TextEditingController(text: widget.requestData.bankName);

    _loadPaymentInfo();
  }

  @override
  void dispose() {
    _voucherEmailController.dispose();
    _voucherMobileController.dispose();
    _upiController.dispose();
    _bankAccountController.dispose();
    _bankHolderController.dispose();
    _bankIfscController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentInfo() async {
    try {
      final userPhone = await SessionManager().getPhoneNumber();
      final userEmail = await SessionManager().getEmail();

      if (widget.requestData.voucherEmail.isEmpty && userEmail != null && userEmail.isNotEmpty) {
        widget.requestData.voucherEmail = userEmail;
        _voucherEmailController.text = userEmail;
      } else if (widget.requestData.voucherEmail.isEmpty) {
        widget.requestData.voucherEmail = 'you@email.com';
        _voucherEmailController.text = 'you@email.com';
      }

      if (widget.requestData.voucherMobile.isEmpty && userPhone != null && userPhone.isNotEmpty) {
        widget.requestData.voucherMobile = userPhone;
        _voucherMobileController.text = userPhone;
      } else if (widget.requestData.voucherMobile.isEmpty) {
        widget.requestData.voucherMobile = '+919960170089';
        _voucherMobileController.text = '+919960170089';
      }

      final data = await ApiService().getProfile();
      _savedUpiAccounts = data['upiAccounts'] ?? [];
      _savedBankAccounts = data['bankAccounts'] ?? [];

      if (_savedUpiAccounts.isNotEmpty) {
        _selectedUpi = _savedUpiAccounts.firstWhere(
          (u) => u['isDefault'] == true,
          orElse: () => _savedUpiAccounts.first,
        ) as Map<String, dynamic>;
        widget.requestData.upiId = _selectedUpi!['upiId'] ?? '';
        _upiController.text = widget.requestData.upiId;
      }

      if (_savedBankAccounts.isNotEmpty) {
        _selectedBank = _savedBankAccounts.firstWhere(
          (b) => b['isDefault'] == true,
          orElse: () => _savedBankAccounts.first,
        ) as Map<String, dynamic>;
        widget.requestData.accountName = _selectedBank!['accountHolderName'] ?? '';
        widget.requestData.accountNumber = _selectedBank!['accountNumber'] ?? '';
        widget.requestData.bankName = _selectedBank!['bankName'] ?? '';
        widget.requestData.ifscCode = _selectedBank!['ifscCode'] ?? '';

        _bankAccountController.text = widget.requestData.accountNumber;
        _bankHolderController.text = widget.requestData.accountName;
        _bankIfscController.text = widget.requestData.ifscCode;
        _bankNameController.text = widget.requestData.bankName;
      }
    } catch (_) {
    } finally {
      if (mounted) {
        widget.onUpdate();
      }
    }
  }

  void _showToast(String message, {bool isError = true}) {
    FToast fToast = FToast();
    fToast.init(context);
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      margin: const EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: isError ? Colors.red.shade600 : const Color(0xFF0D7E40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
    fToast.showToast(child: toast, gravity: ToastGravity.BOTTOM, toastDuration: const Duration(seconds: 3));
  }

  bool validate() {
    if (widget.requestData.paymentMethod == 'voucher') {
      if (widget.requestData.voucherEmail.isEmpty) {
        _showToast('Please enter delivery email ID');
        return false;
      }
      if (widget.requestData.voucherMobile.isEmpty) {
        _showToast('Please enter delivery mobile number');
        return false;
      }
      return true;
    }
    if (widget.requestData.paymentMethod == 'upi') {
      if (widget.requestData.upiId.isEmpty) {
        _showToast('Please enter or select a UPI ID');
        return false;
      }
      return true;
    }
    if (widget.requestData.paymentMethod == 'bank') {
      if (widget.requestData.accountNumber.isEmpty || widget.requestData.ifscCode.isEmpty) {
        _showToast('Please enter Bank account details');
        return false;
      }
      return true;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final method = widget.requestData.paymentMethod;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Amazon Voucher Option Card
          _buildPaymentMethodCard(
            methodKey: 'voucher',
            title: 'Amazon Voucher',
            subtitle: 'Get 5% extra value',
            icon: Icons.card_giftcard_rounded,
            isSelected: method == 'voucher',
            isSpecial: true,
          ),

          const SizedBox(height: 12),

          // 2. Bank Transfer Option Card
          _buildPaymentMethodCard(
            methodKey: 'bank',
            title: 'Bank Transfer',
            subtitle: 'Direct to your bank account',
            icon: Icons.account_balance_rounded,
            isSelected: method == 'bank',
          ),

          const SizedBox(height: 12),

          // 3. UPI Payout Option Card
          _buildPaymentMethodCard(
            methodKey: 'upi',
            title: 'UPI Payout',
            subtitle: 'Instant to your UPI ID',
            icon: Icons.smartphone_rounded,
            isSelected: method == 'upi',
          ),

          const SizedBox(height: 18),

          // 4. "Payment details for [Method]" Card
          _buildPaymentDetailsCard(),

          if (widget.bottomAction != null) ...[
            const SizedBox(height: 16),
            widget.bottomAction!,
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required String methodKey,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    bool isSpecial = false,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          widget.requestData.paymentMethod = methodKey;
          widget.onUpdate();
        });
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDCFCE7) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected && isSpecial
                    ? const Color(0xFF0D7E40)
                    : const Color(0xFFE8F8EE),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected && isSpecial
                      ? Colors.white
                      : const Color(0xFF0D7E40),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected && isSpecial
                          ? const Color(0xFF0D7E40)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Trailing Checkmark or Radio
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D7E40),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.check, size: 14, color: Colors.white),
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Payment Details Card
  Widget _buildPaymentDetailsCard() {
    final method = widget.requestData.paymentMethod;
    final methodName = method == 'voucher'
        ? 'Amazon Voucher'
        : (method == 'bank' ? 'Bank Transfer' : 'UPI Payout');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with green method name
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
              children: [
                const TextSpan(text: 'Payment details for '),
                TextSpan(
                  text: methodName,
                  style: const TextStyle(color: Color(0xFF0D7E40)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            method == 'voucher'
                ? 'Delivered instantly to your email & mobile after pickup verification.'
                : 'Payout will be processed securely after pickup verification.',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
              height: 1.3,
            ),
          ),

          const SizedBox(height: 18),

          // Fields depending on method
          if (method == 'voucher') ...[
            _buildInputField(
              label: 'Delivery email ID',
              controller: _voucherEmailController,
              hint: 'you@email.com',
              onChanged: (val) {
                widget.requestData.voucherEmail = val;
                widget.onUpdate();
              },
            ),
            const SizedBox(height: 14),
            _buildInputField(
              label: 'Delivery mobile number',
              controller: _voucherMobileController,
              hint: '+919960170089',
              keyboardType: TextInputType.phone,
              onChanged: (val) {
                widget.requestData.voucherMobile = val;
                widget.onUpdate();
              },
            ),
          ] else if (method == 'upi') ...[
            _buildInputField(
              label: 'UPI ID',
              controller: _upiController,
              hint: 'username@okaxis',
              onChanged: (val) {
                widget.requestData.upiId = val;
                widget.onUpdate();
              },
            ),
          ] else ...[
            _buildInputField(
              label: 'Account Holder Name',
              controller: _bankHolderController,
              hint: 'Darshan',
              onChanged: (val) {
                widget.requestData.accountName = val;
                widget.onUpdate();
              },
            ),
            const SizedBox(height: 12),
            _buildInputField(
              label: 'Account Number',
              controller: _bankAccountController,
              hint: '1234567890',
              keyboardType: TextInputType.number,
              onChanged: (val) {
                widget.requestData.accountNumber = val;
                widget.onUpdate();
              },
            ),
            const SizedBox(height: 12),
            _buildInputField(
              label: 'IFSC Code',
              controller: _bankIfscController,
              hint: 'HDFC0001234',
              onChanged: (val) {
                widget.requestData.ifscCode = val;
                widget.onUpdate();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            children: [
              TextSpan(text: label),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
