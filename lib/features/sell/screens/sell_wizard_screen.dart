import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:seller_ewaste/core/widgets/bottom_nav_bar.dart';
import 'package:seller_ewaste/features/main/main_screen.dart';
import 'package:seller_ewaste/features/sell/models/sell_request_model.dart';
import 'package:seller_ewaste/features/sell/widgets/step_choose_products.dart';
import 'package:seller_ewaste/features/sell/widgets/step_get_paid.dart';
import 'package:seller_ewaste/features/sell/widgets/step_book_pickup.dart';
import 'package:seller_ewaste/features/sell/widgets/sell_summary_sidebar.dart';

class SellWizardScreen extends StatefulWidget {
  final SellRequestModel requestData;

  const SellWizardScreen({super.key, required this.requestData});

  @override
  State<SellWizardScreen> createState() => _SellWizardScreenState();
}

class _SellWizardScreenState extends State<SellWizardScreen> {
  int _currentStep = 0;
  bool _termsAccepted = false;

  final GlobalKey<StepBookPickupState> _bookPickupKey = GlobalKey<StepBookPickupState>();
  final GlobalKey<StepGetPaidState> _getPaidKey = GlobalKey<StepGetPaidState>();

  void _showToast(String message) {
    FToast fToast = FToast();
    fToast.init(context);
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      margin: const EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.red.shade600,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
    fToast.showToast(child: toast, gravity: ToastGravity.BOTTOM, toastDuration: const Duration(seconds: 3));
  }

  void _nextStep() async {
    if (_currentStep == 0) {
      if (widget.requestData.items.isEmpty) {
        if (widget.requestData.currentItem.isComplete) {
          widget.requestData.addCurrentItem();
        } else {
          if (widget.requestData.currentItem.selectedCategoryModel == null) {
            _showToast('Please select a product category first');
          } else if (widget.requestData.currentItem.localImagePaths.isEmpty &&
              widget.requestData.currentItem.uploadedImageUrls.isEmpty) {
            _showToast('Please upload at least 1 photo of your item');
          } else {
            _showToast('Please fill all required item details');
          }
          return;
        }
      } else {
        // If user filled in another item and it's complete, save it too
        if (widget.requestData.currentItem.isComplete) {
          widget.requestData.addCurrentItem();
        }
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_getPaidKey.currentState?.validate() == false) {
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      final success = await _bookPickupKey.currentState?.validateAndSubmit(_termsAccepted);
      if (success == true) {
        // Success dialog and navigation handled by step_book_pickup
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
          (r) => false,
        );
      }
    }
  }

  void _onUpdate() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Widget _buildActiveStep() {
    final summaryWidget = SellSummarySidebar(
      requestData: widget.requestData,
      currentStep: _currentStep,
      totalSteps: 3,
      onNext: _nextStep,
      onBack: _previousStep,
      onEditCart: () => setState(() => _currentStep = 0),
      isMobile: true,
      termsAccepted: _termsAccepted,
      onTermsChanged: (v) {
        setState(() {
          _termsAccepted = v ?? false;
        });
      },
    );

    switch (_currentStep) {
      case 0:
        return StepChooseProducts(
          requestData: widget.requestData,
          onUpdate: _onUpdate,
          bottomAction: summaryWidget,
        );
      case 1:
        return StepGetPaid(
          key: _getPaidKey,
          requestData: widget.requestData,
          onUpdate: _onUpdate,
          bottomAction: summaryWidget,
        );
      case 2:
        return StepBookPickup(
          key: _bookPickupKey,
          requestData: widget.requestData,
          onUpdate: _onUpdate,
          bottomAction: summaryWidget,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentStep > 0) {
          _previousStep();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F5),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top Header with notification bell
              _buildTopHeader(context),

              // Custom Stepper Pill
              _buildStepper(),

              // Step Content with payout summary cleanly below in scroll view (no overlapping)
              Expanded(
                child: _buildActiveStep(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: 0, // Sell action center is highlighted or maps back cleanly
          onTap: (index) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => MainScreen(initialIndex: index)),
              (r) => false,
            );
          },
          onSellTap: () {
            // Already in sell wizard
          },
        ),
      ),
    );
  }

  /// Screen Header matching screenshots
  Widget _buildTopHeader(BuildContext context) {
    String title = 'Sell items';
    String subtitle = 'Get the best value for your e-waste';
    if (_currentStep == 1) {
      title = 'How do you want to get paid?';
      subtitle = 'Step 2 of 3 • Payout method';
    } else if (_currentStep == 2) {
      title = 'Book your pickup';
      subtitle = 'Step 3 of 3 • Pickup schedule';
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: 12,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              if (_currentStep > 0 || Navigator.canPop(context)) ...[
                GestureDetector(
                  onTap: _previousStep,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: _currentStep == 1 ? 21 : 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Notification Bell Icon with Red Dot
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F8EE),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF0F172A),
                  size: 22,
                ),
                Positioned(
                  top: 9,
                  right: 11,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
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

  /// Custom Stepper Pill Container matching screenshots
  Widget _buildStepper() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepItem(0, '1', 'Choose prod...'),
          _buildStepItem(1, '2', 'Get paid'),
          _buildStepItem(2, '3', 'Book pickup'),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepIndex, String number, String label) {
    final isActive = _currentStep == stepIndex;
    final isCompleted = _currentStep > stepIndex;

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: (isActive || isCompleted)
                ? const Color(0xFF0D7E40)
                : const Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    number,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isActive ? Colors.white : const Color(0xFF0D7E40),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: (isActive || isCompleted) ? FontWeight.w700 : FontWeight.w500,
            color: (isActive || isCompleted)
                ? const Color(0xFF0F172A)
                : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
