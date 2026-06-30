import 'package:flutter/material.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/core/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await ApiService().getProfile();
      if (mounted) {
        setState(() {
          _profileData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Profile fetch error: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile data';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.headingMedium.copyWith(fontSize: 22),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final username = _profileData?['username'] ?? '';
    final email = _profileData?['email'] ?? '';
    final phoneNumber = _profileData?['phoneNumber'] ?? '';

    // Extract first bank account if available
    final banks = _profileData?['bankAccounts'] as List<dynamic>? ?? [];
    final Map<String, dynamic> defaultBank = banks.isNotEmpty ? banks[0] : {};

    // Extract default address
    final addresses = _profileData?['addresses'] as List<dynamic>? ?? [];
    Map<String, dynamic> defaultAddress = {};
    for (var addr in addresses) {
      if (addr['isDefault'] == true) {
        defaultAddress = addr;
        break;
      }
    }
    if (defaultAddress.isEmpty && addresses.isNotEmpty) {
      defaultAddress = addresses[0];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage your account details.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Personal Information Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(Icons.person_outline_rounded, 'Personal Information'),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Change Photo', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Full Name', username)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Email', email)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Mobile', phoneNumber)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('PAN Number', 'Not provided')), // Placeholder as per API
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bank Details Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(Icons.account_balance_rounded, 'Bank Details', iconBgColor: AppColors.primary.withValues(alpha: 0.15), iconColor: AppColors.primary),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Account Holder Name', defaultBank['accountHolderName']?.isEmpty == false ? defaultBank['accountHolderName'] : 'As per bank records')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Account Number', defaultBank['accountNumber']?.isEmpty == false ? defaultBank['accountNumber'] : 'XXXXXXXXXXXXX')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('IFSC Code', defaultBank['ifscCode']?.isEmpty == false ? defaultBank['ifscCode'] : 'SBIN0001234')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('UPI ID', 'Not provided')), // Placeholder
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Saved Addresses Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(Icons.location_on_outlined, 'Saved Addresses', iconBgColor: const Color(0xFFFDE68A), iconColor: const Color(0xFFD97706)),
                const SizedBox(height: 24),
                if (defaultAddress.isEmpty)
                  const Text('No saved addresses found.', style: TextStyle(color: AppColors.textSecondary))
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.home_work_outlined, color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    (defaultAddress['addressType'] ?? 'Home').toString().toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.textPrimary),
                                  ),
                                  if (defaultAddress['isDefault'] == true) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('DEFAULT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${defaultAddress['addressLine'] ?? ''}, ${defaultAddress['city'] ?? ''}, ${defaultAddress['state'] ?? ''} ${defaultAddress['postalCode'] ?? ''}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
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
    );
  }

  Widget _buildCardHeader(IconData icon, String title, {Color? iconBgColor, Color? iconColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor ?? AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String value) {
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
          initialValue: value,
          readOnly: true, // Making it read-only for now since it's just displaying fetched data
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
