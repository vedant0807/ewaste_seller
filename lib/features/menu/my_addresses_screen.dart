import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/core/services/api_service.dart';
import 'package:seller_ewaste/features/menu/add_address_screen.dart';
import 'package:seller_ewaste/features/menu/edit_address_screen.dart';

class MyAddressesScreen extends StatefulWidget {
  final bool isSelectionMode;
  const MyAddressesScreen({super.key, this.isSelectionMode = false});

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  List<dynamic> _addresses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().getProfile();
      if (mounted) {
        setState(() {
          _addresses = data['addresses'] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load addresses';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAddress(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiService().deleteAddress(id);
      if (mounted) {
        Fluttertoast.showToast(msg: 'Address deleted successfully');
      }
      _fetchAddresses();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete address: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Addresses'),
        backgroundColor: AppColors.primary, // Using app's primary instead of screenshot's blue to maintain consistency
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: AppTextStyles.headingMedium.copyWith(fontSize: 20, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddAddressScreen()),
                      );
                      if (res == true && mounted) {
                        _fetchAddresses();
                      }
                    },
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add New Address', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // TextField(
                //   decoration: InputDecoration(
                //     hintText: 'Search Address',
                //     prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                //     filled: true,
                //     fillColor: Colors.white,
                //     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                //     border: InputBorder.none,
                //     enabledBorder: InputBorder.none,
                //     focusedBorder: InputBorder.none,
                //   ),
                // ),
                const Divider(height: 1),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _addresses.isEmpty
                        ? const Center(child: Text('No addresses found.', style: TextStyle(color: AppColors.textSecondary)))
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: _addresses.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final addr = _addresses[index];
                              return InkWell(
                                onTap: widget.isSelectionMode
                                    ? () {
                                        Navigator.pop(context, addr);
                                      }
                                    : null,
                                child: Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.red, size: 28),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  (addr['addressType'] ?? 'HOME').toString().toUpperCase(),
                                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                                                ),
                                                if (addr['isDefault'] == true) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Text('DEFAULT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${addr['addressLine'] ?? ''}, ${addr['city'] ?? ''}, ${addr['state'] ?? ''} - ${addr['postalCode'] ?? ''}',
                                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () async {
                                          final res = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditAddressScreen(
                                                address: addr as Map<String, dynamic>,
                                              ),
                                            ),
                                          );
                                          if (res == true && mounted) {
                                            _fetchAddresses();
                                          }
                                        },
                                        icon: const Icon(Icons.edit, size: 20, color: AppColors.textPrimary),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () {
                                          if (addr['id'] != null) {
                                            _deleteAddress(int.parse(addr['id'].toString()));
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Cannot delete address: ID missing')),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.delete, size: 20, color: AppColors.red),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
