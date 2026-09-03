import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/core/services/api_service.dart';
import 'package:seller_ewaste/features/sell/models/sell_request_model.dart';
import 'package:seller_ewaste/core/utils/validators.dart';
import 'package:seller_ewaste/features/sell/screens/sell_contact_screen.dart';

class SellCheckoutScreen extends StatefulWidget {
  final SellRequestModel requestData;

  const SellCheckoutScreen({super.key, required this.requestData});

  @override
  State<SellCheckoutScreen> createState() => _SellCheckoutScreenState();
}

class _SellCheckoutScreenState extends State<SellCheckoutScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  bool _isLoadingPaymentInfo = true;
  bool _agreedToTerms = false;
  bool _hasGst = false;
  List<dynamic> _savedUpiAccounts = [];
  List<dynamic> _savedBankAccounts = [];
  List<dynamic> _savedGstNumbers = [];
  Map<String, dynamic>? _selectedUpi;
  Map<String, dynamic>? _selectedBank;
  Map<String, dynamic>? _selectedGst;

  @override
  void initState() {
    super.initState();
    _loadPaymentInfo();
    _hasGst = widget.requestData.hasGst;
    
    widget.requestData.paymentMethod = 'voucher';
  }

  Future<void> _loadPaymentInfo() async {
    setState(() {
      _isLoadingPaymentInfo = true;
    });
    try {
      final data = await ApiService().getProfile();
      
      if (data['email'] != null) _emailController.text = data['email'];
      if (data['phone'] != null) _mobileController.text = data['phone'];

      _savedUpiAccounts = data['upiAccounts'] ?? [];
      _savedBankAccounts = data['bankAccounts'] ?? [];
      
      if (_savedUpiAccounts.isNotEmpty) {
        _selectedUpi = _savedUpiAccounts.firstWhere((u) => u['isDefault'] == true, orElse: () => _savedUpiAccounts.first) as Map<String, dynamic>;
      } else {
        _selectedUpi = null;
      }
      
      if (_savedBankAccounts.isNotEmpty) {
        _selectedBank = _savedBankAccounts.firstWhere((b) => b['isDefault'] == true, orElse: () => _savedBankAccounts.first) as Map<String, dynamic>;
      } else {
        _selectedBank = null;
      }
      
      _savedGstNumbers = data['gstNumbers'] ?? [];
      if (_savedGstNumbers.isNotEmpty) {
        _selectedGst = _savedGstNumbers.firstWhere((g) => g['isDefault'] == true, orElse: () => _savedGstNumbers.first) as Map<String, dynamic>;
      } else {
        _selectedGst = null;
      }
      
    } catch (e) {
      _selectedUpi = null;
      _selectedBank = null;
      _selectedGst = null;
    } finally {
      if (mounted) setState(() {
        _isLoadingPaymentInfo = false;
      });
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 3),
    );
  }

  void _onNextPressed() {
    if (widget.requestData.paymentMethod == 'upi' && _selectedUpi == null) {
      _showToast('Please select a UPI ID', isError: true);
      return;
    }
    if (widget.requestData.paymentMethod == 'bank' && _selectedBank == null) {
      _showToast('Please select a Bank Account', isError: true);
      return;
    }
    if (_hasGst && _selectedGst == null) {
      _showToast('Please select a GST number', isError: true);
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => SellContactScreen(
      requestData: widget.requestData,
      selectedUpi: _selectedUpi,
      selectedBank: _selectedBank,
      selectedGst: _selectedGst,
      hasGst: _hasGst,
    )));
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
                    _buildTextField('Label (Optional)', labelController),
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
                      _showToast(upiError, isError: true);
                      return;
                    }
                    
                    Navigator.pop(ctx);
                    setState(() => _isLoadingPaymentInfo = true);
                    
                    try {
                      final payload = {
                        'upiId': upiIdController.text.trim(),
                        'label': labelController.text.trim(),
                        'isDefault': isDefault,
                      };
                      await ApiService().addUpiAccount(payload);
                      
                      if (mounted) {
                        _showToast('UPI added successfully', isError: false);
                        _loadPaymentInfo();
                      }
                    } catch (e) {
                      if (mounted) {
                        _showToast('Failed to save UPI ID', isError: true);
                        setState(() => _isLoadingPaymentInfo = false);
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
                  const Text('Add Bank Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
                      _buildTextField('Account Holder Name *', holderNameController),
                      const SizedBox(height: 16),
                      _buildTextField('Account Number *', accNoController, obscureText: true),
                      const SizedBox(height: 16),
                      _buildTextField('Confirm Account Number *', confirmAccNoController),
                      const SizedBox(height: 16),
                      _buildTextField('IFSC Code *', ifscController, maxLength: 11),
                      if (isFetchingBank)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 8),
                              Text('Fetching bank details...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      else if (fetchedBankName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                fetchedBankName.contains('Invalid') || fetchedBankName.contains('Failed') ? Icons.error_outline : Icons.check_circle_outline,
                                size: 14,
                                color: fetchedBankName.contains('Invalid') || fetchedBankName.contains('Failed') ? Colors.red : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  fetchedBankName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: fetchedBankName.contains('Invalid') || fetchedBankName.contains('Failed') ? Colors.red : Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      _buildTextField('Bank Name *', bankNameController),
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
                          const Text('Set as default Bank Account', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        ],
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
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
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
                            final payload = {
                              'accountHolderName': holderNameController.text.trim(),
                              'bankName': bankNameController.text.trim(),
                              'accountNumber': accNoController.text.trim(),
                              'ifscCode': ifscController.text.trim(),
                              'isDefault': isDefault,
                            };
                            await ApiService().addBankAccount(payload);
                            
                            if (mounted) {
                              _showToast('Bank account added successfully', isError: false);
                              _loadPaymentInfo();
                            }
                          } catch (e) {
                            if (mounted) {
                              _showToast('Failed to save bank account', isError: true);
                              setState(() => _isLoadingPaymentInfo = false);
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
                        child: const Text('Save Account', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildTextField(String label, TextEditingController controller, {bool isPhone = false, bool isRequired = false, String? errorText, int? maxLength, bool obscureText = false, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.number : TextInputType.text,
          maxLength: maxLength,
          obscureText: obscureText,
          readOnly: readOnly,
          onChanged: (v) => setState((){}),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            filled: true,
            fillColor: Colors.grey.shade100,
            errorText: errorText,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildUpiSelection() {
    if (_isLoadingPaymentInfo) return const Padding(padding: EdgeInsets.all(8), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    
    if (_savedUpiAccounts.isEmpty || _selectedUpi == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showAddUpiDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add New UPI ID', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
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
                  if (_selectedUpi!['label'] != null && _selectedUpi!['label'].toString().isNotEmpty)
                    Text(_selectedUpi!['label'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Select UPI ID', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        ..._savedUpiAccounts.map((upi) => ListTile(
                          title: Text(upi['upiId'] ?? ''),
                          subtitle: upi['label'] != null && upi['label'].toString().isNotEmpty ? Text(upi['label']) : null,
                          trailing: _selectedUpi != null && _selectedUpi!['id'] == upi['id'] ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                          onTap: () {
                            setState(() => _selectedUpi = upi as Map<String, dynamic>);
                            Navigator.pop(ctx);
                          },
                        )),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.add, color: AppColors.primary),
                          title: const Text('Add New UPI ID', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
              child: const Text('Change', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankSelection() {
    if (_isLoadingPaymentInfo) return const Padding(padding: EdgeInsets.all(8), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    
    if (_savedBankAccounts.isEmpty || _selectedBank == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showAddBankDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add New Bank Account', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
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
                  const SizedBox(height: 2),
                  Text(_selectedBank!['accountHolderName'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  Text('A/c: ${_selectedBank!['accountNumber']} • IFSC: ${_selectedBank!['ifscCode']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Select Bank Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        ..._savedBankAccounts.map((bank) => ListTile(
                          title: Text(bank['bankName'] ?? ''),
                          subtitle: Text('${bank['accountHolderName']}\nA/c: ${bank['accountNumber']}'),
                          isThreeLine: true,
                          trailing: _selectedBank != null && _selectedBank!['id'] == bank['id'] ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                          onTap: () {
                            setState(() => _selectedBank = bank as Map<String, dynamic>);
                            Navigator.pop(ctx);
                          },
                        )),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.add, color: AppColors.primary),
                          title: const Text('Add New Bank Account', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
              child: const Text('Change', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add GST Number', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    _buildTextField('GST Number *', gstNumberController, maxLength: 15),
                    const SizedBox(height: 16),
                    _buildTextField('Label (Optional)', labelController),
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
                        const Text('Set as default GST', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
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
                    if (gstNumberController.text.trim().isEmpty) {
                      _showToast('GST Number is required', isError: true);
                      return;
                    }
                    if (gstNumberController.text.trim().length != 15) {
                      _showToast('Invalid GST Number format', isError: true);
                      return;
                    }
                    
                    Navigator.pop(ctx);
                    setState(() => _isLoadingPaymentInfo = true);
                    
                    try {
                      final payload = {
                        'gstNumber': gstNumberController.text.trim().toUpperCase(),
                        'label': labelController.text.trim(),
                        'isDefault': isDefault,
                      };
                      await ApiService().addGstNumber(payload);
                      
                      if (mounted) {
                        _showToast('GST number added successfully', isError: false);
                        _loadPaymentInfo();
                      }
                    } catch (e) {
                      if (mounted) {
                        _showToast('Failed to save GST number', isError: true);
                        setState(() => _isLoadingPaymentInfo = false);
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

  Widget _buildGstSelection() {
    if (_isLoadingPaymentInfo) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    
    if (_savedGstNumbers.isEmpty || _selectedGst == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _showAddGstDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add New GST Number', style: TextStyle(fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: Colors.grey.shade300),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F6F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Saved GST', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(_selectedGst!['gstNumber'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
              if (_selectedGst!['isDefault'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Default', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Select GST Number', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    ..._savedGstNumbers.map((gst) => ListTile(
                      title: Text(gst['gstNumber'] ?? ''),
                      subtitle: gst['label'] != null && gst['label'].toString().isNotEmpty ? Text(gst['label']) : null,
                      trailing: _selectedGst != null && _selectedGst!['id'] == gst['id'] ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                      onTap: () {
                        setState(() => _selectedGst = gst as Map<String, dynamic>);
                        Navigator.pop(ctx);
                      },
                    )),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.add, color: AppColors.primary),
                      title: const Text('Add New GST Number', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Use Another GST Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepItem(
              icon: Icons.check,
              title: 'Choose Products',
              subtitle: 'Select what you want to sell',
              isActive: false,
              isCompleted: true,
            ),
            _buildStepLine(isCompleted: true),
            _buildStepItem(
              icon: null,
              stepNumber: '2',
              title: 'Get Paid',
              subtitle: 'Add details &\nchoose payment',
              isActive: true,
              isCompleted: false,
            ),
            _buildStepLine(isCompleted: false),
            _buildStepItem(
              icon: null,
              stepNumber: '3',
              title: 'Book Pickup',
              subtitle: 'Schedule doorstep\npickup',
              isActive: false,
              isCompleted: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepLine({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(top: 16),
        color: isCompleted ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildStepItem({IconData? icon, String? stepNumber, required String title, required String subtitle, required bool isActive, required bool isCompleted}) {
    Color iconBgColor = isCompleted ? AppColors.primary : (isActive ? AppColors.primary : Colors.grey.shade200);
    Color iconColor = isCompleted || isActive ? Colors.white : Colors.grey.shade500;
    Color titleColor = isActive || isCompleted ? AppColors.primary : Colors.grey.shade600;

    return Expanded(
      flex: 2,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 18, color: iconColor)
                  : Text(stepNumber ?? '', style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: titleColor, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Approx. Value of your product', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(width: 4),
                        Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.requestData.totalEstimatedPriceRange,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 2),
                    const Text('Est. range.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 36),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (widget.requestData.items.isNotEmpty) {
                      widget.requestData.currentItem = widget.requestData.items.last;
                      widget.requestData.items.removeLast();
                      Navigator.pop(context, true);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart_outlined, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Your Cart', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit_outlined, size: 10, color: AppColors.primary),
                            ],
                          ),
                          Text('${widget.requestData.items.length} Items Added', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey.shade200),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estimated Pickup', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      Text('Schedule Selected', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCards() {
    Widget buildCard({required String method, required String title, required String subtitle, required Widget icon, required bool isSelected}) {
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => widget.requestData.paymentMethod = method),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: isSelected ? 2 : 1),
              boxShadow: [
                if (isSelected) BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: icon),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.primary),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) const Icon(Icons.check, size: 14, color: Colors.white),
                        if (isSelected) const SizedBox(width: 4),
                        Text(isSelected ? 'Selected' : 'Select', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.primary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildCard(
            method: 'voucher',
            title: 'Amazon Voucher',
            subtitle: 'Get 5% extra value',
            icon: Image.network(
              'https://imgs.search.brave.com/6Y7q_ORFh_vJ1gXMs3c0wEMvSf2kvqQGm-OPKieN0yU/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9sb2dv/dHlwLnVzL2ZpbGUv/YW1hem9uLnN2Zw', 
              fit: BoxFit.contain, 
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
            isSelected: widget.requestData.paymentMethod == 'voucher',
          ),
          buildCard(
            method: 'bank',
            title: 'Bank Transfer',
            subtitle: 'Direct to your\nbank account',
            icon: Image.asset('assets/bank.png', fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance, color: Colors.blueGrey, size: 36)),
            isSelected: widget.requestData.paymentMethod == 'bank',
          ),
          buildCard(
            method: 'upi',
            title: 'UPI Payout',
            subtitle: 'Direct to your\nUPI ID',
            icon: Image.network(
              'https://imgs.search.brave.com/KfIW-j085wQTvOnrjDnkNmdA9sV31zTLxjCzrDEX5aU/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly90NC5m/dGNkbi5uZXQvanBn/LzE1LzQ4LzA1LzA1/LzM2MF9GXzE1NDgw/NTA1NzFfRThiMnRa/Ymg3WXpWVXVkc1Bm/WmVZYk9TRndnMkIz/OFcuanBn', 
              fit: BoxFit.contain, 
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
            isSelected: widget.requestData.paymentMethod == 'upi',
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicPaymentDetails() {
    String title = '';
    Widget content = const SizedBox.shrink();

    if (widget.requestData.paymentMethod == 'voucher') {
      title = 'Amazon Voucher';
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Voucher will be delivered instantly on your specified email ID & mobile number after pickup verification.', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.email_outlined, size: 16, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text('Delivery Email ID *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Enter your email address',
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.phone_outlined, size: 16, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('Delivery Mobile Number *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            // Restrict to digits only
                            FilteringTextInputFormatter.digitsOnly,
                            // Limit to 10 digits (Indian mobile)
                            LengthLimitingTextInputFormatter(10),
                          ],
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: '+91 ',
                            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          ),
                        ),
                      ],
                    ),

                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          const SizedBox(height: 16),
          // Text.rich(
          //   TextSpan(
          //     text: 'You can also update your default profile contact details in ',
          //     style: const TextStyle(fontSize: 12, color: Colors.grey),
          //     children: const [
          //       TextSpan(text: 'Profile Settings', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          //     ],
          //   ),
          // ),
        ],
      );
    } else if (widget.requestData.paymentMethod == 'upi') {
      title = 'UPI Payout';
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('UPI ID *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          _buildUpiSelection(),
        ],
      );
    } else if (widget.requestData.paymentMethod == 'bank') {
      title = 'Bank Transfer';
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bank Account *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          _buildBankSelection(),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Container(
              //   width: 24, height: 24,
              //   decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              // ),
              const SizedBox(width: 8),
              const Text('Payment details for ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Image.asset('assets/seller-logo.png', height: 36),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black, size: 28),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0, left: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text('JD', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('How do you want to ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                          const Text('get paid?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                          const SizedBox(width: 8),
                          const Text('🎉', style: TextStyle(fontSize: 22)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Choose your preferred payout method to receive your earnings', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                _buildSummaryCard(),
                
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Center(child: Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      ),
                      const SizedBox(width: 8),
                      const Text('Choose your payout method', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                _buildPaymentMethodCards(),
                
                const SizedBox(height: 24),
                _buildDynamicPaymentDetails(),
                
                const SizedBox(height: 24),
                
                // GST Checkbox
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _hasGst = !_hasGst;
                            widget.requestData.hasGst = _hasGst;
                          });
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _hasGst ? Icons.check_circle : Icons.circle_outlined,
                              color: _hasGst ? AppColors.primary : Colors.grey.shade400,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('I have a GST number (optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                  SizedBox(height: 4),
                                  Text('Quoted price is inclusive of 18% GST.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_hasGst) ...[
                        const SizedBox(height: 16),
                        _buildGstSelection(),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Terms Checkbox
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _agreedToTerms = !_agreedToTerms;
                      });
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _agreedToTerms ? Icons.check_circle : Icons.circle_outlined,
                          color: _agreedToTerms ? AppColors.primary : Colors.grey.shade400,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('I agree to the terms & conditions *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                                  Expanded(child: Text('Lift unavailable: labour charges may apply.', style: TextStyle(fontSize: 11, color: Colors.grey))),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                                  Expanded(child: Text('Items above 10 kg may incur extra charges.', style: TextStyle(fontSize: 11, color: Colors.grey))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Sticky Bottom Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  if (!_agreedToTerms) {
                    _showToast('Please agree to the terms & conditions', isError: true);
                    return;
                  }
                  _onNextPressed();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Next: Schedule Pickup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
