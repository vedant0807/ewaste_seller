import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/features/requests/requests_screen.dart';
import 'package:seller_ewaste/core/services/api_service.dart';
import 'package:seller_ewaste/features/main/main_screen.dart';

// ---------------------------------------------------------------------------
// SELL SCREEN — Flow: Upload → Device Details → Payment → Schedule Pickup
// ---------------------------------------------------------------------------

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  int _step = 0; // 0=upload, 1=details, 2=payment, 3=schedule

  // ── Step 1 state ──────────────────────────────────────────────────────────
  final List<String> _uploadedImageUrls = [];
  Map<String, dynamic>? _selectedCategoryModel;
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, String> _dropdownValues = {};
  final ValueNotifier<int> _formUpdateNotifier = ValueNotifier(0);
  
  bool _isLoadingCategories = true;
  String? _categoriesError;
  List<Map<String, dynamic>> _apiCategories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await ApiService().getCategories();
      if (res.statusCode == 200) {
        final List json = jsonDecode(res.body);
        setState(() {
          _apiCategories = json.cast<Map<String, dynamic>>().toList();
          _isLoadingCategories = false;
        });
      } else {
        setState(() {
          _categoriesError = 'Failed to load categories';
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Categories error: $e');
      setState(() {
        _categoriesError = 'Failed to fetch categories';
        _isLoadingCategories = false;
      });
    }
  }

  // ── Terms / accept state (step 1 bottom) ─────────────────────────────────
  bool _termsAccepted = false;
  bool _priceAccepted = false;

  // ── Payment state ─────────────────────────────────────────────────────────
  String _paymentMethod = 'upi'; // 'upi' | 'bank' | 'voucher'
  final _upiController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _ifscController = TextEditingController();
  bool _hasGst = false;
  final _gstController = TextEditingController();

  // ── Schedule state ────────────────────────────────────────────────────────
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _altContactController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _pincodeController = TextEditingController();
  DateTime? _pickupDate;
  String? _timeSlot;

  // ── Derived price ─────────────────────────────────────────────────────────
  static const Map<String, int> _basePrices = {
    'Mobile': 4000,
    'Laptop': 8500,
    'Desktop': 5000,
    'Television': 2000,
    'Monitor': 2500,
    'Printer': 1500,
    'Router / WiFi': 800,
    'Gaming Console': 3000,
    'Camera': 3500,
    'Home Appliance': 2000,
    'AC': 4500,
    'Refrigerator': 3000,
    'Washing Machine': 2500,
    'Other': 1000,
  };

  static const Map<String, double> _conditionMultiplier = {
    'Excellent': 1.2,
    'Good': 1.0,
    'Fair': 0.75,
    'Poor': 0.5,
  };

  bool get _allRequiredFilled {
    if (_selectedCategoryModel == null) return false;
    final attrs = _selectedCategoryModel!['attributes'] as List<dynamic>? ?? [];
    for (final attrMap in attrs) {
      final attr = attrMap as Map<String, dynamic>;
      final isRequired = attr['isRequired'] == true;
      final slug = attr['slug'] as String;
      final inputType = attr['inputType'] as String?;

      if (isRequired) {
        if (inputType == 'dropdown') {
          if (_dropdownValues[slug] == null || _dropdownValues[slug]!.isEmpty) return false;
        } else {
          final text = _textControllers[slug]?.text.trim() ?? '';
          if (text.isEmpty) return false;
        }
      }
    }
    return true;
  }

  int get _estimatedPrice {
    if (_selectedCategoryModel == null) return 0;
    final base = _basePrices[_selectedCategoryModel!['name']] ?? 1000;
    final cond = _dropdownValues['condition'] ?? 'Good';
    final mult = _conditionMultiplier[cond] ?? 1.0;
    return (base * mult).round();
  }

  String get _estimatedPriceRange {
    final p = _estimatedPrice;
    if (p == 0) return '—';
    final lo = (p * 0.9).round();
    final hi = (p * 1.1).round();
    return '₹${_fmt(lo)} – ₹${_fmt(hi)}';
  }

  String _fmt(int n) {
    if (n >= 1000) {
      return '${(n ~/ 1000)},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return n.toString();
  }

  // ── Payment CTA enabled? ──────────────────────────────────────────────────
  bool get _paymentReady {
    if (_paymentMethod == 'upi') return _upiController.text.trim().isNotEmpty;
    if (_paymentMethod == 'bank') {
      return _accountNameController.text.trim().isNotEmpty &&
          _accountNumberController.text.trim().isNotEmpty &&
          _bankNameController.text.trim().isNotEmpty &&
          _ifscController.text.trim().isNotEmpty;
    }
    return true; // voucher always ok
  }

  bool get _scheduleReady =>
      _fullNameController.text.trim().isNotEmpty &&
          _mobileController.text.trim().isNotEmpty &&
          _addressController.text.trim().isNotEmpty &&
          _pickupDate != null &&
          _timeSlot != null;

  Future<void> _submitSellRequest() async {
    final categoryName = _selectedCategoryModel?['name'] ?? 'Unknown';
    
    String? brandValue;
    for (final k in _dropdownValues.keys) {
      if (k.toLowerCase() == 'brand') {
        brandValue = _dropdownValues[k];
        break;
      }
    }
    if (brandValue == null || brandValue.isEmpty) {
      for (final k in _textControllers.keys) {
        if (k.toLowerCase() == 'brand') {
          brandValue = _textControllers[k]?.text;
          break;
        }
      }
    }
    
    final brand = (brandValue != null && brandValue.isNotEmpty) ? brandValue : 'Unknown';
    
    final Map<String, String> attributes = {};
    _dropdownValues.forEach((k, v) { 
      if (k.toLowerCase() != 'brand') attributes[k] = v; 
    });
    _textControllers.forEach((k, v) { 
      if (k.toLowerCase() != 'brand' && v.text.isNotEmpty) attributes[k] = v.text; 
    });
    
    final attrString = attributes.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    final deviceStr = '$categoryName ${attrString.isNotEmpty ? '($attrString)' : ''}'.trim();
    
    final nameParts = _fullNameController.text.trim().split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
    
    final dateStr = _pickupDate?.toIso8601String().split('T')[0] ?? '';
    final notes = 'Scheduled pickup on $dateStr during $_timeSlot. Landmark: N/A';

    final payload = {
      'device': deviceStr,
      'category': categoryName,
      'brand': brand,
      'estimatedPrice': _estimatedPrice,
      'deliveryOption': 'service',
      'address': {
        'firstName': firstName,
        'lastName': lastName,
        'address': '${_addressController.text}, ${_areaController.text}'.trim(),
        'city': 'Pune', 
        'state': 'Maharashtra',
        'pincode': _pincodeController.text,
        'phone': _mobileController.text,
        'email': _emailController.text,
        'alternatePhoneNumber': _altContactController.text,
        'addressType': 'Home',
      },
      'images': _uploadedImageUrls,
      'notes': notes,
      'paymentMethod': _paymentMethod.toUpperCase(),
      'scheduledDate': dateStr,
      'timeSlot': _timeSlot,
    };
    
    debugPrint('=== FINAL SELL PAYLOAD ===');
    debugPrint(const JsonEncoder.withIndent('  ').convert(payload));
    debugPrint('==========================');
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );

      // Verify pincode serviceability first
      final pinRes = await ApiService().checkPincode(_pincodeController.text.trim());
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
          Navigator.pop(context); // close loader
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
        return;
      }

      await ApiService().submitSellRequest(payload);
      
      if (mounted) {
        Navigator.pop(context); // close loader
        showDialog(
          context: context,
          builder: (_) => const _SuccessDialog(),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final ctrl in _textControllers.values) {
      ctrl.dispose();
    }
    _upiController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _ifscController.dispose();
    _gstController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _altContactController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            _SellHeader(
              step: _step,
              onBack: _step > 0 ? () => setState(() => _step--) : null,
            ),
            _ProgressBar(step: _step),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _buildStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _UploadStep(
          key: const ValueKey(0),
          uploadedImages: _uploadedImageUrls,
          onImagesChanged: (urls) {
            setState(() {
              _uploadedImageUrls.clear();
              _uploadedImageUrls.addAll(urls);
            });
          },
          onNext: () => setState(() => _step = 1),
        );
      case 1:
        return ValueListenableBuilder<int>(
          valueListenable: _formUpdateNotifier,
          builder: (context, value, child) {
            return _DeviceDetailsStep(
              key: const ValueKey(1),
              categories: _apiCategories,
              isLoading: _isLoadingCategories,
              error: _categoriesError,
              selectedCategory: _selectedCategoryModel,
              onCategorySelect: (c) => setState(() {
                _selectedCategoryModel = c;
                _textControllers.clear();
                _dropdownValues.clear();
              }),
              textControllers: _textControllers,
              dropdownValues: _dropdownValues,
              onDropdownChange: (slug, value) {
                _dropdownValues[slug] = value;
                _formUpdateNotifier.value++;
              },
              estimatedPriceRange: _estimatedPriceRange,
              estimatedPrice: _estimatedPrice,
              termsAccepted: _termsAccepted,
              onTermsChanged: (v) {
                _termsAccepted = v;
                _formUpdateNotifier.value++;
              },
              priceAccepted: _priceAccepted,
              onPriceAcceptChanged: (v) {
                _priceAccepted = v;
                _formUpdateNotifier.value++;
              },
              onNext: (_termsAccepted && _priceAccepted && _allRequiredFilled)
                  ? () => setState(() => _step = 2)
                  : null,
            );
          },
        );
      case 2:
        return ValueListenableBuilder<int>(
          valueListenable: _formUpdateNotifier,
          builder: (context, value, child) {
            return _PaymentStep(
              key: const ValueKey(2),
              estimatedPrice: _estimatedPrice,
              category: _selectedCategoryModel?['name'] ?? '',
              hasGst: _hasGst,
              onGstChanged: (v) {
                _hasGst = v;
                _formUpdateNotifier.value++;
              },
              gstController: _gstController,
              paymentMethod: _paymentMethod,
              onPaymentMethodChanged: (v) {
                _paymentMethod = v;
                _formUpdateNotifier.value++;
              },
              upiController: _upiController,
              accountNameController: _accountNameController,
              accountNumberController: _accountNumberController,
              bankNameController: _bankNameController,
              ifscController: _ifscController,
              paymentReady: _paymentReady,
              onNext: _paymentReady ? () => setState(() => _step = 3) : null,
              onFieldChanged: () => _formUpdateNotifier.value++,
            );
          },
        );
      case 3:
        return ValueListenableBuilder<int>(
          valueListenable: _formUpdateNotifier,
          builder: (context, value, child) {
            return _ScheduleStep(
              key: const ValueKey(3),
              fullNameController: _fullNameController,
              emailController: _emailController,
              mobileController: _mobileController,
              altContactController: _altContactController,
              addressController: _addressController,
              areaController: _areaController,
              pincodeController: _pincodeController,
              pickupDate: _pickupDate,
              onDateChanged: (d) {
                _pickupDate = d;
                _formUpdateNotifier.value++;
              },
              timeSlot: _timeSlot,
              onTimeSlotChanged: (t) {
                _timeSlot = t;
                _formUpdateNotifier.value++;
              },
              scheduleReady: _scheduleReady,
              onSubmit: _scheduleReady ? _submitSellRequest : null,
              onFieldChanged: () => _formUpdateNotifier.value++,
            );
          },
        );
      default:
        return const SizedBox();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _SellHeader extends StatelessWidget {
  final int step;
  final VoidCallback? onBack;
  const _SellHeader({required this.step, this.onBack});

  static const _titles = [
    'Upload Photos',
    'Device Details',
    'Payment Details',
    'Schedule Pickup',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md,
      ),
      child: Row(
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            )
          else
            const SizedBox(width: 40),
          const Spacer(),
          Text(_titles[step], style: AppTextStyles.headingLarge),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS BAR
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int step;
  const _ProgressBar({required this.step});

  static const _labels = ['Upload', 'Details & Review', 'Payment', 'Schedule'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(4, (i) {
          final isLast = i == 3;
          return Container(
            width: 110,
            margin: EdgeInsets.only(right: isLast ? 0 : 6),
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= step ? AppColors.primary : AppColors.bgMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: i <= step
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 0 — UPLOAD PHOTOS
// ─────────────────────────────────────────────────────────────────────────────

class _UploadStep extends StatefulWidget {
  final VoidCallback onNext;
  final List<String> uploadedImages;
  final Function(List<String>) onImagesChanged;
  
  const _UploadStep({
    super.key, 
    required this.onNext,
    required this.uploadedImages,
    required this.onImagesChanged,
  });

  @override
  State<_UploadStep> createState() => _UploadStepState();
}

class _UploadStepState extends State<_UploadStep> {
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => _isUploading = true);
        
        final bytes = await pickedFile.readAsBytes();
        final contentType = pickedFile.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
        
        // 1. Get presigned URL
        final presignedRes = await ApiService().getPresignedUrl(pickedFile.name, contentType);
        final uploadUrl = presignedRes['uploadUrl'];
        final fileUrl = presignedRes['fileUrl'];
        
        // 2. Upload directly to S3
        await ApiService().uploadImageToS3(uploadUrl, bytes, contentType);
        
        // 3. Save URL to state
        final newImages = List<String>.from(widget.uploadedImages)..add(fileUrl);
        widget.onImagesChanged(newImages);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully!')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Item 1',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Upload Photos', style: AppTextStyles.headingMedium),
          const SizedBox(height: 16),

          // Upload Area
          GestureDetector(
            onTap: _isUploading ? null : () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (BuildContext context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Choose Photo Source', style: AppTextStyles.headingMedium),
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                          title: const Text('Open Camera'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                          title: const Text('Upload from Device'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              );
            },
            child: Container(
              width: double.infinity,
              height: 170,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withAlpha(128),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: AppColors.primary.withAlpha(102),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: _isUploading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.upload_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Tap to upload photos', style: AppTextStyles.headingMedium),
                        const SizedBox(height: 4),
                        const Text(
                          'PNG, JPG up to 10MB · Max 5 images',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
            ),
          ),
          if (widget.uploadedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.uploadedImages.map((url) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          final newImages = List<String>.from(widget.uploadedImages)..remove(url);
                          widget.onImagesChanged(newImages);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),

          // Photo tips
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.statusInfoBg,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_rounded, color: AppColors.statusInfo, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Photo Tips',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.statusInfo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...[
                  'Take photos in good lighting',
                  'Include front, back and sides',
                  'Show any damages or scratches clearly',
                ].map(
                      (t) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.statusInfo,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t,
                          style: const TextStyle(fontSize: 12, color: AppColors.statusInfo),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),


          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Next: Details & Review',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 — DEVICE DETAILS (category + fields + price + terms + CTA)
// ─────────────────────────────────────────────────────────────────────────────

class _DeviceDetailsStep extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? selectedCategory;
  final Function(Map<String, dynamic>) onCategorySelect;
  final Map<String, TextEditingController> textControllers;
  final Map<String, String> dropdownValues;
  final Function(String, String) onDropdownChange;
  final String estimatedPriceRange;
  final int estimatedPrice;
  final bool termsAccepted;
  final Function(bool) onTermsChanged;
  final bool priceAccepted;
  final Function(bool) onPriceAcceptChanged;
  final VoidCallback? onNext;

  const _DeviceDetailsStep({
    super.key,
    required this.categories,
    required this.isLoading,
    this.error,
    required this.selectedCategory,
    required this.onCategorySelect,
    required this.textControllers,
    required this.dropdownValues,
    required this.onDropdownChange,
    required this.estimatedPriceRange,
    required this.estimatedPrice,
    required this.termsAccepted,
    required this.onTermsChanged,
    required this.priceAccepted,
    required this.onPriceAcceptChanged,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category Grid ──────────────────────────────────────────────
          const Text(
            'Select Category',
            style: AppTextStyles.headingMedium,
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.85,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat = categories[i];
                final isSelected = selectedCategory?['id'] == cat['id'];
                return GestureDetector(
                  onTap: () => onCategorySelect(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryLight : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(cat['emoji'] ?? '', style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          cat['name'] ?? '',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primaryDark
                                : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 20),

          // ── AI Price Estimate Banner ───────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.primary.withAlpha(77)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Price Estimate',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          selectedCategory == null
                              ? 'Select a category and fill details to see estimate'
                              : 'Based on your inputs: $estimatedPriceRange',
                          key: ValueKey(estimatedPriceRange),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryDark.withAlpha(179),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Form Fields ────────────────────────────────────────────────
          if (selectedCategory != null)
            ...(selectedCategory!['attributes'] as List<dynamic>? ?? []).map((attrObj) {
              final attr = attrObj as Map<String, dynamic>;
              final isRequired = attr['isRequired'] == true;
              final name = attr['name'] ?? '';
              final slug = attr['slug'] ?? '';
              final inputType = attr['inputType'] ?? 'text';
              final options = (attr['options'] as List<dynamic>? ?? []).cast<String>();

              if (inputType == 'dropdown') {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: name,
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                        children: [
                          if (isRequired)
                            const TextSpan(
                              text: ' *',
                              style: TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: dropdownValues[slug],
                      items: options
                          .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                          .toList(),
                      onChanged: (v) => v != null ? onDropdownChange(slug, v) : null,
                      decoration: InputDecoration(
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
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                );
              } else {
                TextEditingController ctrl = textControllers.putIfAbsent(slug, () => TextEditingController());
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: name,
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                        children: [
                          if (isRequired)
                            const TextSpan(
                              text: ' *',
                              style: TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: ctrl,
                      onChanged: (v) => onDropdownChange(slug, v),
                      decoration: InputDecoration(
                        hintText: 'Enter $name',
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
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                );
              }
            }),
          const SizedBox(height: 6),

          // ── Total Estimated Value card ─────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'TOTAL ESTIMATED VALUE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: estimatedPrice == 0
                      ? Text(
                    '0 item(s)',
                    key: const ValueKey('zero'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  )
                      : Column(
                    key: ValueKey(estimatedPrice),
                    children: [
                      Text(
                        '₹${estimatedPrice >= 1000 ? '${estimatedPrice ~/ 1000},${(estimatedPrice % 1000).toString().padLeft(3, '0')}' : estimatedPrice}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        estimatedPriceRange,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1 item(s) — ${selectedCategory?['name'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (estimatedPrice == 0)
                  const Text(
                    'Fill in item details to see pricing here.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Terms & Conditions ────────────────────────────────────────
          _CheckboxCard(
            checked: termsAccepted,
            onChanged: onTermsChanged,
            title: 'I agree to the terms & conditions',
            bullets: const [
              'Lift unavailable: labour charges may apply.',
              'Items above 10 kg may incur extra charges.',
              'Pickup charges may apply.',
              'Final price may vary after physical inspection.',
            ],
          ),
          const SizedBox(height: 10),

          // ── Accept Quoted Price ────────────────────────────────────────
          _CheckboxCard(
            checked: priceAccepted,
            onChanged: onPriceAcceptChanged,
            title: 'I accept the quoted price and request to schedule the pickup.',
            bullets: const [],
            highlight: true,
          ),
          const SizedBox(height: 20),

          // ── CTA ───────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: onNext != null ? AppColors.primary : AppColors.bgMuted,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Next: Bank Details',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 — PAYMENT DETAILS
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentStep extends StatelessWidget {
  final int estimatedPrice;
  final String category;
  final bool hasGst;
  final Function(bool) onGstChanged;
  final TextEditingController gstController;
  final String paymentMethod;
  final Function(String) onPaymentMethodChanged;
  final TextEditingController upiController;
  final TextEditingController accountNameController;
  final TextEditingController accountNumberController;
  final TextEditingController bankNameController;
  final TextEditingController ifscController;
  final bool paymentReady;
  final VoidCallback? onNext;
  final VoidCallback onFieldChanged;

  const _PaymentStep({
    super.key,
    required this.estimatedPrice,
    required this.category,
    required this.hasGst,
    required this.onGstChanged,
    required this.gstController,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
    required this.upiController,
    required this.accountNameController,
    required this.accountNumberController,
    required this.bankNameController,
    required this.ifscController,
    required this.paymentReady,
    this.onNext,
    required this.onFieldChanged,
  });

  String _fmt(int n) {
    if (n >= 1000) {
      return '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary card ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TOTAL ESTIMATED VALUE', style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                )),
                const SizedBox(height: 8),
                Text(
                  '₹${_fmt(estimatedPrice)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'approx. ₹${_fmt(estimatedPrice)} Rupees',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '₹${_fmt(estimatedPrice)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── GST Toggle ────────────────────────────────────────────────
          _CheckboxCard(
            checked: hasGst,
            onChanged: onGstChanged,
            title: 'I have a GST number (optional)',
            bullets: const [],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(
                    'Quoted price is inclusive of 18% GST.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (hasGst) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: gstController,
                    onChanged: (_) => onFieldChanged(),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '22AAAAA0000A1Z5',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.bgPage,
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
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Base amount', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text('—', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('GST (18%, included)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text('—', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total (inclusive)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      Text('—', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Payment Method Title ───────────────────────────────────────
          const Text(
            'Payment Details',
            style: AppTextStyles.headingMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose how you\'d like to receive your payment',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 24),

          // ── UPI ───────────────────────────────────────────────────────
          _PaymentMethodCard(
            selected: paymentMethod == 'upi',
            onTap: () => onPaymentMethodChanged('upi'),
            badge: 'RECOMMENDED · INSTANT',
            icon: Icons.flash_on_rounded,
            title: 'Pay via UPI',
            subtitle: 'Fastest way — get paid within minutes after pickup verification.',
            child: paymentMethod == 'upi'
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text('UPI ID', style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                )),
                const SizedBox(height: 6),
                TextField(
                  controller: upiController,
                  onChanged: (_) => onFieldChanged(),
                  decoration: InputDecoration(
                    hintText: 'yourname@upi / 9876543210@paytm',
                    hintStyle: const TextStyle(fontSize: 12),
                    filled: true,
                    fillColor: AppColors.bgPage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Supports GPay, PhonePe, Paytm, BHIM and any UPI app.',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            )
                : null,
          ),
          const SizedBox(height: 12),

          // Divider
          const Row(children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('OR', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ),
            Expanded(child: Divider()),
          ]),
          const SizedBox(height: 12),

          // ── Bank Transfer ─────────────────────────────────────────────
          _PaymentMethodCard(
            selected: paymentMethod == 'bank',
            onTap: () => onPaymentMethodChanged('bank'),
            icon: Icons.account_balance_rounded,
            title: 'Bank Account Transfer',
            subtitle: 'Receive payment via NEFT/IMPS in 1-2 business days.',
            child: paymentMethod == 'bank'
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _BankField(
                    label: 'Account Holder Name',
                    hint: 'Full name as per bank',
                    controller: accountNameController,
                    onChanged: onFieldChanged,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _BankField(
                    label: 'Bank Name',
                    hint: 'e.g. State Bank of India',
                    controller: bankNameController,
                    onChanged: onFieldChanged,
                  )),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _BankField(
                    label: 'Account Number',
                    hint: 'Enter account number',
                    controller: accountNumberController,
                    onChanged: onFieldChanged,
                    keyboardType: TextInputType.number,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _BankField(
                    label: 'IFSC Code',
                    hint: 'e.g. SBIN0001234',
                    controller: ifscController,
                    onChanged: onFieldChanged,
                  )),
                ]),
                const SizedBox(height: 6),
                const Text(
                  'Required only if you choose bank transfer instead of UPI.',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            )
                : null,
          ),
          const SizedBox(height: 12),

          // Divider
          const Row(children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('OR REDEEM VOUCHER', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ),
            Expanded(child: Divider()),
          ]),
          const SizedBox(height: 12),

          // ── Gift Voucher ──────────────────────────────────────────────
          _PaymentMethodCard(
            selected: paymentMethod == 'voucher',
            onTap: () => onPaymentMethodChanged('voucher'),
            icon: Icons.card_giftcard_rounded,
            iconColor: AppColors.statusSuccess,
            iconBg: AppColors.statusSuccessBg,
            title: 'Redeem as Gift Voucher',
            subtitle: 'Get up to 5% extra value when you choose a voucher instead of cash.',
            hideRadio: true,
            showChevron: true,
            child: paymentMethod == 'voucher' ? Padding(
              padding: const EdgeInsets.only(top: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 6,
                itemBuilder: (context, i) {
                  final v = const [
                    ('Amazon Pay', '🛒', Color(0xFFF3EED9)),
                    ('Flipkart', '🛍️', Color(0xFFDFE6F5)),
                    ('Myntra', '👗', Color(0xFFF3E0E5)),
                    ('BigBasket', '🛒', Color(0xFFDDF2E7)),
                    ('Swiggy Money', '🍔', Color(0xFFF5E4DE)),
                    ('Croma', '📱', Color(0xFFDEF2E8)),
                  ][i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: v.$3,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(v.$2, style: const TextStyle(fontSize: 18)),
                        const Spacer(),
                        Text(v.$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        Text('₹${_fmt((estimatedPrice * 1.05).round())}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  );
                },
              ),
            ) : null,
          ),
          const SizedBox(height: 20),

          // ── Total + CTA ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Estimated', style: AppTextStyles.bodyMedium),
              Text(
                '₹${_fmt(estimatedPrice)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: const Text(
                'Submit & Schedule Pickup',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: onNext != null ? AppColors.primary : AppColors.bgMuted,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
          ),
          if (!paymentReady)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Pick a gift voucher above, or provide UPI ID / bank details to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 3 — SCHEDULE & PICKUP
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleStep extends StatelessWidget {
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final TextEditingController altContactController;
  final TextEditingController addressController;
  final TextEditingController areaController;
  final TextEditingController pincodeController;
  final DateTime? pickupDate;
  final Function(DateTime) onDateChanged;
  final String? timeSlot;
  final Function(String?) onTimeSlotChanged;
  final bool scheduleReady;
  final VoidCallback? onSubmit;
  final VoidCallback onFieldChanged;

  const _ScheduleStep({
    super.key,
    required this.fullNameController,
    required this.emailController,
    required this.mobileController,
    required this.altContactController,
    required this.addressController,
    required this.areaController,
    required this.pincodeController,
    required this.pickupDate,
    required this.onDateChanged,
    required this.timeSlot,
    required this.onTimeSlotChanged,
    required this.scheduleReady,
    this.onSubmit,
    required this.onFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fill in your details and choose a time slot.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 20),

          // ── Contact & Address ─────────────────────────────────────────
          _SectionHeader(
            icon: Icons.location_on_rounded,
            label: 'Contact & Address',
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _ScheduleField(
              label: 'Full Name',
              hint: 'John Doe',
              controller: fullNameController,
              onChanged: onFieldChanged,
            )),
            const SizedBox(width: 10),
            Expanded(child: _ScheduleField(
              label: 'Email',
              hint: 'john@example.com',
              controller: emailController,
              onChanged: onFieldChanged,
              keyboardType: TextInputType.emailAddress,
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _ScheduleField(
              label: 'Mobile Number',
              hint: '+91 98765 43210',
              controller: mobileController,
              onChanged: onFieldChanged,
              keyboardType: TextInputType.phone,
            )),
            const SizedBox(width: 10),
            Expanded(child: _ScheduleField(
              label: 'Alternate Contact',
              hint: 'Optional',
              controller: altContactController,
              onChanged: onFieldChanged,
              keyboardType: TextInputType.phone,
            )),
          ]),
          const SizedBox(height: 12),
          _ScheduleField(
            label: 'Pickup Address',
            hint: 'Full address',
            controller: addressController,
            onChanged: onFieldChanged,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _ScheduleField(
              label: 'Area / Landmark',
              hint: 'Near city mall',
              controller: areaController,
              onChanged: onFieldChanged,
            )),
            const SizedBox(width: 10),
            Expanded(child: _ScheduleField(
              label: 'Pincode',
              hint: '400001',
              controller: pincodeController,
              onChanged: onFieldChanged,
              keyboardType: TextInputType.number,
            )),
          ]),
          const SizedBox(height: 24),

          // ── Schedule ──────────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.schedule_rounded,
            label: 'Schedule',
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pickup Date', style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  )),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: now.add(const Duration(days: 1)),
                        firstDate: now.add(const Duration(days: 1)),
                        lastDate: now.add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        onDateChanged(picked);
                        onFieldChanged();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Text(
                            pickupDate == null
                                ? 'dd/mm/yyyy'
                                : '${pickupDate!.day.toString().padLeft(2, '0')}/${pickupDate!.month.toString().padLeft(2, '0')}/${pickupDate!.year}',
                            style: TextStyle(
                              fontSize: 13,
                              color: pickupDate == null
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Time Slot', style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  )),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: timeSlot,
                    hint: const Text('Select time slot',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    items: [
                      '9:00 AM – 12:00 PM',
                      '12:00 PM – 3:00 PM',
                      '3:00 PM – 6:00 PM',
                    ]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      onTimeSlotChanged(v);
                      onFieldChanged();
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.bgCard,
                      isDense: true,
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
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: const Text(
                'Confirm Pickup',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: onSubmit != null ? AppColors.primary : AppColors.bgMuted,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _CheckboxCard extends StatelessWidget {
  final bool checked;
  final Function(bool) onChanged;
  final String title;
  final List<String> bullets;
  final bool highlight;
  final Widget? child;

  const _CheckboxCard({
    required this.checked,
    required this.onChanged,
    required this.title,
    required this.bullets,
    this.highlight = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: checked && highlight
              ? AppColors.primaryLight.withAlpha(128)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: checked ? AppColors.primary : AppColors.border,
            width: checked ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: checked ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: checked ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  ...bullets.map((b) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '• $b',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )),
                  ?child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBg;
  final String title;
  final String subtitle;
  final Widget? child;
  final bool hideRadio;
  final bool showChevron;

  const _PaymentMethodCard({
    required this.selected,
    required this.onTap,
    this.badge,
    required this.icon,
    this.iconColor,
    this.iconBg,
    required this.title,
    required this.subtitle,
    this.child,
    this.hideRadio = false,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight.withValues(alpha: 0.4) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg ?? AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!hideRadio)
                  Icon(
                    showChevron
                        ? (selected ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded)
                        : (selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
                    color: selected && !showChevron ? AppColors.primary : AppColors.textSecondary,
                    size: 20,
                  ),
              ],
            ),
            ?child,
          ],
        ),
      ),
    );
  }
}

class _BankField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final TextInputType? keyboardType;

  const _BankField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        )),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: AppColors.bgPage,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final TextInputType? keyboardType;

  const _ScheduleField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        )),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
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
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.headingMedium),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUCCESS DIALOG
// ─────────────────────────────────────────────────────────────────────────────

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
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Request Submitted! 🎉',
              style: AppTextStyles.headingLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your pickup has been scheduled. We\'ll come to collect your device within 48 hours.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Request ID: REQ-1025',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Track Request',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}