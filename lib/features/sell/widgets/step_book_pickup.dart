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

class StepBookPickup extends StatefulWidget {
  final SellRequestModel requestData;
  final VoidCallback onUpdate;
  final Widget? bottomAction;

  const StepBookPickup({
    super.key,
    required this.requestData,
    required this.onUpdate,
    this.bottomAction,
  });

  @override
  State<StepBookPickup> createState() => StepBookPickupState();
}

class StepBookPickupState extends State<StepBookPickup> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _altContactController = TextEditingController();
  
  bool _isLoadingAddress = true;
  bool? _isPincodeServiceable;
  bool _isCheckingPincode = false;
  String _pincodeErrorMsg = '';

  List<dynamic> _savedGstNumbers = [];
  Map<String, dynamic>? _selectedGst;

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
        widget.requestData.selectedAddressModel = defaultAddr as Map<String, dynamic>;
        _checkPincode();
      } else {
        widget.requestData.selectedAddressModel = null;
      }

      final List<dynamic> gstList = data['gstNumbers'] ?? [];
      _savedGstNumbers = gstList;
      if (_savedGstNumbers.isNotEmpty) {
        _selectedGst = _savedGstNumbers.firstWhere(
          (g) => g['isDefault'] == true,
          orElse: () => _savedGstNumbers.first,
        ) as Map<String, dynamic>;
        if (widget.requestData.hasGst && widget.requestData.gstNumber.isEmpty) {
          widget.requestData.gstNumber = _selectedGst!['gstNumber'] ?? '';
        }
      }
    } catch (e) {
      widget.requestData.selectedAddressModel = null;
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
        widget.onUpdate();
      }
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
    if (widget.requestData.selectedAddressModel == null) return;
    final pincode = widget.requestData.selectedAddressModel!['postalCode']?.toString() ?? '';
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
      widget.onUpdate();
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
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

  Future<bool> validateAndSubmit(bool termsAccepted) async {
    if (widget.requestData.selectedAddressModel == null) {
      _showToast('Please select an address', isError: true);
      return false;
    }
    if (widget.requestData.pickupDate == null) {
      _showToast('Please select a pickup date', isError: true);
      return false;
    }
    if (widget.requestData.timeSlot == null) {
      _showToast('Please select a pickup time slot', isError: true);
      return false;
    }
    if (widget.requestData.hasGst && widget.requestData.gstNumber.trim().isEmpty) {
      _showToast('Please select or add a GST number', isError: true);
      return false;
    }
    if (!termsAccepted) {
      _showToast('Please agree to the terms', isError: true);
      return false;
    }
    
    return await _submitRequest();
  }

  Future<bool> _submitRequest() async {
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
        return false;
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
            'contactName': req.selectedAddressModel!['contactName']?.toString() ?? '',
            'firstName': firstName,
            'lastName': lastName,
            'address': req.selectedAddressModel!['addressLine']?.toString() ?? '',
            'city': req.selectedAddressModel!['city']?.toString() ?? '', 
            'state': req.selectedAddressModel!['state']?.toString() ?? '',
            'pincode': req.selectedAddressModel!['postalCode']?.toString() ?? '',
            'phone': req.mobile,
            'email': req.email,
            'alternatePhoneNumber': req.altContact,
            'addressType': req.selectedAddressModel!['addressType']?.toString() ?? 'home',
          },
          'images': item.uploadedImageUrls,
          'notes': notes,
          'scheduledDate': dateStr,
          'timeSlot': req.timeSlot,
          'paymentMethod': req.paymentMethod.toUpperCase(),
          'gstNumber': req.hasGst ? req.gstNumber : '',
          'payout': {
            'accountHolder': req.paymentMethod == 'bank' ? req.accountName : '',
            'bankName': req.paymentMethod == 'bank' ? req.bankName : '',
            'accountNumber': req.paymentMethod == 'bank' ? req.accountNumber : '',
            'ifsc': req.paymentMethod == 'bank' ? req.ifscCode : '',
            'upiId': req.paymentMethod == 'upi' ? req.upiId : '',
            'preferredMethod': req.paymentMethod.toUpperCase(),
          },
        };

        await ApiService().submitSellRequest(payload);
      }
      
      if (mounted) {
        Navigator.pop(context);
        showDialog(context: context, barrierDismissible: false, builder: (_) => const _SuccessDialog());
      }
      return true;
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showToast('Failed to submit: $e', isError: true);
      }
      return false;
    }
  }

  Widget _buildPickupSummaryCard() {
    final allItems = [...widget.requestData.items];
    if (widget.requestData.currentItem.selectedCategoryModel != null) {
      allItems.add(widget.requestData.currentItem);
    }
    final totalCount = allItems.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF0D7E40)),
                  SizedBox(width: 8),
                  Text(
                    'Your Pickup Summary',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalCount ${totalCount == 1 ? 'item' : 'items'}',
                  style: const TextStyle(color: Color(0xFF0D7E40), fontWeight: FontWeight.bold, fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = allItems[index];
              final catName = item.selectedCategoryModel?['name'] ?? 'Device';
              final brand = item.textValues['brand'] ?? item.dropdownValues['brand'] ?? '';
              final condition = item.dropdownValues['condition'] ?? 'Good';

              return Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: item.localImagePaths.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(item.localImagePaths.first),
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Center(child: Icon(Icons.devices_rounded, size: 20, color: Color(0xFF0D7E40))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(catName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                        Text(brand.isNotEmpty ? '$brand • $condition' : condition, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(
                    item.estimatedPriceRange,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0D7E40)),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Est. Payout', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                Text(
                  widget.requestData.totalEstimatedPriceRange,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0D7E40)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildPickupSummaryCard(),
        const Text('Pickup Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Text('Choose an address and a time slot for pickup', style: TextStyle(fontSize: 12,)),

        const SizedBox(height: 16),
        
        const Text('Selected Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        if (_isLoadingAddress)
          const Center(child: CircularProgressIndicator(strokeWidth: 2))
        else if (widget.requestData.selectedAddressModel == null)
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
                      (widget.requestData.selectedAddressModel!['addressType'] ?? 'HOME').toString().toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditAddressScreen(address: widget.requestData.selectedAddressModel!)));
                            if (res == true && mounted) _loadAddress();
                          },
                          child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () async {
                            final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAddressesScreen(isSelectionMode: true)));
                            if (res != null && mounted) {
                              setState(() => widget.requestData.selectedAddressModel = res as Map<String, dynamic>);
                              widget.onUpdate();
                              _checkPincode();
                            }
                          },
                          child: const Text('Change', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                ),
                if ((widget.requestData.selectedAddressModel!['contactName']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.requestData.selectedAddressModel!['contactName'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                  ),
                  if ((widget.requestData.selectedAddressModel!['phoneNumber']?.toString() ?? '').isNotEmpty)
                    Text(
                      widget.requestData.selectedAddressModel!['phoneNumber'].toString(),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${widget.requestData.selectedAddressModel!['addressLine'] ?? ''}, ${widget.requestData.selectedAddressModel!['city'] ?? ''}, ${widget.requestData.selectedAddressModel!['state'] ?? ''} - ${widget.requestData.selectedAddressModel!['postalCode'] ?? ''}',
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
                      if (picked != null) {
                        setState(() => widget.requestData.pickupDate = picked);
                        widget.onUpdate();
                      }
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
                  if (v != null) {
                    setState(() => widget.requestData.timeSlot = v);
                    widget.onUpdate();
                  }
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

    // ── GST Section ──────────────────────────────────────────
    const SizedBox(height: 24),
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.requestData.hasGst ? const Color(0xFF0D7E40) : AppColors.border,
          width: widget.requestData.hasGst ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                widget.requestData.hasGst = !widget.requestData.hasGst;
                if (widget.requestData.hasGst) {
                  if (_selectedGst != null) {
                    widget.requestData.gstNumber = _selectedGst!['gstNumber'] ?? '';
                  }
                } else {
                  widget.requestData.gstNumber = '';
                }
              });
              widget.onUpdate();
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  widget.requestData.hasGst ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: widget.requestData.hasGst ? const Color(0xFF0D7E40) : Colors.grey.shade400,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'I have a GST number (optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Quoted price is inclusive of 18% GST.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.requestData.hasGst) ...[
            const SizedBox(height: 16),
            _buildGstSelection(),
          ],
        ],
      ),
    ),

    if (widget.bottomAction != null) ...[
      const SizedBox(height: 16),
      widget.bottomAction!,
    ],
    const SizedBox(height: 40),
  ]);
  }

  void _showAddGstDialog() {
    final gstNumberController = TextEditingController();
    final labelController = TextEditingController();
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add GST Number', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: gstNumberController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 15,
                decoration: InputDecoration(
                  labelText: 'GST Number *',
                  hintText: 'e.g. 27AAAAA0000A1Z5',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelController,
                decoration: InputDecoration(
                  labelText: 'Business / Trade Name (Optional)',
                  hintText: 'e.g. My Shop',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: isDefault,
                    activeColor: const Color(0xFF0D7E40),
                    onChanged: (v) => setDialogState(() => isDefault = v ?? false),
                  ),
                  const Text('Set as default GST', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = gstNumberController.text.trim().toUpperCase();
                if (text.isEmpty) {
                  _showToast('GST Number is required', isError: true);
                  return;
                }
                if (text.length != 15) {
                  _showToast('Invalid GST Number format (15 characters required)', isError: true);
                  return;
                }
                Navigator.pop(ctx);
                try {
                  final payload = {
                    'gstNumber': text,
                    'label': labelController.text.trim(),
                    'isDefault': isDefault,
                  };
                  await ApiService().addGstNumber(payload);
                  _showToast('GST number added successfully', isError: false);
                  await _loadAddress();
                  setState(() {
                    widget.requestData.hasGst = true;
                    widget.requestData.gstNumber = text;
                    _selectedGst = {'gstNumber': text, 'label': labelController.text.trim(), 'isDefault': isDefault};
                  });
                  widget.onUpdate();
                } catch (_) {
                  _showToast('Failed to save GST number', isError: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D7E40),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save GST Number'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGstSelection() {
    if (_savedGstNumbers.isEmpty || _selectedGst == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _showAddGstDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add New GST Number', style: TextStyle(fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0D7E40),
            side: const BorderSide(color: Color(0xFF0D7E40)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'GSTIN: ',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      Text(
                        _selectedGst!['gstNumber'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  if ((_selectedGst!['label']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _selectedGst!['label'].toString(),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ],
              ),
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (ctx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Select GST Number', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          ),
                          ..._savedGstNumbers.map((gst) => ListTile(
                            title: Text(gst['gstNumber'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: gst['label'] != null && gst['label'].toString().isNotEmpty ? Text(gst['label']) : null,
                            trailing: _selectedGst != null && _selectedGst!['id'] == gst['id']
                                ? const Icon(Icons.check_circle, color: Color(0xFF0D7E40))
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedGst = gst as Map<String, dynamic>;
                                widget.requestData.gstNumber = gst['gstNumber'] ?? '';
                              });
                              widget.onUpdate();
                              Navigator.pop(ctx);
                            },
                          )),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.add, color: Color(0xFF0D7E40)),
                            title: const Text('Add New GST Number', style: TextStyle(color: Color(0xFF0D7E40), fontWeight: FontWeight.bold)),
                            onTap: () {
                              Navigator.pop(ctx);
                              _showAddGstDialog();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Change',
                    style: TextStyle(color: Color(0xFF0D7E40), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
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
