import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/core/services/api_service.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  String _selectedType = 'Home';
  bool _isDefault = false;
  bool _isSaving = false;
  bool _isFetchingLocation = false;

  bool? _isPincodeServiceable;
  bool _isCheckingPincode = false;
  String _pincodeErrorMsg = '';

  List<dynamic> _cities = [];
  bool _isLoadingCities = false;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    setState(() => _isLoadingCities = true);
    try {
      final res = await ApiService().getCities();
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _cities = data;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading cities: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingCities = false);
      }
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final Geocoding geocoding = Geocoding();
      List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        setState(() {
          _addressController.text = '${place.street ?? ''}, ${place.subLocality ?? ''}'.trim().replaceAll(RegExp(r'^,\s*'), '');
          _cityController.text = place.locality ?? '';
          _stateController.text = place.administrativeArea ?? '';
          _pincodeController.text = place.postalCode ?? '';
          _selectedCity = place.locality;
        });
        
        if (_pincodeController.text.isNotEmpty) {
           _onPincodeChanged(_pincodeController.text);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  void _onPincodeChanged(String value) async {
    if (value.length == 6) {
      setState(() {
        _isCheckingPincode = true;
        _isPincodeServiceable = null;
      });
      
      final pinRes = await ApiService().checkPincode(value.trim());
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
    } else {
      if (_isPincodeServiceable != null || _isCheckingPincode) {
        setState(() {
          _isCheckingPincode = false;
          _isPincodeServiceable = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    bool isCityValid = _selectedCity != null && _selectedCity!.trim().isNotEmpty;
    bool isFormValid = _formKey.currentState!.validate();
    
    if (!isCityValid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a city')));
      return;
    }
    if (!isFormValid) return;
    
    if (_isPincodeServiceable != true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid, serviceable 6-digit pincode.')));
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      await ApiService().addAddress({
        'addressLine': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'postalCode': _pincodeController.text.trim(),
        'addressType': _selectedType,
        'isDefault': _isDefault,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address added successfully!')));
        Navigator.pop(context, true); // Return true to signal refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add address: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Add New Address'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: AppTextStyles.headingMedium.copyWith(fontSize: 20, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
                icon: _isFetchingLocation 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location),
                label: const Text('Use Current Location'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel('Pickup Address *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                maxLines: 4,
                decoration: _inputDecoration('Street name, landmark, building number, etc.'),
                validator: (v) => v!.trim().isEmpty ? 'Please enter your address' : null,
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Pincode *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _pincodeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          onChanged: _onPincodeChanged,
                          decoration: _inputDecoration('e.g. 411052').copyWith(counterText: ''),
                          validator: (v) {
                            if (v!.trim().isEmpty) return 'Required';
                            if (v.trim().length != 6) return '6 digits required';
                            return null;
                          },
                        ),
                        if (_isCheckingPincode) ...[
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 4),
                              Expanded(child: Text('Checking...', style: TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                            ],
                          ),
                        ] else if (_isPincodeServiceable == true) ...[
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.green, size: 12),
                              SizedBox(width: 4),
                              Expanded(child: Text('Serviceable', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ] else if (_isPincodeServiceable == false) ...[
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.cancel_rounded, color: Colors.red, size: 12),
                              const SizedBox(width: 4),
                              Expanded(child: Text(_pincodeErrorMsg, style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('City *'),
                        const SizedBox(height: 8),
                        _isLoadingCities
                            ? const SizedBox(
                                height: 50,
                                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                              )
                            : DropdownMenu<String>(
                                initialSelection: _selectedCity,
                                expandedInsets: EdgeInsets.zero,
                                hintText: 'Select City',
                                onSelected: (value) {
                                  setState(() {
                                    _selectedCity = value;
                                    _cityController.text = value ?? '';
                                  });
                                },
                                dropdownMenuEntries: _cities.map((city) {
                                  final cityName = city['name']?.toString() ?? '';
                                  return DropdownMenuEntry<String>(
                                    value: cityName,
                                    label: cityName,
                                  );
                                }).toList(),
                                inputDecorationTheme: InputDecorationTheme(
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
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

              const SizedBox(height: 20),

              _buildLabel('State *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _stateController,
                decoration: _inputDecoration('e.g. Maharashtra'),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 20),

              _buildLabel('Address Type *'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildTypeButton('Home')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTypeButton('Office')),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _isDefault,
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _isDefault = v);
                        }
                      },
                      activeColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Set as default address', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                ],
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Address', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _buildTypeButton(String type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
        ),
        alignment: Alignment.center,
        child: Text(
          type,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
