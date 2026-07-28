import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/core/services/api_service.dart';

class EditAddressScreen extends StatefulWidget {
  final Map<String, dynamic> address;

  const EditAddressScreen({super.key, required this.address});

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _contactNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _pincodeController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;

  late String _selectedType;
  late bool _isDefault;
  bool _isSaving = false;
  bool _isFetchingLocation = false;

  List<dynamic> _cities = [];
  bool _isLoadingCities = false;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _contactNameController = TextEditingController(text: widget.address['contactName']?.toString() ?? '');
    _phoneNumberController = TextEditingController(text: widget.address['phoneNumber']?.toString() ?? '');
    _emailController = TextEditingController(text: widget.address['email']?.toString() ?? '');
    _addressController = TextEditingController(text: widget.address['addressLine']?.toString() ?? '');
    _pincodeController = TextEditingController(text: widget.address['postalCode']?.toString() ?? '');
    _cityController = TextEditingController(text: widget.address['city']?.toString() ?? '');
    _stateController = TextEditingController(text: widget.address['state']?.toString() ?? '');

    String type = (widget.address['addressType']?.toString() ?? 'Home');
    _selectedType = type.toLowerCase() == 'office' ? 'Office' : 'Home';
    _isDefault = widget.address['isDefault'] == true || widget.address['isDefault'] == 1 || widget.address['isDefault'] == 'true';
    
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
            final currentCity = _cityController.text.trim();
            if (currentCity.isNotEmpty) {
              final matchedCity = _cities.where((c) => (c['name']?.toString() ?? '').toLowerCase() == currentCity.toLowerCase()).firstOrNull;
              if (matchedCity != null) {
                _selectedCity = matchedCity['name']?.toString();
                _cityController.text = _selectedCity!;
              } else {
                _cities.insert(0, {'id': 'custom', 'name': currentCity});
                _selectedCity = currentCity;
              }
            }
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
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  @override
  void dispose() {
    _contactNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
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
    
    setState(() => _isSaving = true);
    
    try {
      final addressId = widget.address['id'];
      if (addressId == null) {
        throw Exception("Address ID is missing");
      }

      await ApiService().editAddress(
        int.parse(addressId.toString()),
        {
          'contactName': _contactNameController.text.trim(),
          'phoneNumber': _phoneNumberController.text.trim(),
          'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          'addressLine': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'postalCode': _pincodeController.text.trim(),
          'addressType': _selectedType.toLowerCase(),
          'isDefault': _isDefault,
        }
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address updated successfully!')));
        Navigator.pop(context, true); // Return true to signal refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update address: $e')));
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
        title: const Text('Edit Address'),
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

              // ── Pickup Contact ─────────────────────────────────────
              _buildLabel('Pickup Contact Name *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration('e.g. Ravi Kumar'),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Phone Number *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneNumberController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: _inputDecoration('10-digit number').copyWith(counterText: ''),
                          validator: (v) {
                            if (v!.trim().isEmpty) return 'Required';
                            if (!RegExp(r'^\d{10}$').hasMatch(v.trim())) return '10 digits';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Email (optional)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration('email@example.com'),
                        ),
                      ],
                    ),
                  ),
                ],
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
                          decoration: _inputDecoration('e.g. 411052'),
                          validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                        ),
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
                        : const Text('Update Address', style: TextStyle(fontWeight: FontWeight.bold)),
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
