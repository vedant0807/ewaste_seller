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
    if (attrs.isNotEmpty) {
      for (final attrMap in attrs) {
        if (attrMap is! Map) continue;
        final slug = attrMap['slug']?.toString() ?? '';
        if (slug.isEmpty) continue;
        final val = (dropdownValues[slug] ?? textValues[slug])?.trim();
        if (val == null || val.isEmpty) return false;
      }
    } else {
      final brand = (textValues['brand'] ?? dropdownValues['brand'])?.trim();
      if (brand == null || brand.isEmpty) return false;
      final age = (textValues['age'] ?? dropdownValues['age'])?.trim();
      if (age == null || age.isEmpty) return false;
      final condition = (dropdownValues['condition'] ?? textValues['condition'])?.trim();
      if (condition == null || condition.isEmpty) return false;
      final type = (textValues['type'] ?? dropdownValues['type'])?.trim();
      if (type == null || type.isEmpty) return false;
    }
    return true;
  }

  int get estimatedPrice {
    if (!isComplete) return 0;
    
    final basePrices = <String, int>{
      'Mobile': 3500,
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
      'Other': 1500,
    };

    final conditionMultiplier = <String, double>{
      'Excellent': 1.2,
      'Good': 1.0,
      'Fair': 0.75,
      'Poor': 0.5,
    };

    if (selectedCategoryModel == null) return 0;
    final catName = (selectedCategoryModel!['name'] ?? '').toString().toLowerCase();

    int base = 2500;
    for (final entry in basePrices.entries) {
      if (catName.contains(entry.key.toLowerCase())) {
        base = entry.value;
        break;
      }
    }

    final cond = dropdownValues['condition'] ?? textValues['condition'] ?? 'Good';
    final mult = conditionMultiplier[cond] ?? 1.0;
    return (base * mult).round();
  }

  String get estimatedPriceRange {
    final p = estimatedPrice;
    if (p == 0) return '—';
    final lo = (p * 0.85).round();
    final hi = (p * 1.15).round();
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
  int get totalItemCount {
    int count = items.length;
    if (currentItem.isComplete) {
      count += 1;
    }
    return count;
  }

  int get estimatedPrice {
    int total = 0;
    for (var item in items) {
      total += item.estimatedPrice;
    }
    if (currentItem.isComplete) {
      total += currentItem.estimatedPrice;
    }
    return total;
  }

  String get totalEstimatedPriceRange {
    final p = estimatedPrice;
    if (p == 0) return '—';
    final lo = (p * 0.85).round();
    final hi = (p * 1.15).round();
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

  // Remove an item at specific index
  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
    }
  }

  // Load an existing item into currentItem for editing
  void loadItemForEdit(int index) {
    if (index >= 0 && index < items.length) {
      // If current item has data, preserve it into items first
      if (currentItem.selectedCategoryModel != null) {
        items.add(currentItem);
      }
      currentItem = items.removeAt(index);
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
  String voucherEmail = '';
  String voucherMobile = '';

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
  Map<String, dynamic>? selectedAddressModel;

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
    selectedAddressModel = null;
  }
}
