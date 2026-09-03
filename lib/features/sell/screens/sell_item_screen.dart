import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/core/services/api_service.dart';
import 'package:seller_ewaste/features/sell/models/sell_request_model.dart';
import 'package:seller_ewaste/features/sell/screens/sell_checkout_screen.dart';
import 'package:seller_ewaste/features/menu/menu_screen.dart';

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
  List<dynamic> _banners = [];

  final Map<String, TextEditingController> _textControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchBanners();
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

  Future<void> _fetchBanners() async {
    try {
      final res = await ApiService().getBanners('header');
      if (res.statusCode == 200) {
        final List json = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _banners = json;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load banners: $e');
    }
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
    return widget.requestData.currentItem.isComplete;
  }

  Widget _buildBanners() {
    if (_banners.isEmpty) return const SizedBox.shrink();
    return CarouselSlider(
      options: CarouselOptions(
        aspectRatio: 11.5, // Wider aspect ratio for desktop-style banners
        viewportFraction: 0.95,
        autoPlay: true,
        enlargeCenterPage: true,
      ),
      items: _banners.map((banner) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  banner['image'],
                  fit: BoxFit.contain, // Ensures the entire image is visible without cropping or distortion
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildEcoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Eco-Friendly Recycling', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('CERTIFIED ECO', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Authorized responsible recycling for a greener tomorrow', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> cat, bool isSelected, bool isHorizontal) {
    bool isOther = cat['name'] != null && cat['name'].toString().toLowerCase().contains('other categories');
    
    Widget content = Container(
      width: isHorizontal ? 80 : null,
      margin: isHorizontal ? const EdgeInsets.only(right: 12) : null,
      decoration: BoxDecoration(
        color: isOther ? AppColors.primaryLight.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: (isOther && !isSelected) ? null : Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
        boxShadow: isHorizontal ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ]
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: (cat['imageUrl'] != null || (cat['emoji'] != null && cat['emoji'].toString().startsWith('http')))
                        ? Image.network(
                            cat['imageUrl'] ?? cat['emoji'],
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Text('📱', style: TextStyle(fontSize: 24)),
                          )
                        : Text(cat['emoji'] ?? '📱', style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cat['name'] ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.1),
                ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
            ),
        ],
      ),
    );

    if (isOther && !isSelected) {
      content = DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: AppColors.primary.withValues(alpha: 0.4),
          strokeWidth: 1.5,
          dashPattern: const [6, 4],
          radius: const Radius.circular(12),
          padding: EdgeInsets.zero,
        ),
        child: content,
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          widget.requestData.selectedCategoryModel = cat;
          widget.requestData.textValues.clear();
          widget.requestData.dropdownValues.clear();
          for (var c in _textControllers.values) { c.clear(); }
        });
      },
      child: content,
    );
  }

  Widget _buildCategoryList(bool isSelected) {
    if (_isLoadingCategories) {
      return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
    }
    if (_categoriesError != null) {
      return Padding(padding: const EdgeInsets.all(20), child: Text(_categoriesError!, style: const TextStyle(color: Colors.red)));
    }

    if (isSelected) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Choose a Product Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0,),
            child: Text("Let's get you the best price & save the planet 🌿"),
          ),
          SizedBox(height: 10,),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _apiCategories.length,
              itemBuilder: (context, index) {
                final cat = _apiCategories[index];
                final isCatSelected = widget.requestData.selectedCategoryModel?['name'] == cat['name'];
                return _buildCategoryItem(cat, isCatSelected, true);
              },
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text('Choose a Product Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text("Let's get you the best price & save the planet 🌿"),
          ),
          SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _apiCategories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final cat = _apiCategories[index];
                return _buildCategoryItem(cat, false, false);
              },
            ),
          ),
        ],
      );
    }
  }

  Widget _buildCameraIconStack() {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.2,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.2,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 26),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.black87, size: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCards() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: DottedBorder(
              options: RoundedRectDottedBorderOptions(
                color: AppColors.primary.withValues(alpha: 0.3),
                strokeWidth: 1.5,
                dashPattern: const [6, 4],
                radius: const Radius.circular(12),
                padding: EdgeInsets.zero,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildCameraIconStack(),
                    const SizedBox(height: 16),
                    const Text('Click & Upload\nPhotos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary), textAlign: TextAlign.center,),
                    const SizedBox(height: 8),
                    const Text('JPG, PNG, WEBP • Max\n5 photos • Up to 10 MB', style: TextStyle(fontSize: 10, color: Colors.blueGrey), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DottedBorder(
              options: RoundedRectDottedBorderOptions(
                color: AppColors.primary.withValues(alpha: 0.3),
                strokeWidth: 1.5,
                dashPattern: const [6, 4],
                radius: const Radius.circular(12),
                padding: EdgeInsets.zero,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.grid_view_rounded, color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select a Product Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center,),
                    const SizedBox(height: 8),
                    const Text('Please choose a category from\nabove to specify item details.', style: TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCategoryBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: (widget.requestData.selectedCategoryModel?['imageUrl'] != null || (widget.requestData.selectedCategoryModel?['emoji'] != null && widget.requestData.selectedCategoryModel!['emoji'].toString().startsWith('http')))
                ? Image.network(
                    widget.requestData.selectedCategoryModel?['imageUrl'] ?? widget.requestData.selectedCategoryModel?['emoji'],
                    fit: BoxFit.contain,
                  )
                : Center(child: Text(widget.requestData.selectedCategoryModel?['emoji'] ?? '📱', style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selected Category', style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  widget.requestData.selectedCategoryModel?['name'] ?? '',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              setState(() {
                widget.requestData.selectedCategoryModel = null;
                widget.requestData.textValues.clear();
                widget.requestData.dropdownValues.clear();
                for (var c in _textControllers.values) { c.clear(); }
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('Change', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUploadCard() {
    return GestureDetector(
      onTap: _isUploading ? null : _showImageSourceBottomSheet,
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: AppColors.primary.withValues(alpha: 0.3),
          strokeWidth: 1.5,
          dashPattern: const [6, 4],
          radius: const Radius.circular(12),
          padding: EdgeInsets.zero,
        ),
        child: Container(
          width: 110,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCameraIconStack(),
              const SizedBox(height: 12),
              const Text('Click & Upload\nPhotos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('JPG, PNG, WEBP\nMax 5 photos', style: TextStyle(fontSize: 8, color: Colors.blueGrey), textAlign: TextAlign.center),
              if (widget.requestData.localImagePaths.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: widget.requestData.localImagePaths.asMap().entries.map((entry) {
                    int index = entry.key;
                    String path = entry.value;
                    return Stack(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 0, right: 0,
                          child: GestureDetector(
                            onTap: () => setState(() => widget.requestData.localImagePaths.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 10, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicFields() {
    final attrs = widget.requestData.selectedCategoryModel!['attributes'] as List<dynamic>? ?? [];
    final List<Widget> rows = [];

    Widget buildField(Map<String, dynamic> attr) {
      final name = attr['name'] ?? '';
      final slug = attr['slug'] ?? '';
      final inputType = attr['inputType'] ?? 'text';

      final optionsList = attr['options'] as List<dynamic>? ?? [];
      final options = optionsList.map((e) {
        if (e is Map) return (e['name'] ?? e['value'] ?? e.toString()).toString();
        return e.toString();
      }).toList();

      final inputDecoration = InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.transparent)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        hintText: inputType == 'text' ? 'Enter $name' : 'Select $name',
        hintStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
      );

      Widget fieldWidget;
      if (inputType == 'dropdown') {
        fieldWidget = LayoutBuilder(
          builder: (context, constraints) {
            return DropdownMenu<String>(
              initialSelection: widget.requestData.dropdownValues[slug],
              expandedInsets: EdgeInsets.zero,
              hintText: 'Select $name',
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              onSelected: (v) {
                if (v != null) setState(() => widget.requestData.dropdownValues[slug] = v);
              },
              dropdownMenuEntries: options
                  .map((opt) => DropdownMenuEntry(
                        value: opt,
                        label: opt,
                        style: MenuItemButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ))
                  .toList(),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
            );
          },
        );
      } else {
        TextEditingController ctrl = _textControllers.putIfAbsent(slug, () => TextEditingController());
        fieldWidget = TextField(
          controller: ctrl,
          onChanged: (v) => setState(() => widget.requestData.textValues[slug] = v),
          decoration: inputDecoration,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              children: const [
                TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          fieldWidget,
        ],
      );
    }

    for (int i = 0; i < attrs.length; i += 2) {
      final attr1 = attrs[i] as Map<String, dynamic>;
      final field1 = buildField(attr1);

      Widget? field2;
      if (i + 1 < attrs.length) {
        final attr2 = attrs[i + 1] as Map<String, dynamic>;
        field2 = buildField(attr2);
      }

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: field1),
              const SizedBox(width: 8),
              Expanded(child: field2 ?? const SizedBox()),
            ],
          ),
        )
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  Widget _buildItemDetailsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ITEM DETAILS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 2),
          const Text('Fill the details of your items', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoUploadCard(),
              const SizedBox(width: 12),
              Expanded(child: _buildDynamicFields()),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _canProceedCurrentItem ? () {
                setState(() {
                  widget.requestData.addCurrentItem();
                  for (var c in _textControllers.values) {
                    c.clear();
                  }
                });
              } : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('+ Add New Item', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceedCurrentItem ? () async {
                if (_canProceedCurrentItem) {
                  widget.requestData.addCurrentItem();
                  for (var c in _textControllers.values) {
                    c.clear();
                  }
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SellCheckoutScreen(requestData: widget.requestData),
                  ),
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
                disabledBackgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Next ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SellCheckoutScreen(requestData: widget.requestData),
              ),
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
                    widget.requestData.currentItem = SellItemModel();
                    widget.requestData.textValues.clear();
                    widget.requestData.dropdownValues.clear();
                    for (var c in _textControllers.values) { c.clear(); }
                  }
                });
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Checkout (${widget.requestData.items.length} items)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.requestData.selectedCategoryModel != null) {
          setState(() {
            widget.requestData.selectedCategoryModel = null;
            widget.requestData.textValues.clear();
            widget.requestData.dropdownValues.clear();
            for (var c in _textControllers.values) { c.clear(); }
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        drawer: const MenuScreen(),
        appBar: AppBar(
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          elevation: 0,
          leading: widget.requestData.selectedCategoryModel != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    setState(() {
                      widget.requestData.selectedCategoryModel = null;
                      widget.requestData.textValues.clear();
                      widget.requestData.dropdownValues.clear();
                      for (var c in _textControllers.values) { c.clear(); }
                    });
                  },
                )
              : Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.black, size: 28),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
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
                children: [
                  _buildBanners(),
                  // _buildEcoBanner(),
                  if (widget.requestData.selectedCategoryModel == null) ...[
                    _buildCategoryList(false),
                    _buildEmptyStateCards(),
                  ] else ...[
                    _buildSelectedCategoryBanner(),
                    _buildCategoryList(true),
                    _buildItemDetailsSection(),
                  ],
                ],
              ),
            ),
            if (widget.requestData.selectedCategoryModel != null)
              _buildBottomButtons()
            else if (widget.requestData.items.isNotEmpty)
              _buildCheckoutButton()
          ],
        ),
      ),
    );
  }
}
