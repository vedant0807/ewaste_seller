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
            'contactName': _selectedAddress!['contactName']?.toString() ?? '',
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

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 14,
            left: 30,
            right: 30,
            child: Row(
              children: [
                Expanded(child: Container(height: 2, color: AppColors.primary)),
                Expanded(child: Container(height: 2, color: AppColors.primary)),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepIndicator('Choose Products', 'Select what you\nwant to sell', true),
              _buildStepIndicator('Get Paid', 'Add details &\nchoose payment', true),
              _buildStepIndicator('Book Pickup', 'Schedule doorstep\npickup', true, isCurrent: true, stepNumber: '3'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(String title, String subtitle, bool isCompleted, {bool isCurrent = false, String stepNumber = ''}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.primary : Colors.white,
              shape: BoxShape.circle,
              border: isCompleted ? null : Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: Center(
              child: isCompleted && !isCurrent
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(stepNumber, style: TextStyle(color: isCurrent ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: isCompleted ? AppColors.primary : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final item = widget.requestData.items.isNotEmpty ? widget.requestData.items.first : null;
    final categoryName = item?.selectedCategoryModel?['name'] ?? 'Unknown';
    final priceRange = item?.estimatedPriceRange ?? '';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.calendar_month_outlined, size: 16, color: Colors.blueGrey),
              SizedBox(width: 8),
              Text('Your Pickup Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.ac_unit, size: 24), // Placeholder for product icon
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Text('1 Item', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Text(priceRange, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.payment, size: 14, color: Colors.blue),
                        SizedBox(width: 4),
                        Text('Payment Method', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(widget.requestData.paymentMethod.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        const Text('Pickup Address', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (_selectedAddress != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                            child: Text((_selectedAddress!['addressType'] ?? 'HOME').toString().toUpperCase(), style: const TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedAddress != null ? '${_selectedAddress!['addressLine'] ?? ''}, ${_selectedAddress!['city'] ?? ''}' : 'Not Selected',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.calendar_today_outlined, size: 14, color: Colors.blueAccent),
                        SizedBox(width: 4),
                        Text('Pickup Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.requestData.pickupDate != null ? '${widget.requestData.pickupDate!.day} Sept ${widget.requestData.pickupDate!.year}' : 'Not Selected',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.access_time, size: 14, color: Colors.orange),
                        SizedBox(width: 4),
                        Text('Pickup Time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.requestData.timeSlot ?? 'Not Selected',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: _submitRequestWithValidation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Confirm My Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24, height: 24,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Center(child: Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              ),
              const SizedBox(width: 8),
              const Text('Choose pickup address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.my_location, size: 14, color: AppColors.primary),
                label: const Text('Fetch Live Location', style: TextStyle(fontSize: 10, color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingAddress)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (_selectedAddress == null)
            GestureDetector(
              onTap: () async {
                final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAddressScreen()));
                if (res == true && mounted) _loadAddress();
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), style: BorderStyle.none),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add New Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 4),
                        Text('Save more addresses for\nfaster checkout', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
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
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedAddress!['addressLine'] ?? ''}, ${_selectedAddress!['city'] ?? ''}, ${_selectedAddress!['state'] ?? ''} - ${_selectedAddress!['postalCode'] ?? ''}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateTimeStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24, height: 24,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Center(child: Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              ),
              const SizedBox(width: 8),
              const Text('Choose preferred date & time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: CalendarDatePicker(
              initialDate: widget.requestData.pickupDate ?? DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 14)),
              onDateChanged: (d) => setState(() => widget.requestData.pickupDate = d),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.requestData.pickupDate != null)
            Text('Available time slots for ${widget.requestData.pickupDate!.day} Sept ${widget.requestData.pickupDate!.year}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            children: ['9:00 AM - 11:00 AM', '11:00 AM - 1:00 PM', '2:00 PM - 4:00 PM', '4:00 PM - 6:00 PM'].map((time) {
              final isSelected = widget.requestData.timeSlot == time;
              return GestureDetector(
                onTap: () => setState(() => widget.requestData.timeSlot = time),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(time, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isSelected ? AppColors.primary : Colors.black87)),
                          const SizedBox(height: 4),
                          Text(isSelected ? 'Selected' : 'Available', style: TextStyle(fontSize: 9, color: isSelected ? AppColors.primary : Colors.green)),
                        ],
                      ),
                      if (isSelected)
                        const Positioned(
                          top: 4, right: 4,
                          child: Icon(Icons.check_circle, color: AppColors.primary, size: 14),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Important to know', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('🏋️', style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Expanded(child: Text.rich(TextSpan(children: [
                TextSpan(text: 'Lift unavailable? ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
                TextSpan(text: 'Labour charges may apply.', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ]))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('📦', style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Expanded(child: Text.rich(TextSpan(children: [
                TextSpan(text: 'More than 10 items? ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
                TextSpan(text: 'Extra handling charges may apply.', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ]))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('🔍', style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Expanded(child: Text('Final price depends on inspection at pickup.', style: TextStyle(fontSize: 11, color: Colors.grey))),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Image.asset('assets/seller-logo.png', height: 36),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black, size: 28),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0, left: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text('JD', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                _buildStepper(),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Schedule pickup & ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                          const Text('select address.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Choose your convenient pickup address and time slot for doorstep verification', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                _buildSummaryCard(),
                
                const SizedBox(height: 32),
                _buildAddressStep(),
                
                if (_isCheckingPincode) ...[
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('Checking service availability...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ] else if (_isPincodeServiceable == true) ...[
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text('Service available', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ] else if (_isPincodeServiceable == false) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel_rounded, color: Colors.red, size: 14),
                        const SizedBox(width: 4),
                        Expanded(child: Text(_pincodeErrorMsg, style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                _buildDateTimeStep(),
                
                const SizedBox(height: 32),
                _buildImportantInfoCard(),
                
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24, height: 24,
                        child: Checkbox(
                          value: _termsAccepted,
                          onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                          activeColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text.rich(TextSpan(children: [
                              TextSpan(text: 'I agree to the terms & conditions ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                              TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                            ])),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('• ', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
                                Expanded(child: Text('Lift unavailable: labour charges may apply.', style: TextStyle(fontSize: 11, color: Colors.grey))),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('• ', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
                                Expanded(child: Text('Items above 10 kg may incur extra charges.', style: TextStyle(fontSize: 11, color: Colors.grey))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Sticky Bottom Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _submitRequestWithValidation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Confirm My Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
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
