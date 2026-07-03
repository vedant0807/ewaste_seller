import 'package:flutter/material.dart';
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
  late TextEditingController _addressController;
  late TextEditingController _pincodeController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;

  late String _selectedType;
  late bool _isDefault;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.address['addressLine']?.toString() ?? '');
    _pincodeController = TextEditingController(text: widget.address['postalCode']?.toString() ?? '');
    _cityController = TextEditingController(text: widget.address['city']?.toString() ?? '');
    _stateController = TextEditingController(text: widget.address['state']?.toString() ?? '');

    String type = (widget.address['addressType']?.toString() ?? 'Home');
    _selectedType = type.toLowerCase() == 'office' ? 'Office' : 'Home';
    _isDefault = widget.address['isDefault'] == true || widget.address['isDefault'] == 1 || widget.address['isDefault'] == 'true';
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
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final addressId = widget.address['id'];
      if (addressId == null) {
        throw Exception("Address ID is missing");
      }

      await ApiService().editAddress(
        int.parse(addressId.toString()),
        {
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
                        TextFormField(
                          controller: _cityController,
                          decoration: _inputDecoration('e.g. Pune'),
                          validator: (v) => v!.trim().isEmpty ? 'Required' : null,
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
