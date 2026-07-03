import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/core/services/api_service.dart';
import 'package:seller_ewaste/features/sell/models/sell_request_model.dart';
import 'package:seller_ewaste/features/sell/screens/sell_checkout_screen.dart';

class SellItemScreen extends StatefulWidget {
  final SellRequestModel requestData;

  const SellItemScreen({super.key, required this.requestData});

  @override
  State<SellItemScreen> createState() => _SellItemScreenState();
}

class _SellItemScreenState extends State<SellItemScreen> {
  bool _isLoadingCategories = true;
  String? _categoriesError;
  List<Map<String, dynamic>> _apiCategories = [];
  bool _isUploading = false;

  final Map<String, TextEditingController> _textControllers = {};

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
        setState(() {
          _apiCategories = json.cast<Map<String, dynamic>>().toList();
          _isLoadingCategories = false;
        });
      } else {
        setState(() {
          _categoriesError = 'Failed to load categories';
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      setState(() {
        _categoriesError = 'Failed to fetch categories';
        _isLoadingCategories = false;
      });
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
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can only upload up to 5 photos')));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
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
          if (addedCount < pickedFiles.length && mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only up to 5 photos can be uploaded. Extra photos were ignored.')));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick images: $e')));
      }
    }
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Add Photo', style: AppTextStyles.headingMedium),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Take a picture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultiImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Removed _showCategoryPicker bottom sheet

  bool get _canProceedCurrentItem {
    if (widget.requestData.selectedCategoryModel == null) return false;
    final attrs = widget.requestData.selectedCategoryModel!['attributes'] as List<dynamic>? ?? [];
    for (final attrMap in attrs) {
      final attr = attrMap as Map<String, dynamic>;
      if (attr['isRequired'] == true) {
        final slug = attr['slug'] as String;
        if (attr['inputType'] == 'dropdown') {
          if (widget.requestData.dropdownValues[slug]?.isEmpty ?? true) return false;
        } else {
          if (widget.requestData.textValues[slug]?.isEmpty ?? true) return false;
        }
      }
    }
    return true;
  }

  bool get _canCheckout {
    return _canProceedCurrentItem || widget.requestData.items.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        title: Text('Item Details', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.requestData.selectedCategoryModel == null) ...[
                  const Text('What are you selling?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Text('Select a category to continue', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  
                  if (_isLoadingCategories)
                    const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                  else if (_categoriesError != null)
                    Padding(padding: const EdgeInsets.all(20), child: Text(_categoriesError!, style: const TextStyle(color: Colors.red)))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _apiCategories.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemBuilder: (context, index) {
                        final cat = _apiCategories[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              widget.requestData.selectedCategoryModel = cat;
                              widget.requestData.textValues.clear();
                              widget.requestData.dropdownValues.clear();
                              for (var c in _textControllers.values) { c.clear(); }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.bgPage,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(cat['emoji'] ?? '📱', style: const TextStyle(fontSize: 24)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    cat['name'] ?? '',
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ] else ...[
                  // Selected Category Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Text(widget.requestData.selectedCategoryModel?['emoji'] ?? '📱', style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Selected Category', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text(
                                widget.requestData.selectedCategoryModel?['name'] ?? '',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              widget.requestData.selectedCategoryModel = null;
                              widget.requestData.textValues.clear();
                              widget.requestData.dropdownValues.clear();
                              for (var c in _textControllers.values) { c.clear(); }
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Change', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Total Value and Add Item Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Value', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(
                            widget.requestData.totalEstimatedPriceRange,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: _canProceedCurrentItem ? () {
                          setState(() {
                            widget.requestData.addCurrentItem();
                            for (var c in _textControllers.values) { c.clear(); }
                          });
                        } : null,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add New Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ], // Close else block
                
                if (widget.requestData.selectedCategoryModel != null) ...[
                  // Device Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Device Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Provide accurate details for the best price', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 20),
                        
                        // Dynamic Fields
                        ...(widget.requestData.selectedCategoryModel!['attributes'] as List<dynamic>? ?? []).map((attrObj) {
                          final attr = attrObj as Map<String, dynamic>;
                          final isRequired = attr['isRequired'] == true;
                          final name = attr['name'] ?? '';
                          final slug = attr['slug'] ?? '';
                          final inputType = attr['inputType'] ?? 'text';
                          
                          final optionsList = attr['options'] as List<dynamic>? ?? [];
                          final options = optionsList.map((e) {
                            if (e is Map) return (e['name'] ?? e['value'] ?? e.toString()).toString();
                            return e.toString();
                          }).toList();

                          final inputDecoration = InputDecoration(
                            labelText: isRequired ? '$name *' : name,
                            filled: true,
                            fillColor: AppColors.bgPage,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.transparent)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          );

                          if (inputType == 'dropdown') {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: DropdownMenu<String>(
                                initialSelection: widget.requestData.dropdownValues[slug],
                                expandedInsets: EdgeInsets.zero,
                                label: Text(isRequired ? '$name *' : name),
                                onSelected: (v) {
                                  if (v != null) setState(() => widget.requestData.dropdownValues[slug] = v);
                                },
                                dropdownMenuEntries: options.map((opt) => DropdownMenuEntry(value: opt, label: opt)).toList(),
                                inputDecorationTheme: InputDecorationTheme(
                                  filled: true,
                                  fillColor: AppColors.bgPage,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.transparent)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                                ),
                                trailingIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                                selectedTrailingIcon: const Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.primary),
                                menuStyle: MenuStyle(
                                  backgroundColor: const WidgetStatePropertyAll(Colors.white),
                                  elevation: const WidgetStatePropertyAll(8),
                                  shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            );
                          } else {
                            TextEditingController ctrl = _textControllers.putIfAbsent(slug, () => TextEditingController());
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TextField(
                                controller: ctrl,
                                onChanged: (v) => setState(() => widget.requestData.textValues[slug] = v),
                                decoration: inputDecoration,
                              ),
                            );
                          }
                        }),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Photos Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.bgPage,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${widget.requestData.localImagePaths.length}/5',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Add clear photos of your device (Optional)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.requestData.localImagePaths.length < 5
                                ? widget.requestData.localImagePaths.length + 1
                                : 5,
                            itemBuilder: (context, index) {
                              if (index == widget.requestData.localImagePaths.length) {
                                return GestureDetector(
                                  onTap: _isUploading ? null : _showImageSourceBottomSheet,
                                  child: Container(
                                    width: 90,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgPage,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: _isUploading 
                                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                                      : const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 28),
                                            SizedBox(height: 8),
                                            Text('Add', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                  ),
                                );
                              }
                              
                              final path = widget.requestData.localImagePaths[index];
                              return Container(
                                width: 90,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  image: DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: GestureDetector(
                                    onTap: () => setState(() => widget.requestData.localImagePaths.removeAt(index)),
                                    child: Container(
                                      margin: const EdgeInsets.all(6),
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54, 
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40), // Bottom padding
              ],
            ),
          ),
          
          // Modern Floating Bottom Bar (similar to food delivery apps)
          if (widget.requestData.selectedCategoryModel != null)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                height: 52,width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canCheckout ? () async {
                    if (_canProceedCurrentItem) {
                      widget.requestData.addCurrentItem();
                      for (var c in _textControllers.values) { c.clear(); }
                    }
                    
                    final selectedAddress = null; // No longer passing this
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SellCheckoutScreen(requestData: widget.requestData)),
                    ).then((wasEdit) {
                         if (mounted) {
                           setState(() {
                             if (wasEdit == true) {
                               widget.requestData.textValues.forEach((key, value) {
                                 if (_textControllers.containsKey(key)) {
                                   _textControllers[key]!.text = value;
                                 } else {
                                   _textControllers[key] = TextEditingController(text: value);
                                 }
                               });
                             } else {
                               // Reset for new item
                               widget.requestData.currentItem = SellItemModel();
                               widget.requestData.textValues.clear();
                               widget.requestData.dropdownValues.clear();
                               for (var c in _textControllers.values) { c.clear(); }
                             }
                           });
                         }
                      });
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.bgMuted,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
