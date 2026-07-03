import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/core/services/api_service.dart';
import 'package:seller_ewaste/core/services/session_manager.dart';
import 'package:seller_ewaste/features/sell/models/sell_request_model.dart';
import 'package:seller_ewaste/features/main/main_screen.dart';
import 'package:seller_ewaste/features/menu/add_address_screen.dart';
import 'package:seller_ewaste/features/menu/edit_address_screen.dart';
import 'package:seller_ewaste/features/menu/my_addresses_screen.dart';

class SellCheckoutScreen extends StatefulWidget {
  final SellRequestModel requestData;

  const SellCheckoutScreen({super.key, required this.requestData});

  @override
  State<SellCheckoutScreen> createState() => _SellCheckoutScreenState();
}

class _SellCheckoutScreenState extends State<SellCheckoutScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _altContactController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  
  bool _termsAccepted = false;
  bool _hasGst = false;

  bool _isLoadingAddress = true;
  Map<String, dynamic>? _selectedAddress;

  bool? _isPincodeServiceable;
  bool _isCheckingPincode = false;
  String _pincodeErrorMsg = '';

  void _checkPincode() async {
    if (_selectedAddress == null) return;
    final pincode = _selectedAddress!['postalCode']?.toString() ?? '';
    widget.requestData.pincode = pincode;
    
    setState(() {
      _isCheckingPincode = true;
      _isPincodeServiceable = null;
    });
    
    final pinRes = await ApiService().checkPincode(pincode.trim());
    bool isServiceable = pinRes.statusCode == 200;
    String errorMsg = 'Not serviceable';
    
    if (isServiceable) {
      try {
        final json = jsonDecode(pinRes.body);
        if (json['serviceAvailable'] == false) {
          isServiceable = false;
          if (json['message'] != null) errorMsg = json['message'];
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isCheckingPincode = false;
        _isPincodeServiceable = isServiceable;
        _pincodeErrorMsg = errorMsg;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSessionData();
    _fullNameController.text = widget.requestData.fullName;
    _mobileController.text = widget.requestData.mobile;
    _emailController.text = widget.requestData.email;
    _upiController.text = widget.requestData.upiId;
    _altContactController.text = widget.requestData.altContact;
    _accountNameController.text = widget.requestData.accountName;
    _accountNumberController.text = widget.requestData.accountNumber;
    _ifscController.text = widget.requestData.ifscCode;
    _gstController.text = widget.requestData.gstNumber;
    _hasGst = widget.requestData.hasGst;
    
    // Setup listeners to update model
    _fullNameController.addListener(() => widget.requestData.fullName = _fullNameController.text);
    _mobileController.addListener(() => widget.requestData.mobile = _mobileController.text);
    _emailController.addListener(() => widget.requestData.email = _emailController.text);
    _upiController.addListener(() => widget.requestData.upiId = _upiController.text);
    _altContactController.addListener(() => widget.requestData.altContact = _altContactController.text);
    _accountNameController.addListener(() => widget.requestData.accountName = _accountNameController.text);
    _accountNumberController.addListener(() => widget.requestData.accountNumber = _accountNumberController.text);
    _ifscController.addListener(() => widget.requestData.ifscCode = _ifscController.text);
    _gstController.addListener(() => widget.requestData.gstNumber = _gstController.text);
    
    // Default to UPI if nothing selected
    if (widget.requestData.paymentMethod.isEmpty) {
      widget.requestData.paymentMethod = 'upi';
    }

    _loadAddress();
  }

  Future<void> _loadAddress() async {
    setState(() => _isLoadingAddress = true);
    try {
      final data = await ApiService().getProfile();
      final List<dynamic> addresses = data['addresses'] ?? [];
      if (addresses.isNotEmpty) {
        final defaultAddr = addresses.firstWhere((a) => a['isDefault'] == true, orElse: () => addresses.first);
        _selectedAddress = defaultAddr as Map<String, dynamic>;
        _checkPincode();
      } else {
        _selectedAddress = null;
      }
    } catch (e) {
      _selectedAddress = null;
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _loadSessionData() async {
    final sm = SessionManager();
    final name = await sm.getUserName();
    final phone = await sm.getPhoneNumber();
    final email = await sm.getEmail();
    
    setState(() {
      if (widget.requestData.fullName.isEmpty && name != null) _fullNameController.text = name;
      if (widget.requestData.mobile.isEmpty && phone != null) _mobileController.text = phone;
      if (widget.requestData.email.isEmpty && email != null) _emailController.text = email;
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _upiController.dispose();
    _altContactController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final hasContact = _fullNameController.text.isNotEmpty && 
                       _mobileController.text.isNotEmpty && 
                       _selectedAddress != null &&
                       _isPincodeServiceable == true;
    final hasSchedule = widget.requestData.pickupDate != null && 
                        widget.requestData.timeSlot != null;
    
    bool hasPayment = false;
    if (widget.requestData.paymentMethod == 'upi') {
      hasPayment = _upiController.text.isNotEmpty;
    } else if (widget.requestData.paymentMethod == 'bank') {
      hasPayment = _accountNameController.text.isNotEmpty && _accountNumberController.text.isNotEmpty && _ifscController.text.isNotEmpty;
    } else {
      hasPayment = true; 
    }

    return hasContact && hasSchedule && hasPayment && _termsAccepted;
  }

  Future<void> _submitRequest() async {
    final req = widget.requestData;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );

      final pinRes = await ApiService().checkPincode(req.pincode.trim());
      bool isServiceable = pinRes.statusCode == 200;
      String errorMsg = 'Pincode is unserviceable at the moment.';
      
      if (isServiceable) {
        try {
          final json = jsonDecode(pinRes.body);
          if (json['serviceAvailable'] == false) {
            isServiceable = false;
            if (json['message'] != null) errorMsg = json['message'];
          }
        } catch (_) {}
      }

      if (!isServiceable) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
        }
        return;
      }

      for (final item in req.items) {
        item.uploadedImageUrls.clear();
        for (final path in item.localImagePaths) {
          final file = File(path);
          final bytes = await file.readAsBytes();
          final name = path.split('/').last;
          final contentType = path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
          
          final presignedRes = await ApiService().getPresignedUrl(name, contentType);
          await ApiService().uploadImageToS3(presignedRes['uploadUrl'], bytes, contentType);
          item.uploadedImageUrls.add(presignedRes['fileUrl']);
        }

        final categoryName = item.selectedCategoryModel?['name'] ?? 'Unknown';
        
        String? brandValue = item.dropdownValues.entries
            .where((e) => e.key.toLowerCase() == 'brand').firstOrNull?.value 
            ?? item.textValues.entries.where((e) => e.key.toLowerCase() == 'brand').firstOrNull?.value;
            
        final brand = (brandValue?.isNotEmpty == true) ? brandValue : 'Unknown';
        
        final Map<String, String> attributes = {};
        item.dropdownValues.forEach((k, v) { if (k.toLowerCase() != 'brand') attributes[k] = v; });
        item.textValues.forEach((k, v) { if (k.toLowerCase() != 'brand' && v.isNotEmpty) attributes[k] = v; });
        
        final attrString = attributes.entries.map((e) => '${e.key}: ${e.value}').join(', ');
        final deviceStr = '$categoryName ${attrString.isNotEmpty ? '($attrString)' : ''}'.trim();
        
        final nameParts = req.fullName.trim().split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts.first : '';
        final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
        final dateStr = req.pickupDate?.toIso8601String().split('T')[0] ?? '';
        final notes = 'Scheduled pickup on $dateStr during ${req.timeSlot}.';

        final payload = {
          'device': deviceStr,
          'category': categoryName,
          'brand': brand,
          'estimatedPrice': item.estimatedPrice,
          'deliveryOption': 'service',
          'address': {
            'firstName': firstName,
            'lastName': lastName,
            'address': _selectedAddress!['addressLine']?.toString() ?? '',
            'city': _selectedAddress!['city']?.toString() ?? '', 
            'state': _selectedAddress!['state']?.toString() ?? '',
            'pincode': _selectedAddress!['postalCode']?.toString() ?? '',
            'phone': req.mobile,
            'email': req.email,
            'alternatePhoneNumber': req.altContact,
            'addressType': _selectedAddress!['addressType']?.toString() ?? 'home',
          },
          'images': item.uploadedImageUrls,
          'notes': notes,
          'paymentMethod': req.paymentMethod.toUpperCase(),
          'payout': {
            'accountHolder': req.accountName,
            'bankName': req.bankName,
            'accountNumber': req.accountNumber,
            'ifsc': req.ifscCode,
            'upiId': req.upiId,
            'preferredMethod': req.paymentMethod.toUpperCase(),
          },
        };

        await ApiService().submitSellRequest(payload);
      }
      
      if (mounted) {
        Navigator.pop(context);
        showDialog(context: context, barrierDismissible: false, builder: (_) => const _SuccessDialog());
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit: $e')));
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: Text('Checkout', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.requestData.items.isNotEmpty) ...[
                  const Text('Items Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...widget.requestData.items.map((item) {
                    final categoryName = item.selectedCategoryModel?['name'] ?? 'Unknown';
                    final price = item.estimatedPrice;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(item.selectedCategoryModel?['emoji'] ?? '📱', style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Text(categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            children: [
                              Text('₹$price', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  widget.requestData.currentItem = item;
                                  widget.requestData.items.remove(item);
                                  Navigator.pop(context, true); // true indicates edit mode
                                },
                                child: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    widget.requestData.items.remove(item);
                                  });
                                  if (widget.requestData.items.isEmpty) {
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context, false); // false indicates new item
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('+ Add Another Device', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Contact & Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField('Full Name', _fullNameController),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Mobile', _mobileController, isPhone: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField('Alternate Contact', _altContactController, isPhone: true)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField('Email', _emailController),
                const SizedBox(height: 12),
                
                
                const Text('Selected Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                if (_isLoadingAddress)
                  const Center(child: CircularProgressIndicator(strokeWidth: 2))
                else if (_selectedAddress == null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAddressScreen()));
                        if (res == true && mounted) _loadAddress();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add New Address', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              (_selectedAddress!['addressType'] ?? 'HOME').toString().toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditAddressScreen(address: _selectedAddress!)));
                                    if (res == true && mounted) _loadAddress();
                                  },
                                  child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                                ),
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: () async {
                                    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAddressesScreen(isSelectionMode: true)));
                                    if (res != null && mounted) {
                                      setState(() => _selectedAddress = res as Map<String, dynamic>);
                                      _checkPincode();
                                    }
                                  },
                                  child: const Text('Change', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_selectedAddress!['addressLine'] ?? ''}, ${_selectedAddress!['city'] ?? ''}, ${_selectedAddress!['state'] ?? ''} - ${_selectedAddress!['postalCode'] ?? ''}',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                if (_isCheckingPincode) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Checking service availability...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ] else if (_isPincodeServiceable == true) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text('Service available', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ] else if (_isPincodeServiceable == false) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.cancel_rounded, color: Colors.red, size: 14),
                      const SizedBox(width: 4),
                      Expanded(child: Text(_pincodeErrorMsg, style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ],
                
                const SizedBox(height: 32),
                
                const Text('Pickup Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 14)),
                          );
                          if (picked != null) setState(() => widget.requestData.pickupDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                widget.requestData.pickupDate != null 
                                  ? '${widget.requestData.pickupDate!.day}/${widget.requestData.pickupDate!.month}/${widget.requestData.pickupDate!.year}'
                                  : 'Select Date',
                                style: TextStyle(
                                  fontSize: 14, 
                                  fontWeight: FontWeight.w600,
                                  color: widget.requestData.pickupDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['9 AM - 12 PM', '12 PM - 3 PM', '3 PM - 6 PM'].map((slot) {
                      final isSelected = widget.requestData.timeSlot == slot;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(slot),
                          selected: isSelected,
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (bool selected) {
                            if (selected) setState(() => widget.requestData.timeSlot = slot);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                const Text('How to pay you?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: widget.requestData.paymentMethod == 'upi' ? AppColors.primary : Colors.transparent),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Radio<String>(
                            value: 'upi',
                            groupValue: widget.requestData.paymentMethod,
                            onChanged: (v) => setState(() => widget.requestData.paymentMethod = v!),
                            activeColor: AppColors.primary,
                          ),
                          const Text('UPI Transfer (Instant)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const Spacer(),
                          const Icon(Icons.flash_on_rounded, color: Colors.orange, size: 20),
                        ],
                      ),
                      if (widget.requestData.paymentMethod == 'upi') ...[
                        const SizedBox(height: 8),
                        _buildTextField('Enter UPI ID (e.g. name@bank)', _upiController),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: widget.requestData.paymentMethod == 'bank' ? AppColors.primary : Colors.transparent),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Radio<String>(
                            value: 'bank',
                            groupValue: widget.requestData.paymentMethod,
                            onChanged: (v) => setState(() => widget.requestData.paymentMethod = v!),
                            activeColor: AppColors.primary,
                          ),
                          const Text('Bank Transfer (1-2 days)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const Spacer(),
                          const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 20),
                        ],
                      ),
                      if (widget.requestData.paymentMethod == 'bank') ...[
                        const SizedBox(height: 8),
                        _buildTextField('Account Holder Name', _accountNameController),
                        const SizedBox(height: 8),
                        _buildTextField('IFSC Code', _ifscController),
                        const SizedBox(height: 8),
                        _buildTextField('Account Number', _accountNumberController, isPhone: true),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _hasGst,
                            onChanged: (v) {
                              setState(() {
                                _hasGst = v ?? false;
                                widget.requestData.hasGst = _hasGst;
                              });
                            },
                            activeColor: AppColors.primary,
                          ),
                          const Text('I have a GST Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      if (_hasGst) ...[
                        const SizedBox(height: 8),
                        _buildTextField('GST Number', _gstController),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                CheckboxListTile(
                  value: _termsAccepted,
                  onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                  title: const Text('I agree to the terms and final physical inspection.', style: TextStyle(fontSize: 13)),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          
          // Bottom Summary & Confirm
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Value', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        '₹${widget.requestData.estimatedPrice}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _canSubmit ? _submitRequest : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.bgMuted,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Confirm Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isPhone = false, bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ${isRequired ? '*' : ''}'.trim(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.number : TextInputType.text,
          onChanged: (v) => setState((){}),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Request Placeda', style: AppTextStyles.headingLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Admin will contact you soon.', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)), (r) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View Requests', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
