import 'dart:convert';
import 'package:flutter/material.dart';
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
  bool _isLoadingPaymentInfo = true;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Checkout', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(15),
              children: [
                if (widget.requestData.items.isNotEmpty) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween
                    ,children: [
                      Text('Items Summary', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () {
                        Navigator.pop(context, false); // false indicates new item
                      }, child: const Text(" + Add New Item",style: TextStyle(color: AppColors.primary,fontSize: 16,fontWeight: FontWeight.bold),))
                    ],
                  ),
                  ...widget.requestData.items.map((item) {
                    final categoryName = item.selectedCategoryModel?['name'] ?? 'Unknown';
                    final priceRange = item.estimatedPriceRange;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              (item.selectedCategoryModel?['imageUrl'] != null || (item.selectedCategoryModel?['emoji'] != null && item.selectedCategoryModel!['emoji'].toString().startsWith('http')))
                                  ? Image.network(
                                      item.selectedCategoryModel?['imageUrl'] ?? item.selectedCategoryModel?['emoji'],
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Text('📱', style: TextStyle(fontSize: 20)),
                                    )
                                  : Text(item.selectedCategoryModel?['emoji'] ?? '📱', style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Text(categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            children: [
                              Text(priceRange, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  widget.requestData.currentItem = item;
                                  widget.requestData.items.remove(item);
                                  Navigator.pop(context, true); // true indicates edit mode
                                },
                                child: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    widget.requestData.items.remove(item);
                                  });
                                  if (widget.requestData.items.isEmpty) {
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  Container(
                    margin: const EdgeInsets.only(top: 4, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 22),
                            const SizedBox(width: 8),
                            const Text(
                              'Total Approx Range',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          widget.requestData.totalEstimatedPriceRange,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
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
                            onChanged: (v) => setState(() => widget.requestData.paymentMethod = v!),
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
                          child: Text('You will receive an Voucher link on your registered email and mobile number after successful pickup.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
                            onChanged: (v) => setState(() => widget.requestData.paymentMethod = v!),
                            activeColor: AppColors.primary,
                          ),
                          const Text('Bank Transfer (1-2 days)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const Spacer(),
                          const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 20),
                        ],
                      ),
                      if (widget.requestData.paymentMethod == 'bank')
                        _buildBankSelection(),
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
                            onChanged: (v) => setState(() => widget.requestData.paymentMethod = v!),
                            activeColor: AppColors.primary,
                          ),
                          const Text('UPI Transfer (Instant)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const Spacer(),
                          const Icon(Icons.flash_on_rounded, color: Colors.orange, size: 20),
                        ],
                      ),
                      if (widget.requestData.paymentMethod == 'upi')
                        _buildUpiSelection(),
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
                            _hasGst = !_hasGst;
                            widget.requestData.hasGst = _hasGst;
                          });
                        },
                        child: Row(
                          children: [
                            Icon(
                              _hasGst ? Icons.check_circle : Icons.circle_outlined,
                              color: _hasGst ? AppColors.primary : Colors.grey.shade400,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'I have a GST number (optional)',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 36, top: 4),
                        child: Text(
                          'Quoted price is inclusive of 18% GST.',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ),
                      if (_hasGst) ...[
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
            ),
          ),
          
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onNextPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.bgMuted,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
