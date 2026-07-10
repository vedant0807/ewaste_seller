class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email ID is required';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Enter a valid email ID';
    return null;
  }

  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) return 'Mobile number is required';
    final regex = RegExp(r'^[6-9]\d{9}$');
    if (!regex.hasMatch(value)) return 'Enter a valid 10-digit mobile number';
    return null;
  }

  static String? validateIfsc(String? value) {
    if (value == null || value.trim().isEmpty) return 'IFSC code is required';
    final regex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$'); 
    if (!regex.hasMatch(value)) return 'Enter a valid 11-character IFSC code';
    return null;
  }

  static String? validateUpi(String? value) {
    if (value == null || value.trim().isEmpty) return 'UPI ID is required';
    final regex = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');
    if (!regex.hasMatch(value)) return 'Enter a valid UPI ID';
    return null;
  }

  static String? validateBankAccount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Bank account is required';
    final regex = RegExp(r'^\d{9,18}$');
    if (!regex.hasMatch(value)) return 'Enter a valid bank account number (9-18 digits)';
    return null;
  }

  static String? validateGst(String? value) {
    if (value == null || value.trim().isEmpty) return 'GST number is required';
    final regex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$', caseSensitive: false);
    if (!regex.hasMatch(value.toUpperCase())) return 'Enter a valid GST number';
    return null;
  }
}
