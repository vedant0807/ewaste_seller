import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:seller_ewaste/core/services/api_service.dart';
import 'package:seller_ewaste/features/sell/models/sell_request_model.dart';

class StepChooseProducts extends StatefulWidget {
  final SellRequestModel requestData;
  final VoidCallback onUpdate;
  final Widget? bottomAction;

  const StepChooseProducts({
    super.key,
    required this.requestData,
    required this.onUpdate,
    this.bottomAction,
  });

  @override
  State<StepChooseProducts> createState() => _StepChooseProductsState();
}

class _StepChooseProductsState extends State<StepChooseProducts> {
  bool _isLoadingCategories = true;
  List<Map<String, dynamic>> _apiCategories = [];
  final Map<String, TextEditingController> _textControllers = {};
  int? _editingItemIndex;

  final List<Map<String, dynamic>> _fallbackCategories = [
    {
      'id': 'mobile',
      'name': 'Mobile',
      'icon': Icons.phone_iphone_rounded,
      'attributes': [
        {'name': 'Brand', 'slug': 'brand', 'inputType': 'text'},
        {'name': 'Age', 'slug': 'age', 'inputType': 'text'},
        {'name': 'Condition', 'slug': 'condition', 'inputType': 'dropdown', 'options': ['Excellent', 'Good', 'Fair', 'Poor']},
        {'name': 'Type', 'slug': 'type', 'inputType': 'text'},
      ]
    },
    {
      'id': 'laptop',
      'name': 'Laptop',
      'icon': Icons.laptop_mac_rounded,
      'attributes': [
        {'name': 'Brand', 'slug': 'brand', 'inputType': 'text'},
        {'name': 'Age', 'slug': 'age', 'inputType': 'text'},
        {'name': 'Condition', 'slug': 'condition', 'inputType': 'dropdown', 'options': ['Excellent', 'Good', 'Fair', 'Poor']},
        {'name': 'Type', 'slug': 'type', 'inputType': 'text'},
      ]
    },
    {
      'id': 'ac',
      'name': 'AC',
      'icon': Icons.ac_unit_rounded,
      'attributes': [
        {'name': 'Brand', 'slug': 'brand', 'inputType': 'text'},
        {'name': 'Age', 'slug': 'age', 'inputType': 'text'},
        {'name': 'Condition', 'slug': 'condition', 'inputType': 'dropdown', 'options': ['Excellent', 'Good', 'Fair', 'Poor']},
        {'name': 'Type', 'slug': 'type', 'inputType': 'text'},
      ]
    },
    {
      'id': 'pc',
      'name': 'PC',
      'icon': Icons.desktop_windows_rounded,
      'attributes': [
        {'name': 'Brand', 'slug': 'brand', 'inputType': 'text'},
        {'name': 'Age', 'slug': 'age', 'inputType': 'text'},
        {'name': 'Condition', 'slug': 'condition', 'inputType': 'dropdown', 'options': ['Excellent', 'Good', 'Fair', 'Poor']},
        {'name': 'Type', 'slug': 'type', 'inputType': 'text'},
      ]
    },
    {
      'id': 'others',
      'name': 'Others',
      'icon': Icons.grid_view_rounded,
      'attributes': [
        {'name': 'Brand', 'slug': 'brand', 'inputType': 'text'},
        {'name': 'Age', 'slug': 'age', 'inputType': 'text'},
        {'name': 'Condition', 'slug': 'condition', 'inputType': 'dropdown', 'options': ['Excellent', 'Good', 'Fair', 'Poor']},
        {'name': 'Type', 'slug': 'type', 'inputType': 'text'},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchCategories();

    widget.requestData.textValues.forEach((key, value) {
      _textControllers[key] = TextEditingController(text: value);
    });
  }

  @override
  void dispose() {
    for (var ctrl in _textControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await ApiService().getCategories();
      if (res.statusCode == 200) {
        final List json = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _apiCategories = json.cast<Map<String, dynamic>>().toList();
            _isLoadingCategories = false;
          });

          // Only match if a category is already selected
          if (widget.requestData.selectedCategoryModel != null) {
            final currentName = widget.requestData.selectedCategoryModel!['name']?.toString().toLowerCase() ?? '';
            final matched = _apiCategories.firstWhere(
              (c) => (c['name']?.toString().toLowerCase() ?? '').contains(currentName),
              orElse: () => widget.requestData.selectedCategoryModel!,
            );
            widget.requestData.selectedCategoryModel = matched;
          }
        }
      } else {
        if (mounted) setState(() => _isLoadingCategories = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          if (widget.requestData.localImagePaths.length < 5) {
            widget.requestData.localImagePaths.add(pickedFile.path);
            widget.onUpdate();
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You can only upload up to 5 photos')),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickMultiImage() async {
    final picker = ImagePicker();
    try {
      final pickedFiles = await picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          int addedCount = 0;
          for (var file in pickedFiles) {
            if (widget.requestData.localImagePaths.length < 5) {
              widget.requestData.localImagePaths.add(file.path);
              addedCount++;
            }
          }
          widget.onUpdate();
          if (addedCount < pickedFiles.length && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Only up to 5 photos can be uploaded.')),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    }
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Upload Photos',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8EE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0D7E40)),
                  ),
                  title: const Text('Take a picture', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8EE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFF0D7E40)),
                  ),
                  title: const Text('Choose from gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickMultiImage();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getFallbackIconForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mobile') || lower.contains('phone')) return Icons.phone_iphone_rounded;
    if (lower.contains('laptop')) return Icons.laptop_mac_rounded;
    if (lower.contains('ac') || lower.contains('air')) return Icons.ac_unit_rounded;
    if (lower.contains('pc') || lower.contains('desktop') || lower.contains('computer')) return Icons.desktop_windows_rounded;
    if (lower.contains('tv') || lower.contains('television')) return Icons.tv_rounded;
    if (lower.contains('refrigerator') || lower.contains('fridge')) return Icons.kitchen_rounded;
    return Icons.grid_view_rounded;
  }

  Widget _buildCategoryIcon(Map<String, dynamic> cat, bool isSelected) {
    final imageUrl = cat['imageUrl'] ?? cat['emoji'];
    if (imageUrl != null && imageUrl.toString().startsWith('http')) {
      return Image.network(
        imageUrl.toString(),
        fit: BoxFit.contain,
        width: 60,
        height: 52,
        errorBuilder: (context, error, stackTrace) => Icon(
          _getFallbackIconForName(cat['name']?.toString() ?? ''),
          size: 36,
          color: isSelected ? const Color(0xFF0D7E40) : const Color(0xFF475569),
        ),
      );
    }
    if (cat['emoji'] != null && cat['emoji'].toString().isNotEmpty && !cat['emoji'].toString().startsWith('http')) {
      return Text(cat['emoji'].toString(), style: const TextStyle(fontSize: 34));
    }
    return Icon(
      cat['icon'] as IconData? ?? _getFallbackIconForName(cat['name']?.toString() ?? ''),
      size: 36,
      color: isSelected ? const Color(0xFF0D7E40) : const Color(0xFF475569),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _addAnotherItem() {
    if (widget.requestData.currentItem.selectedCategoryModel == null) {
      _showToast('Please select a product category first');
      return;
    }

    if (widget.requestData.currentItem.localImagePaths.isEmpty &&
        widget.requestData.currentItem.uploadedImageUrls.isEmpty) {
      _showToast('Please upload at least 1 photo of your item');
      return;
    }

    if (!widget.requestData.currentItem.isComplete) {
      _showToast('Please fill all required item details to add this item');
      return;
    }

    setState(() {
      widget.requestData.addCurrentItem();
      for (var c in _textControllers.values) {
        c.clear();
      }
      _editingItemIndex = null;
    });

    widget.onUpdate();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Item added to cart! Add another or proceed.'),
          ],
        ),
        backgroundColor: const Color(0xFF0D7E40),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _loadItemForEdit(int index) {
    if (index < 0 || index >= widget.requestData.items.length) return;

    setState(() {
      // If user had unsaved draft with category and photos, preserve it
      if (_editingItemIndex == null &&
          widget.requestData.currentItem.selectedCategoryModel != null &&
          (widget.requestData.currentItem.localImagePaths.isNotEmpty ||
              widget.requestData.currentItem.textValues.isNotEmpty)) {
        widget.requestData.items.add(widget.requestData.currentItem);
      } else if (_editingItemIndex != null) {
        // If already editing another item, put it back
        widget.requestData.items.insert(_editingItemIndex!, widget.requestData.currentItem);
      }

      final itemToEdit = widget.requestData.items.removeAt(index);
      widget.requestData.currentItem = itemToEdit;
      _editingItemIndex = index;

      // Repopulate text controllers
      for (var ctrl in _textControllers.values) {
        ctrl.clear();
      }
      widget.requestData.currentItem.textValues.forEach((key, val) {
        if (_textControllers.containsKey(key)) {
          _textControllers[key]!.text = val;
        } else {
          _textControllers[key] = TextEditingController(text: val);
        }
      });
    });

    widget.onUpdate();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editing item #${index + 1}: ${widget.requestData.selectedCategoryModel?['name'] ?? 'Device'}'),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveEditedItem() {
    if (_editingItemIndex == null) return;

    if (!widget.requestData.currentItem.isComplete) {
      _showToast('Please fill all required details & photo to save changes');
      return;
    }

    setState(() {
      widget.requestData.items.insert(_editingItemIndex!, widget.requestData.currentItem);
      widget.requestData.currentItem = SellItemModel();
      for (var c in _textControllers.values) {
        c.clear();
      }
      _editingItemIndex = null;
    });

    widget.onUpdate();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Item changes saved!'),
          ],
        ),
        backgroundColor: const Color(0xFF0D7E40),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _cancelEdit() {
    if (_editingItemIndex == null) return;

    setState(() {
      widget.requestData.items.insert(_editingItemIndex!, widget.requestData.currentItem);
      widget.requestData.currentItem = SellItemModel();
      for (var c in _textControllers.values) {
        c.clear();
      }
      _editingItemIndex = null;
    });

    widget.onUpdate();
  }

  void _removeItem(int index) {
    if (index < 0 || index >= widget.requestData.items.length) return;

    setState(() {
      widget.requestData.items.removeAt(index);
    });

    widget.onUpdate();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Item removed from cart'),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildEditingBanner() {
    if (_editingItemIndex == null) return const SizedBox.shrink();

    final catName = widget.requestData.selectedCategoryModel?['name'] ?? 'Device';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note_rounded, color: Color(0xFFB45309), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Editing item #${_editingItemIndex! + 1}: $catName',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF92400E),
              ),
            ),
          ),
          TextButton(
            onPressed: _cancelEdit,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildItemActionButtons() {
    if (_editingItemIndex != null) {
      return Container(
        margin: const EdgeInsets.only(top: 14),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Cancel Edit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveEditedItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D7E40),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 14),
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _addAnotherItem,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0D7E40),
          side: const BorderSide(color: Color(0xFF0D7E40), width: 1.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 18, color: Color(0xFF0D7E40)),
            SizedBox(width: 8),
            Text(
              '+ Add Another Item',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0D7E40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddedItemsSection() {
    if (widget.requestData.items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: Color(0xFF0D7E40),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Added Items (${widget.requestData.items.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.requestData.totalEstimatedPriceRange,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D7E40),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.requestData.items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = widget.requestData.items[index];
              final catName = item.selectedCategoryModel?['name'] ?? 'Device';

              String brand = item.textValues['brand'] ?? item.dropdownValues['brand'] ?? '';
              String condition = item.dropdownValues['condition'] ?? 'Good';

              List<String> detailsList = [];
              if (brand.isNotEmpty) detailsList.add(brand);
              if (condition.isNotEmpty) detailsList.add(condition);
              final subtitle = detailsList.isNotEmpty ? detailsList.join(' • ') : 'Standard condition';

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    // Thumbnail or Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: item.localImagePaths.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(item.localImagePaths.first),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Icon(
                                _getFallbackIconForName(catName),
                                size: 24,
                                color: const Color(0xFF0D7E40),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Title & details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            catName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.estimatedPriceRange,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0D7E40),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Edit & Delete actions
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF0D7E40)),
                      tooltip: 'Edit item',
                      onPressed: () => _loadItemForEdit(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                      tooltip: 'Remove item',
                      onPressed: () => _removeItem(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner if editing an existing item
          _buildEditingBanner(),

          // 1. Headline: "Let's get you the best price 🌿"
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
              children: [
                TextSpan(text: "Let's get you the "),
                TextSpan(
                  text: 'best price ',
                  style: TextStyle(color: Color(0xFF10B981)),
                ),
                TextSpan(text: '🌿'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select your item and add details to see an approximate value range.',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
              height: 1.3,
            ),
          ),

          const SizedBox(height: 18),

          // 2. Category Title
          const Text(
            'Choose a product category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 12),

          // 3. Dynamic Categories Grid from API
          _buildDynamicCategoriesGrid(),

          const SizedBox(height: 18),

          if (widget.requestData.selectedCategoryModel == null) ...[
            // Prompt user to select a category first
            _buildCategoryPromptCard(),
          ] else ...[
            // 4. Dotted Photo Upload Box
            _buildPhotoUploadBox(),

            // Uploaded images preview list
            if (widget.requestData.localImagePaths.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildUploadedThumbnails(),
            ],

            const SizedBox(height: 20),

            // 5. "Item details" Card (with dynamic attributes or standard fields)
            _buildItemDetailsCard(),

            // 6. Action Buttons (+ Add Another Item or Save/Cancel Edit)
            _buildItemActionButtons(),
          ],

          // 7. Added Items List (with Edit and Remove buttons)
          _buildAddedItemsSection(),

          // 8. Payout Summary Card directly below Item details (No overlapping!)
          if (widget.bottomAction != null) ...[
            const SizedBox(height: 18),
            widget.bottomAction!,
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryPromptCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F8EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.touch_app_outlined,
              color: Color(0xFF0D7E40),
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select a category above',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose an electronic device type to upload photos, enter specifications, and see your instant price estimate.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Dynamic Categories Grid
  Widget _buildDynamicCategoriesGrid() {
    if (_isLoadingCategories) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF0D7E40)),
        ),
      );
    }

    final categories = _apiCategories.isNotEmpty ? _apiCategories : _fallbackCategories;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.82,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final cat = categories[index];
        final currentCat = widget.requestData.selectedCategoryModel;
        final isSelected = currentCat != null &&
            (currentCat['id'] == cat['id'] ||
                (currentCat['name']?.toString().toLowerCase() == cat['name']?.toString().toLowerCase()));

        return InkWell(
          onTap: () {
            setState(() {
              widget.requestData.selectedCategoryModel = cat;
              widget.requestData.textValues.clear();
              widget.requestData.dropdownValues.clear();
              for (var c in _textControllers.values) {
                c.clear();
              }
            });
            widget.onUpdate();
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFDCFCE7) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                width: isSelected ? 1.6 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (isSelected)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 52,
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: _buildCategoryIcon(cat, isSelected),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat['name']?.toString() ?? '',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? const Color(0xFF0D7E40) : const Color(0xFF0F172A),
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Dotted Photo Upload Container
  Widget _buildPhotoUploadBox() {
    return InkWell(
      onTap: _showImageSourceBottomSheet,
      borderRadius: BorderRadius.circular(20),
      child: DottedBorder(
        options: const RoundedRectDottedBorderOptions(
          color: Color(0xFF10B981),
          strokeWidth: 1.2,
          dashPattern: [6, 4],
          radius: Radius.circular(20),
          padding: EdgeInsets.zero,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D7E40),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Click & upload photos',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'JPG, PNG, WEBP • up to 5 photos • 10 MB',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Horizontal list of uploaded thumbnails
  Widget _buildUploadedThumbnails() {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.requestData.localImagePaths.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final path = widget.requestData.localImagePaths[index];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(path),
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      widget.requestData.localImagePaths.removeAt(index);
                      widget.onUpdate();
                    });
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// "Item details" Form Card (dynamic attributes from API category or 2-column fallback)
  Widget _buildItemDetailsCard() {
    final cat = widget.requestData.selectedCategoryModel;
    final attrs = cat != null && cat['attributes'] is List
        ? cat['attributes'] as List<dynamic>
        : <dynamic>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Item details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),

          if (attrs.isNotEmpty)
            _buildDynamicAttributeRows(attrs)
          else ...[
            // Default 2-column layout (Brand, Age, Condition, Type)
            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    label: 'Brand',
                    isRequired: true,
                    hint: 'e.g. Apple',
                    fieldKey: 'brand',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFormField(
                    label: 'Age',
                    isRequired: true,
                    hint: 'e.g. 2 years',
                    fieldKey: 'age',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildConditionDropdown(
                    label: 'Condition',
                    isRequired: true,
                    fieldKey: 'condition',
                    options: const ['Excellent', 'Good', 'Fair', 'Poor'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFormField(
                    label: 'Type',
                    isRequired: true,
                    hint: 'e.g. MacBook Air',
                    fieldKey: 'type',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Pairs dynamic attributes into 2-column rows
  Widget _buildDynamicAttributeRows(List<dynamic> attrs) {
    List<Widget> rows = [];
    for (int i = 0; i < attrs.length; i += 2) {
      final attr1 = attrs[i] as Map<String, dynamic>;
      final attr2 = (i + 1 < attrs.length) ? attrs[i + 1] as Map<String, dynamic> : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildSingleAttrField(attr1)),
              if (attr2 != null) ...[
                const SizedBox(width: 12),
                Expanded(child: _buildSingleAttrField(attr2)),
              ] else ...[
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildSingleAttrField(Map<String, dynamic> attr) {
    final name = attr['name']?.toString() ?? '';
    final slug = attr['slug']?.toString() ?? name.toLowerCase();
    final inputType = attr['inputType']?.toString() ?? 'text';
    final optionsRaw = attr['options'] as List<dynamic>? ?? [];
    final options = optionsRaw.map((e) {
      if (e is Map) return (e['name'] ?? e['value'] ?? e.toString()).toString();
      return e.toString();
    }).toList();

    if (inputType == 'dropdown' || options.isNotEmpty) {
      return _buildConditionDropdown(
        label: name,
        isRequired: true,
        fieldKey: slug,
        options: options.isNotEmpty ? options : const ['Excellent', 'Good', 'Fair', 'Poor'],
      );
    } else {
      return _buildFormField(
        label: name,
        isRequired: true,
        hint: 'e.g. $name',
        fieldKey: slug,
      );
    }
  }

  Widget _buildFormField({
    required String label,
    required bool isRequired,
    required String hint,
    required String fieldKey,
  }) {
    final controller = _textControllers.putIfAbsent(
      fieldKey,
      () => TextEditingController(text: widget.requestData.textValues[fieldKey] ?? ''),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            children: [
              TextSpan(text: label),
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: controller,
            onChanged: (val) {
              widget.requestData.textValues[fieldKey] = val;
              widget.onUpdate();
            },
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionDropdown({
    required String label,
    required bool isRequired,
    required String fieldKey,
    required List<String> options,
  }) {
    final currentVal = widget.requestData.dropdownValues[fieldKey];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            children: [
              TextSpan(text: label),
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(currentVal) ? currentVal : null,
              hint: Text(
                'Select $label',
                style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                overflow: TextOverflow.ellipsis,
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 20),
              isExpanded: true,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(14),
              items: options.map((c) {
                return DropdownMenuItem<String>(
                  value: c,
                  child: Text(
                    c,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    widget.requestData.dropdownValues[fieldKey] = val;
                    widget.onUpdate();
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
