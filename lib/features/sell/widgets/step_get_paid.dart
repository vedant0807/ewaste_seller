import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/core/services/api_service.dart';
import 'package:seller_ewaste/features/sell/models/sell_request_model.dart';
import 'package:seller_ewaste/core/utils/validators.dart';

class StepGetPaid extends StatefulWidget {
  final SellRequestModel requestData;
  final VoidCallback onUpdate;

  const StepGetPaid({super.key, required this.requestData, required this.onUpdate});

  @override
  State<StepGetPaid> createState() => StepGetPaidState();
}

class StepGetPaidState extends State<StepGetPaid> {
  bool _isLoadingPaymentInfo = true;
  List<dynamic> _savedUpiAccounts = [];
  List<dynamic> _savedBankAccounts = [];
  List<dynamic> _savedGstNumbers = [];
  
  // We keep full objects locally to render labels easily
  Map<String, dynamic>? _selectedUpi;
  Map<String, dynamic>? _selectedBank;
  Map<String, dynamic>? _selectedGst;

  @override
  void initState() {
    super.initState();
    _loadPaymentInfo();
    
    // Default
    if (widget.requestData.paymentMethod.isEmpty) {
      widget.requestData.paymentMethod = 'voucher';
    }
  }

  Future<void> _loadPaymentInfo() async {
    setState(() {
      _isLoadingPaymentInfo = true;
    });
    try {
      final data = await ApiService().getProfile();
      
      _savedUpiAccounts = data['upiAccounts'] ?? [];
      _savedBankAccounts = data['bankAccounts'] ?? [];
      _savedGstNumbers = data['gstNumbers'] ?? [];
      
      if (_savedUpiAccounts.isNotEmpty) {
        _selectedUpi = _savedUpiAccounts.firstWhere((u) => u['isDefault'] == true, orElse: () => _savedUpiAccounts.first) as Map<String, dynamic>;
        widget.requestData.upiId = _selectedUpi!['upiId'];
      }
      
      if (_savedBankAccounts.isNotEmpty) {
        _selectedBank = _savedBankAccounts.firstWhere((b) => b['isDefault'] == true, orElse: () => _savedBankAccounts.first) as Map<String, dynamic>;
        widget.requestData.accountName = _selectedBank!['accountHolderName'] ?? '';
        widget.requestData.accountNumber = _selectedBank!['accountNumber'] ?? '';
        widget.requestData.bankName = _selectedBank!['bankName'] ?? '';
        widget.requestData.ifscCode = _selectedBank!['ifscCode'] ?? '';
      }
      
      if (_savedGstNumbers.isNotEmpty) {
        _selectedGst = _savedGstNumbers.firstWhere((g) => g['isDefault'] == true, orElse: () => _savedGstNumbers.first) as Map<String, dynamic>;
        if (widget.requestData.hasGst) {
          widget.requestData.gstNumber = _selectedGst!['gstNumber'];
        }
      }
      
    } catch (e) {
      // Ignore
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPaymentInfo = false;
        });
        widget.onUpdate();
      }
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
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Flexible(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
    fToast.showToast(child: toast, gravity: ToastGravity.BOTTOM, toastDuration: const Duration(seconds: 3));
  }

  void _showAddUpiDialog() {
    final upiIdController = TextEditingController();
    final labelController = TextEditingController();
    bool isDefault = true;

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
                  const Text('Add New UPI ID', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField('UPI ID *', upiIdController),
                    const SizedBox(height: 16),
                    _buildTextField('Label (Optional)', labelController),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: isDefault,
                          onChanged: (val) => setModalState(() => isDefault = val ?? false),
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
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final upiError = Validators.validateUpi(upiIdController.text.trim());
                    if (upiError != null) {
                      _showToast(upiError, isError: true);
                      return;
                    }
                    Navigator.pop(ctx);
                    setState(() => _isLoadingPaymentInfo = true);
                    try {
                      await ApiService().addUpiAccount({
                        'upiId': upiIdController.text.trim(),
                        'label': labelController.text.trim(),
                        'isDefault': isDefault,
                      });
                      _showToast('UPI added successfully', isError: false);
                      _loadPaymentInfo();
                    } catch (e) {
                      _showToast('Failed to save UPI ID', isError: true);
                      setState(() => _isLoadingPaymentInfo = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('Save UPI ID', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddBankDialog() {
    final holderNameController = TextEditingController();
    final bankNameController = TextEditingController();
    final accNoController = TextEditingController();
    final confirmAccNoController = TextEditingController();
    final ifscController = TextEditingController();
    bool isDefault = true;
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
                      if (bankNameController.text.isEmpty) bankNameController.text = data['BANK'] ?? '';
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
                if (fetchedBankName.isNotEmpty) setModalState(() => fetchedBankName = '');
              }
            });

            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Add Bank Account'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField('Account Holder Name *', holderNameController),
                    const SizedBox(height: 16),
                    _buildTextField('Account Number *', accNoController, obscureText: true),
                    const SizedBox(height: 16),
                    _buildTextField('Confirm Account Number *', confirmAccNoController),
                    const SizedBox(height: 16),
                    _buildTextField('IFSC Code *', ifscController, maxLength: 11),
                    if (isFetchingBank)
                      const Text('Fetching bank details...', style: TextStyle(fontSize: 12))
                    else if (fetchedBankName.isNotEmpty)
                      Text(fetchedBankName, style: TextStyle(fontSize: 12, color: fetchedBankName.contains('Invalid') ? Colors.red : Colors.green)),
                    const SizedBox(height: 16),
                    _buildTextField('Bank Name *', bankNameController),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: isDefault,
                          onChanged: (val) => setModalState(() => isDefault = val ?? false),
                        ),
                        const Text('Set as default Bank Account'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (holderNameController.text.trim().isEmpty || accNoController.text.trim().isEmpty || confirmAccNoController.text.trim().isEmpty || ifscController.text.trim().isEmpty || bankNameController.text.trim().isEmpty) {
                      _showToast('Please fill all mandatory fields', isError: true);
                      return;
                    }
                    if (accNoController.text != confirmAccNoController.text) {
                      _showToast('Account numbers do not match', isError: true);
                      return;
                    }
                    final ifscError = Validators.validateIfsc(ifscController.text.trim());
                    if (ifscError != null) {
                      _showToast(ifscError, isError: true);
                      return;
                    }
                    Navigator.pop(ctx);
                    setState(() => _isLoadingPaymentInfo = true);
                    try {
                      await ApiService().addBankAccount({
                        'accountHolderName': holderNameController.text.trim(),
                        'bankName': bankNameController.text.trim(),
                        'accountNumber': accNoController.text.trim(),
                        'ifscCode': ifscController.text.trim(),
                        'isDefault': isDefault,
                      });
                      _showToast('Bank account added successfully', isError: false);
                      _loadPaymentInfo();
                    } catch (e) {
                      _showToast('Failed to save bank account', isError: true);
                      setState(() => _isLoadingPaymentInfo = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('Save Account'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddGstDialog() {
    final gstNumberController = TextEditingController();
    final labelController = TextEditingController();
    bool isDefault = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            gstNumberController.addListener(() {
              String text = gstNumberController.text;
              if (text != text.toUpperCase()) {
                int cursorPosition = gstNumberController.selection.base.offset;
                gstNumberController.value = gstNumberController.value.copyWith(
                  text: text.toUpperCase(),
                  selection: TextSelection.collapsed(offset: cursorPosition),
                );
              }
            });
            
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Add GST Number'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField('GST Number *', gstNumberController, maxLength: 15),
                    const SizedBox(height: 16),
                    _buildTextField('Label (Optional)', labelController),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: isDefault,
                          onChanged: (val) => setModalState(() => isDefault = val ?? false),
                        ),
                        const Text('Set as default GST'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (gstNumberController.text.trim().isEmpty || gstNumberController.text.trim().length != 15) {
                      _showToast('Invalid GST Number', isError: true);
                      return;
                    }
                    Navigator.pop(ctx);
                    setState(() => _isLoadingPaymentInfo = true);
                    try {
                      await ApiService().addGstNumber({
                        'gstNumber': gstNumberController.text.trim().toUpperCase(),
                        'label': labelController.text.trim(),
                        'isDefault': isDefault,
                      });
                      _showToast('GST number added successfully', isError: false);
                      _loadPaymentInfo();
                    } catch (e) {
                      _showToast('Failed to save GST number', isError: true);
                      setState(() => _isLoadingPaymentInfo = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('Save GST Number'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscureText = false, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: maxLength,
          obscureText: obscureText,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildUpiSelection() {
    if (_isLoadingPaymentInfo) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    
    if (_savedUpiAccounts.isEmpty || _selectedUpi == null) {
      return OutlinedButton.icon(
        onPressed: _showAddUpiDialog,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add New UPI ID'),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedUpi!['upiId'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (_selectedUpi!['label'] != null)
                  Text(_selectedUpi!['label'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._savedUpiAccounts.map((upi) => ListTile(
                        title: Text(upi['upiId'] ?? ''),
                        onTap: () {
                          setState(() {
                            _selectedUpi = upi as Map<String, dynamic>;
                            widget.requestData.upiId = _selectedUpi!['upiId'];
                            widget.onUpdate();
                          });
                          Navigator.pop(ctx);
                        },
                      )),
                      ListTile(
                        leading: const Icon(Icons.add),
                        title: const Text('Add New UPI ID'),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showAddUpiDialog();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildBankSelection() {
    if (_isLoadingPaymentInfo) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    
    if (_savedBankAccounts.isEmpty || _selectedBank == null) {
      return OutlinedButton.icon(
        onPressed: _showAddBankDialog,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add New Bank Account'),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedBank!['bankName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('A/c: ${_selectedBank!['accountNumber']} • IFSC: ${_selectedBank!['ifscCode']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._savedBankAccounts.map((bank) => ListTile(
                        title: Text(bank['bankName'] ?? ''),
                        subtitle: Text('A/c: ${bank['accountNumber']}'),
                        onTap: () {
                          setState(() {
                            _selectedBank = bank as Map<String, dynamic>;
                            widget.requestData.accountName = _selectedBank!['accountHolderName'] ?? '';
                            widget.requestData.accountNumber = _selectedBank!['accountNumber'] ?? '';
                            widget.requestData.bankName = _selectedBank!['bankName'] ?? '';
                            widget.requestData.ifscCode = _selectedBank!['ifscCode'] ?? '';
                            widget.onUpdate();
                          });
                          Navigator.pop(ctx);
                        },
                      )),
                      ListTile(
                        leading: const Icon(Icons.add),
                        title: const Text('Add New Bank Account'),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showAddBankDialog();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildGstSelection() {
    if (_isLoadingPaymentInfo) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (_savedGstNumbers.isEmpty || _selectedGst == null) {
      return OutlinedButton.icon(
        onPressed: _showAddGstDialog,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add New GST Number'),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_selectedGst!['gstNumber'] ?? ''),
          TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._savedGstNumbers.map((gst) => ListTile(
                        title: Text(gst['gstNumber'] ?? ''),
                        onTap: () {
                          setState(() {
                            _selectedGst = gst as Map<String, dynamic>;
                            widget.requestData.gstNumber = _selectedGst!['gstNumber'];
                            widget.onUpdate();
                          });
                          Navigator.pop(ctx);
                        },
                      )),
                      ListTile(
                        leading: const Icon(Icons.add),
                        title: const Text('Add New GST Number'),
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
            child: const Text('Change'),
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
        const Text('How do you want to get paid?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.requestData.paymentMethod == 'voucher' ? AppColors.primary : Colors.transparent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Radio<String>(
                    value: 'voucher',
                    groupValue: widget.requestData.paymentMethod,
                    onChanged: (v) {
                      setState(() => widget.requestData.paymentMethod = v!);
                      widget.onUpdate();
                    },
                    activeColor: AppColors.primary,
                  ),
                  const Text('Voucher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  const Icon(Icons.card_giftcard_rounded, color: Colors.blue, size: 20),
                ],
              ),
              if (widget.requestData.paymentMethod == 'voucher')
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 16, right: 16),
                  child: Text('You will receive a Voucher link on your registered email and mobile number after successful pickup.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.requestData.paymentMethod == 'bank' ? AppColors.primary : Colors.transparent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Radio<String>(
                    value: 'bank',
                    groupValue: widget.requestData.paymentMethod,
                    onChanged: (v) {
                      setState(() => widget.requestData.paymentMethod = v!);
                      widget.onUpdate();
                    },
                    activeColor: AppColors.primary,
                  ),
                  const Text('Bank Transfer (1-2 days)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 20),
                ],
              ),
              if (widget.requestData.paymentMethod == 'bank') _buildBankSelection(),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.requestData.paymentMethod == 'upi' ? AppColors.primary : Colors.transparent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Radio<String>(
                    value: 'upi',
                    groupValue: widget.requestData.paymentMethod,
                    onChanged: (v) {
                      setState(() => widget.requestData.paymentMethod = v!);
                      widget.onUpdate();
                    },
                    activeColor: AppColors.primary,
                  ),
                  const Text('UPI Transfer (Instant)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  const Icon(Icons.flash_on_rounded, color: Colors.orange, size: 20),
                ],
              ),
              if (widget.requestData.paymentMethod == 'upi') _buildUpiSelection(),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    widget.requestData.hasGst = !widget.requestData.hasGst;
                  });
                  widget.onUpdate();
                },
                child: Row(
                  children: [
                    Icon(
                      widget.requestData.hasGst ? Icons.check_circle : Icons.circle_outlined,
                      color: widget.requestData.hasGst ? AppColors.primary : Colors.grey.shade400,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text('I have a GST number (optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                  ],
                ),
              ),
              if (widget.requestData.hasGst) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: _buildGstSelection(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // A validation method to be called by the orchestrator if needed
  bool validate() {
    if (widget.requestData.paymentMethod == 'upi' && widget.requestData.upiId.isEmpty) {
      _showToast('Please select a UPI ID', isError: true);
      return false;
    }
    if (widget.requestData.paymentMethod == 'bank' && widget.requestData.accountNumber.isEmpty) {
      _showToast('Please select a Bank Account', isError: true);
      return false;
    }
    if (widget.requestData.hasGst && widget.requestData.gstNumber.isEmpty) {
      _showToast('Please select a GST number', isError: true);
      return false;
    }
    return true;
  }
}
