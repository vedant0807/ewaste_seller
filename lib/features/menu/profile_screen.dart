import 'package:flutter/material.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/core/services/api_service.dart';
import 'package:seller_ewaste/features/menu/my_addresses_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().getProfile();
      if (mounted) {
        setState(() {
          _profileData = data;
          _isLoading = false;
          _nameController.text = _profileData?['username'] ?? '';
          _emailController.text = _profileData?['email'] ?? '';
          _phoneController.text = _profileData?['phoneNumber'] ?? '';
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
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: AppTextStyles.headingMedium.copyWith(fontSize: 20, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildContent(),
      bottomNavigationBar: (!_isLoading && _error == null) ? _buildBottomBar() : null,
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveProfile,
          icon: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check_circle_outline_rounded, size: 20),
          label: Text(_isSaving ? 'Saving...' : 'Save Profile Changes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await ApiService().updateProfile({
        'name': _nameController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneController.text,
        'bankDetails': {
          'accountHolderName': '',
          'bankName': '',
          'accountNumber': '',
          'ifscCode': '',
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
        _fetchProfile(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Widget _buildContent() {
    final username = _profileData?['username'] ?? 'User';
    final email = _profileData?['email'] ?? 'Not provided';
    final phoneNumber = _profileData?['phoneNumber'] ?? 'Not provided';

    // Commented out Bank Details as requested
    /*
    final banks = _profileData?['bankAccounts'] as List<dynamic>? ?? [];
    final Map<String, dynamic> defaultBank = banks.isNotEmpty ? banks[0] : {};
    */

    final addresses = _profileData?['addresses'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F6), // Very light green bg
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Initials Box
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _getInitials(username),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(phoneNumber, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(child: Text(email, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // 2. Update Basic Details
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    const Text('Update Basic Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField('Full Name *', _nameController),
                const SizedBox(height: 16),
                _buildTextField('Email Address *', _emailController),
                const SizedBox(height: 16),
                _buildTextField('Mobile Number', _phoneController, readOnly: true),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // 3. Saved Addresses
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primary),
                        const SizedBox(width: 12),
                        const Text('Saved Addresses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyAddressesScreen()),
                        );
                        if (res == true && mounted) {
                          _fetchProfile(); // Refresh list if changes were made
                        }
                      },
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      label: const Text('Manage'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (addresses.isEmpty)
                  const Text('No saved addresses found.', style: TextStyle(color: AppColors.textSecondary))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: addresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final addr = addresses[index];
                      final isDefault = addr['isDefault'] == true;
                      
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDefault ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDefault ? const Color(0xFF86EFAC) : Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    (addr['addressType'] ?? 'HOME').toString().toUpperCase(),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                  ),
                                ),
                                if (isDefault)
                                  const Text('Default', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              addr['addressLine'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${addr['city'] ?? ''}, ${addr['state'] ?? ''} - ${addr['postalCode'] ?? ''}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () {},
                                      child: const Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                                          SizedBox(width: 4),
                                          Text('Edit', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    InkWell(
                                      onTap: () {},
                                      child: const Row(
                                        children: [
                                          Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.textSecondary),
                                          SizedBox(width: 4),
                                          Text('Delete', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (!isDefault)
                                  OutlinedButton(
                                    onPressed: () {},
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('Set Default', style: TextStyle(fontSize: 11)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),
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
      border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC), // very light gray as in screenshot
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
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
