import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:seller_ewaste/core/services/api_service.dart';
import 'package:seller_ewaste/features/menu/my_addresses_screen.dart';
import 'package:seller_ewaste/features/menu/edit_address_screen.dart';
import 'package:seller_ewaste/core/utils/validators.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/theme/app_theme.dart';

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
    final emailError = Validators.validateEmail(_emailController.text);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(emailError)));
      return;
    }

    // Phone is technically read-only based on code, but just in case:
    final phoneError = Validators.validateMobile(_phoneController.text);
    if (phoneError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(phoneError)));
      return;
    }

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

  Future<void> _deleteUpi(int id) async {
    try {
      await ApiService().deleteUpiAccount(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID deleted successfully')));
        _fetchProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete UPI ID')));
      }
    }
  }

  Future<void> _setDefaultUpi(Map<String, dynamic> upi) async {
    setState(() => _isLoading = true);
    try {
      final payload = {
        'upiId': upi['upiId'],
        'label': upi['label'],
        'isDefault': true,
      };
      await ApiService().editUpiAccount(int.parse(upi['id'].toString()), payload);
      if (mounted) {
        _fetchProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to set default UPI ID')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showUpiDialog([Map<String, dynamic>? upi]) {
    final isEdit = upi != null;
    final upiIdController = TextEditingController(text: isEdit ? upi['upiId'] : '');
    final labelController = TextEditingController(text: isEdit ? upi['label'] : '');
    bool isDefault = isEdit ? (upi['isDefault'] ?? false) : false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEdit ? 'Edit UPI ID' : 'Add New UPI ID', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('UPI ID *', upiIdController),
                    const SizedBox(height: 16),
                    _buildTextField('Label (Optional)', labelController, hint: 'e.g. Personal, GPay, PhonePe'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: isDefault,
                          onChanged: (val) {
                            setModalState(() => isDefault = val ?? false);
                          },
                          activeColor: AppColors.primary,
                        ),
                        const Text('Set as default UPI ID', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final upiError = Validators.validateUpi(upiIdController.text.trim());
                    if (upiError != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(upiError)));
                      return;
                    }
                    
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    
                    try {
                      final payload = {
                        'upiId': upiIdController.text.trim(),
                        'label': labelController.text.trim(),
                        'isDefault': isDefault,
                      };
                      
                      if (isEdit) {
                        await ApiService().editUpiAccount(int.parse(upi['id'].toString()), payload);
                      } else {
                        await ApiService().addUpiAccount(payload);
                      }
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'UPI updated successfully' : 'UPI added successfully')));
                        _fetchProfile();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save UPI ID')));
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Save UPI ID', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteGst(int id) async {
    try {
      await ApiService().deleteGstNumber(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GST number deleted successfully')));
        _fetchProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete GST number')));
      }
    }
  }

  Future<void> _setDefaultGst(Map<String, dynamic> gst) async {
    setState(() => _isLoading = true);
    try {
      final payload = {
        'gstNumber': gst['gstNumber'],
        'label': gst['label'],
        'isDefault': true,
      };
      await ApiService().editGstNumber(int.parse(gst['id'].toString()), payload);
      if (mounted) {
        _fetchProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to set default GST number')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showGstDialog([Map<String, dynamic>? gst]) {
    final isEdit = gst != null;
    final gstNumberController = TextEditingController(text: isEdit ? gst['gstNumber'] : '');
    final labelController = TextEditingController(text: isEdit ? gst['label'] : '');
    bool isDefault = isEdit ? (gst['isDefault'] ?? false) : false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEdit ? 'Edit GST Number' : 'Add New GST Number', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('GST Number *', gstNumberController, hint: 'e.g. 22AAAAA0000A1Z5'),
                    const SizedBox(height: 16),
                    _buildTextField('Label (Optional)', labelController, hint: 'e.g. Business, Branch Office'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: isDefault,
                          onChanged: (val) {
                            setModalState(() => isDefault = val ?? false);
                          },
                          activeColor: AppColors.primary,
                        ),
                        const Text('Set as default GST number', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final gstError = Validators.validateGst(gstNumberController.text.trim());
                    if (gstError != null) {
                      Fluttertoast.showToast(msg: gstError, backgroundColor: Colors.red);
                      return;
                    }
                    
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    
                    try {
                      final payload = {
                        'gstNumber': gstNumberController.text.trim().toUpperCase(),
                        'label': labelController.text.trim(),
                        'isDefault': isDefault,
                      };
                      
                      if (isEdit) {
                        await ApiService().editGstNumber(int.parse(gst['id'].toString()), payload);
                      } else {
                        await ApiService().addGstNumber(payload);
                      }
                      
                      if (mounted) {
                        Fluttertoast.showToast(msg: isEdit ? 'GST number updated successfully' : 'GST number added successfully', backgroundColor: Colors.green);
                        _fetchProfile();
                      }
                    } catch (e) {
                      if (mounted) {
                        Fluttertoast.showToast(msg: 'Failed to save GST number', backgroundColor: Colors.red);
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Save GST Number', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteBank(int id) async {
    try {
      await ApiService().deleteBankAccount(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bank account deleted successfully')));
        _fetchProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete bank account')));
      }
    }
  }

  Future<void> _setDefaultBank(Map<String, dynamic> bank) async {
    setState(() => _isLoading = true);
    try {
      final payload = {
        'accountHolderName': bank['accountHolderName'],
        'bankName': bank['bankName'],
        'accountNumber': bank['accountNumber'],
        'ifscCode': bank['ifscCode'],
        'isDefault': true,
      };
      await ApiService().editBankAccount(int.parse(bank['id'].toString()), payload);
      if (mounted) {
        _fetchProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to set default bank account')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showBankDialog([Map<String, dynamic>? bank]) {
    final isEdit = bank != null;
    final holderNameController = TextEditingController(text: isEdit ? bank['accountHolderName'] : '');
    final bankNameController = TextEditingController(text: isEdit ? bank['bankName'] : '');
    final accNoController = TextEditingController(text: isEdit ? bank['accountNumber'] : '');
    final confirmAccNoController = TextEditingController(text: isEdit ? bank['accountNumber'] : '');
    final ifscController = TextEditingController(text: isEdit ? bank['ifscCode'] : '');
    bool isDefault = isEdit ? (bank['isDefault'] ?? false) : false;
    bool isFetchingBank = false;
    String fetchedBankName = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            ifscController.addListener(() async {
              String text = ifscController.text;
              if (text != text.toUpperCase()) {
                int cursorPosition = ifscController.selection.base.offset;
                ifscController.value = ifscController.value.copyWith(
                  text: text.toUpperCase(),
                  selection: TextSelection.collapsed(offset: cursorPosition),
                );
                text = text.toUpperCase();
              }

              if (text.length == 11) {
                setModalState(() => isFetchingBank = true);
                try {
                  final res = await http.get(Uri.parse('https://ifsc.razorpay.com/$text'));
                  if (res.statusCode == 200) {
                    final data = jsonDecode(res.body);
                    setModalState(() {
                      fetchedBankName = '${data['BANK']} - ${data['BRANCH']}';
                      if (bankNameController.text.isEmpty) {
                        bankNameController.text = data['BANK'] ?? '';
                      }
                      isFetchingBank = false;
                    });
                  } else {
                    setModalState(() {
                      fetchedBankName = 'Invalid IFSC or Not Found';
                      isFetchingBank = false;
                    });
                  }
                } catch (e) {
                  setModalState(() {
                    fetchedBankName = 'Failed to fetch bank details';
                    isFetchingBank = false;
                  });
                }
              } else {
                if (fetchedBankName.isNotEmpty) {
                  setModalState(() {
                    fetchedBankName = '';
                  });
                }
              }
            });

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEdit ? 'Edit Bank Account' : 'Add New Bank Account', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 18, color: Colors.black54),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField('Account Holder Name *', holderNameController, hint: 'e.g. John Doe'),
                      const SizedBox(height: 16),
                      _buildTextField('Account Number *', accNoController, obscureText: true, hint: '9-18 digit account number'),
                      const SizedBox(height: 16),
                      _buildTextField('Confirm Account Number *', confirmAccNoController, hint: 'Confirm 9-18 digit account number'),
                      const SizedBox(height: 16),
                      _buildTextField('IFSC Code *', ifscController, maxLength: 11, hint: 'IFSC (e.g. SBIN0001234)'),
                      
                      if (isFetchingBank)
                        const Padding(
                          padding: EdgeInsets.only(top: 6, left: 4),
                          child: Text('Fetching bank details...', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        )
                      else if (fetchedBankName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            fetchedBankName, 
                            style: TextStyle(
                              fontSize: 12, 
                              color: fetchedBankName.contains('Invalid') || fetchedBankName.contains('Failed') ? Colors.red : Colors.green, 
                              fontWeight: FontWeight.w600
                            )
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(top: 6, left: 4),
                          child: Text('e.g. SBIN0000502', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ),
                        
                      const SizedBox(height: 16),
                      _buildTextField('Bank Name *', bankNameController, hint: 'e.g. State Bank of India'),
                      const SizedBox(height: 20),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: isDefault,
                                onChanged: (val) {
                                  setModalState(() => isDefault = val ?? false);
                                },
                                activeColor: AppColors.primary,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Set as default bank account', 
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)
                              )
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (holderNameController.text.trim().isEmpty || bankNameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Holder name and Bank name are required')));
                            return;
                          }

                          if (accNoController.text.trim() != confirmAccNoController.text.trim()) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please confirm your account number')));
                            return;
                          }

                          final accError = Validators.validateBankAccount(accNoController.text.trim());
                          if (accError != null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(accError)));
                            return;
                          }

                          final ifscError = Validators.validateIfsc(ifscController.text.trim());
                          if (ifscError != null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ifscError)));
                            return;
                          }
                          
                          Navigator.pop(ctx);
                          setState(() => _isLoading = true);
                          
                          try {
                            final payload = {
                              'accountHolderName': holderNameController.text.trim(),
                              'bankName': bankNameController.text.trim(),
                              'accountNumber': accNoController.text.trim(),
                              'ifscCode': ifscController.text.trim(),
                              'isDefault': isDefault,
                            };
                            
                            if (isEdit) {
                              await ApiService().editBankAccount(int.parse(bank['id'].toString()), payload);
                            } else {
                              await ApiService().addBankAccount(payload);
                            }
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Bank account updated successfully' : 'Bank account added successfully')));
                              _fetchProfile();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save bank account')));
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Save Bank Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
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
    final upiAccounts = _profileData?['upiAccounts'] as List<dynamic>? ?? [];
    final bankAccounts = _profileData?['bankAccounts'] as List<dynamic>? ?? [];
    final gstNumbers = _profileData?['gstNumbers'] as List<dynamic>? ?? [];

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
                                      onTap: () async {
                                        final res = await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => EditAddressScreen(address: addr)),
                                        );
                                        if (res == true && mounted) {
                                          _fetchProfile(); // Refresh list if changes were made
                                        }
                                      },
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

          const SizedBox(height: 20),

          // 4. Saved UPI IDs
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
                        const Icon(Icons.alternate_email_rounded, size: 20, color: AppColors.primary),
                        const SizedBox(width: 12),
                        const Text('Saved UPI IDs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showUpiDialog(),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Add New'),
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
                if (upiAccounts.isEmpty)
                  const Text('No saved UPI IDs found.', style: TextStyle(color: AppColors.textSecondary))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: upiAccounts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final upi = upiAccounts[index];
                      final isDefault = upi['isDefault'] == true;
                      
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
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    (upi['label'] ?? 'PERSONAL').toString().toUpperCase(),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                  ),
                                ),
                                if (isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text('Default', style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 10)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              upi['upiId'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${upi['status'] ?? 'active'}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => _showUpiDialog(upi),
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
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete UPI ID'),
                                            content: const Text('Are you sure you want to delete this UPI ID?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  _deleteUpi(int.parse(upi['id'].toString()));
                                                }, 
                                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
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
                                    onPressed: () => _setDefaultUpi(upi),
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

          const SizedBox(height: 20),

          // 5. Saved Bank Accounts
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
                        const Icon(Icons.account_balance_outlined, size: 20, color: AppColors.primary),
                        const SizedBox(width: 12),
                        const Text('Saved Bank Accounts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showBankDialog(),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Add New'),
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
                if (bankAccounts.isEmpty)
                  const Text('No saved bank accounts found.', style: TextStyle(color: AppColors.textSecondary))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bankAccounts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final bank = bankAccounts[index];
                      final isDefault = bank['isDefault'] == true;
                      
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
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    (bank['bankName'] ?? 'BANK').toString().toUpperCase(),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                  ),
                                ),
                                if (isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text('Default', style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 10)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              bank['accountHolderName'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'A/C: \u2022\u2022\u2022\u2022 \u2022\u2022\u2022\u2022 ${bank['accountNumber']?.toString().length != null && bank['accountNumber'].toString().length >= 4 ? bank['accountNumber'].toString().substring(bank['accountNumber'].toString().length - 4) : bank['accountNumber']}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, letterSpacing: 1.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'IFSC: ${bank['ifscCode'] ?? ''}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => _showBankDialog(bank),
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
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete Bank Account'),
                                            content: const Text('Are you sure you want to delete this bank account?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  _deleteBank(int.parse(bank['id'].toString()));
                                                }, 
                                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
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
                                    onPressed: () => _setDefaultBank(bank),
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

          const SizedBox(height: 20),

          // 6. Saved GST Numbers
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
                        const Icon(Icons.business_outlined, size: 20, color: AppColors.primary),
                        const SizedBox(width: 12),
                        const Text('Saved GST Numbers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showGstDialog(),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Add New'),
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
                if (gstNumbers.isEmpty)
                  const Text('No saved GST numbers found.', style: TextStyle(color: AppColors.textSecondary))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: gstNumbers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final gst = gstNumbers[index];
                      final isDefault = gst['isDefault'] == true;
                      
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
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    (gst['label'] != null && gst['label'].toString().isNotEmpty ? gst['label'] : 'GSTIN').toString().toUpperCase(),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                  ),
                                ),
                                if (isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text('Default', style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 10)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              gst['gstNumber'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => _showGstDialog(gst),
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
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete GST Number'),
                                            content: const Text('Are you sure you want to delete this GST number?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  _deleteGst(int.parse(gst['id'].toString()));
                                                }, 
                                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
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
                                    onPressed: () => _setDefaultGst(gst),
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

  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false, String? hint, bool obscureText = false, int? maxLength}) {
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
          obscureText: obscureText,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
            counterText: '',
          ),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
