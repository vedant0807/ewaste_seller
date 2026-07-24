import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/core/services/api_service.dart';
import 'package:seller_ewaste/core/services/session_manager.dart';
import 'package:seller_ewaste/features/sell/models/sell_request_model.dart';
import 'package:seller_ewaste/features/main/main_screen.dart';
import 'package:seller_ewaste/features/menu/add_address_screen.dart';
import 'package:seller_ewaste/features/menu/edit_address_screen.dart';
import 'package:seller_ewaste/features/menu/my_addresses_screen.dart';

class SellContactScreen extends StatefulWidget {
  final SellRequestModel requestData;
  final Map<String, dynamic>? selectedUpi;
  final Map<String, dynamic>? selectedBank;
  final Map<String, dynamic>? selectedGst;
  final bool hasGst;

  const SellContactScreen({
    super.key, 
    required this.requestData,
    this.selectedUpi,
    this.selectedBank,
    this.selectedGst,
    required this.hasGst,
  });

  @override
  State<SellContactScreen> createState() => _SellContactScreenState();
}

class _SellContactScreenState extends State<SellContactScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _altContactController = TextEditingController();
  
  bool _isLoadingAddress = true;
  Map<String, dynamic>? _selectedAddress;

  bool? _isPincodeServiceable;
  bool _isCheckingPincode = false;
  String _pincodeErrorMsg = '';

  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
    _fullNameController.text = widget.requestData.fullName;
    _mobileController.text = widget.requestData.mobile;
    _emailController.text = widget.requestData.email;
    _altContactController.text = widget.requestData.altContact;
    
    _fullNameController.addListener(() => widget.requestData.fullName = _fullNameController.text);
    _mobileController.addListener(() => widget.requestData.mobile = _mobileController.text);
    _emailController.addListener(() => widget.requestData.email = _emailController.text);
    _altContactController.addListener(() => widget.requestData.altContact = _altContactController.text);
    
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
      if (widget.requestData.mobile.isEmpty && phone != null) {
        _mobileController.text = phone.replaceAll('+91', '').replaceAll(' ', '');
      }
      if (widget.requestData.email.isEmpty && email != null) _emailController.text = email;
    });
  }

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

  void _showToast(String message, {bool isError = true}) {
    FToast fToast = FToast();
    fToast.init(context);

    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      margin: const EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: isError ? Colors.red.shade600 : Colors.green.shade600,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );

    fToast.showToast(child: toast, gravity: ToastGravity.BOTTOM, toastDuration: const Duration(seconds: 3));
  }

  void _submitRequestWithValidation() {
    // if (_fullNameController.text.trim().isEmpty) {
    //   _showToast('Please enter your full name', isError: true);
    //   return;
    // }
    // if (_mobileController.text.trim().isEmpty) {
    //   _showToast('Mobile number is missing', isError: true);
    //   return;
    // }
    // if (_emailController.text.trim().isEmpty) {
    //   _showToast('Please enter your email address', isError: true);
    //   return;
    // }
    if (_selectedAddress == null) {
      _showToast('Please select an address', isError: true);
      return;
    }
    if (widget.requestData.pickupDate == null) {
      _showToast('Please select a pickup date', isError: true);
      return;
    }
    if (widget.requestData.timeSlot == null) {
      _showToast('Please select a pickup time slot', isError: true);
      return;
    }
    if (!_termsAccepted) {
      _showToast('Please agree to the terms', isError: true);
      return;
    }
    
    _submitRequest();
  }

  Future<void> _submitRequest() async {
    final req = widget.requestData;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );

      if (_isPincodeServiceable != true) {
        if (mounted) {
          Navigator.pop(context);
          _showToast(_pincodeErrorMsg, isError: true);
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
          'scheduledDate': dateStr,
          'timeSlot': req.timeSlot,
          'paymentMethod': req.paymentMethod.toUpperCase(),
          'gstNumber': widget.hasGst && widget.selectedGst != null ? widget.selectedGst!['gstNumber'] : '',
          'payout': {
            'accountHolder': req.paymentMethod == 'bank' && widget.selectedBank != null ? widget.selectedBank!['accountHolderName'] : '',
            'bankName': req.paymentMethod == 'bank' && widget.selectedBank != null ? widget.selectedBank!['bankName'] : '',
            'accountNumber': req.paymentMethod == 'bank' && widget.selectedBank != null ? widget.selectedBank!['accountNumber'] : '',
            'ifsc': req.paymentMethod == 'bank' && widget.selectedBank != null ? widget.selectedBank!['ifscCode'] : '',
            'upiId': req.paymentMethod == 'upi' && widget.selectedUpi != null ? widget.selectedUpi!['upiId'] : '',
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
        _showToast('Failed to submit: $e', isError: true);
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Contact Details', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Pickup Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('Choose an address and a time slot for pickup', style: TextStyle(fontSize: 12,)),

                const SizedBox(height: 16),
                // _buildTextField('Full Name', _fullNameController, isRequired: true),
                // const SizedBox(height: 12),
                // Row(
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Expanded(child: _buildTextField('Mobile', _mobileController, isPhone: true, maxLength: 13, isRequired: true, readOnly: true, errorText: (_mobileController.text.isNotEmpty && !RegExp(r'^\d{10,13}$').hasMatch(_mobileController.text)) ? '10-13 digits' : null)),
                //     const SizedBox(width: 12),
                //     Expanded(child: _buildTextField('Alternate Contact', _altContactController, isPhone: true, maxLength: 13, errorText: (_altContactController.text.isNotEmpty && !RegExp(r'^\d{10,13}$').hasMatch(_altContactController.text)) ? '10-13 digits' : null)),
                //   ],
                // ),
                // const SizedBox(height: 12),
                // _buildTextField('Email', _emailController, isRequired: true),
                // const SizedBox(height: 24),
                
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text.rich(
                            TextSpan(
                              text: 'Date',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              children: [
                                TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
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
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.requestData.pickupDate != null
                                        ? '${widget.requestData.pickupDate!.day}/${widget.requestData.pickupDate!.month}/${widget.requestData.pickupDate!.year}'
                                        : 'Select Date',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: widget.requestData.pickupDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text.rich(
                            TextSpan(
                              text: 'Time',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              children: [
                                TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownMenu<String>(
                        initialSelection: widget.requestData.timeSlot,
                        expandedInsets: EdgeInsets.zero,
                        hintText: 'Time Slot',
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        onSelected: (v) {
                          if (v != null) setState(() => widget.requestData.timeSlot = v);
                        },
                        dropdownMenuEntries: ['9:00 AM - 11:00 AM', '11:00 AM - 1:00 PM', '2:00 PM - 4:00 PM', '4:00 PM - 6:00 PM']
                            .map((opt) => DropdownMenuEntry(
                                  value: opt,
                                  label: opt,
                                  style: MenuItemButton.styleFrom(
                                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ))
                            .toList(),
                        inputDecorationTheme: InputDecorationTheme(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.transparent)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        ),
                        trailingIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                        selectedTrailingIcon: const Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.primary),
                        menuStyle: MenuStyle(
                          backgroundColor: const WidgetStatePropertyAll(Colors.white),
                          elevation: const WidgetStatePropertyAll(8),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CheckboxListTile(
              value: _termsAccepted,
              onChanged: (v) => setState(() => _termsAccepted = v ?? false),
              title: const Text('I agree to the terms and final physical inspection.', style: TextStyle(fontSize: 13)),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitRequestWithValidation,
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
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isPhone = false, bool isRequired = false, String? errorText, int? maxLength, bool obscureText = false, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            children: [
              if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.number : TextInputType.text,
          maxLength: maxLength,
          obscureText: obscureText,
          readOnly: readOnly,
          onChanged: (v) => setState((){}),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            errorText: errorText,
            counterText: '',
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
            const Text('Request Placed', style: AppTextStyles.headingLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Admin will contact you soon.', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)), (r) => false);
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
