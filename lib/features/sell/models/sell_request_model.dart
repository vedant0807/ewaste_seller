class SellItemModel {
  List<String> uploadedImageUrls = [];
  List<String> localImagePaths = [];
  Map<String, dynamic>? selectedCategoryModel;
  Map<String, String> textValues = {};
  Map<String, String> dropdownValues = {};

  bool get isComplete {
    if (selectedCategoryModel == null) return false;
    
    // Photo is required
    if (localImagePaths.isEmpty && uploadedImageUrls.isEmpty) return false;

    final attrs = selectedCategoryModel!['attributes'] as List<dynamic>? ?? [];
    for (final attrMap in attrs) {
      final attr = attrMap as Map<String, dynamic>;
      final slug = attr['slug'] as String;
      if (attr['inputType'] == 'dropdown') {
        if (dropdownValues[slug]?.isEmpty ?? true) return false;
      } else {
        if (textValues[slug]?.isEmpty ?? true) return false;
      }
    }
    return true;
  }

  int get estimatedPrice {
    if (!isComplete) return 0;
    
    final basePrices = <String, int>{
      'Mobile': 4000,
      'Laptop': 8500,
      'Desktop': 5000,
      'Television': 2000,
      'Monitor': 2500,
      'Printer': 1500,
      'Router / WiFi': 800,
      'Gaming Console': 3000,
      'Camera': 3500,
      'Home Appliance': 2000,
      'AC': 4500,
      'Refrigerator': 3000,
      'Washing Machine': 2500,
      'Other': 1000,
    };

    final conditionMultiplier = <String, double>{
      'Excellent': 1.2,
      'Good': 1.0,
      'Fair': 0.75,
      'Poor': 0.5,
    };

    final base = basePrices[selectedCategoryModel!['name']] ?? 1000;
    final cond = dropdownValues['condition'] ?? 'Good';
    final mult = conditionMultiplier[cond] ?? 1.0;
    return (base * mult).round();
  }

  String get estimatedPriceRange {
    final p = estimatedPrice;
    if (p == 0) return '—';
    final lo = (p * 0.9).round();
    final hi = (p * 1.1).round();
    return '₹${_fmt(lo)} – ₹${_fmt(hi)}';
  }

  String _fmt(int n) {
    if (n >= 1000) {
      return '${(n ~/ 1000)},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return n.toString();
  }
}

class SellRequestModel {
  // Step 1 & 2: Items
  List<SellItemModel> items = [];
  SellItemModel currentItem = SellItemModel();

  // For backward compatibility during migration and easy access
  List<String> get uploadedImageUrls => currentItem.uploadedImageUrls;
  List<String> get localImagePaths => currentItem.localImagePaths;
  Map<String, dynamic>? get selectedCategoryModel => currentItem.selectedCategoryModel;
  set selectedCategoryModel(Map<String, dynamic>? val) => currentItem.selectedCategoryModel = val;
  Map<String, String> get textValues => currentItem.textValues;
  Map<String, String> get dropdownValues => currentItem.dropdownValues;
  String get estimatedPriceRange => currentItem.estimatedPriceRange;

  // Derived / Calculated values
  int get estimatedPrice {
    int total = 0;
    for (var item in items) {
      total += item.estimatedPrice;
    }
    total += currentItem.estimatedPrice;
    return total;
  }

  String get totalEstimatedPriceRange {
    final p = estimatedPrice;
    if (p == 0) return '—';
    final lo = (p * 0.9).round();
    final hi = (p * 1.1).round();
    return '₹${_fmt(lo)} – ₹${_fmt(hi)}';
  }

  String _fmt(int n) {
    if (n >= 1000) {
      return '${(n ~/ 1000)},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return n.toString();
  }

  // Add the current item to the list and prepare for a new one
  void addCurrentItem() {
    if (currentItem.selectedCategoryModel != null) {
      items.add(currentItem);
      currentItem = SellItemModel();
    }
  }

  // Step 3: Payment
  String paymentMethod = 'upi'; // 'upi' | 'bank' | 'voucher'
  String upiId = '';
  String accountName = '';
  String accountNumber = '';
  String bankName = '';
  String ifscCode = '';
  bool hasGst = false;
  String gstNumber = '';

  // Step 4: Schedule
  String fullName = '';
  String email = '';
  String mobile = '';
  String altContact = '';
  String address = '';
  String area = '';
  String pincode = '';
  DateTime? pickupDate;
  String? timeSlot;

  // Clear data (useful if we want to reset the form)
  void clear() {
    items.clear();
    currentItem = SellItemModel();
    
    paymentMethod = 'upi';
    upiId = '';
    accountName = '';
    accountNumber = '';
    bankName = '';
    ifscCode = '';
    hasGst = false;
    gstNumber = '';
    
    fullName = '';
    email = '';
    mobile = '';
    altContact = '';
    address = '';
    area = '';
    pincode = '';
    pickupDate = null;
    timeSlot = null;
  }
}
