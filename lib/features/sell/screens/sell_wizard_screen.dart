import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/features/sell/models/sell_request_model.dart';
import 'package:seller_ewaste/features/sell/widgets/step_choose_products.dart';
import 'package:seller_ewaste/features/sell/widgets/step_get_paid.dart';
import 'package:seller_ewaste/features/sell/widgets/step_book_pickup.dart';
import 'package:seller_ewaste/features/sell/widgets/sell_summary_sidebar.dart';
import 'package:seller_ewaste/features/menu/menu_screen.dart';

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
          Flexible(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
    fToast.showToast(child: toast, gravity: ToastGravity.BOTTOM, toastDuration: const Duration(seconds: 3));
  }

  void _nextStep() async {
    if (_currentStep == 0) {
      if (widget.requestData.items.isEmpty) {
        _showToast('Please add at least one item');
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      if (widget.requestData.paymentMethod == 'upi' && widget.requestData.upiId.isEmpty) {
        _showToast('Please select a UPI ID');
        return;
      }
      if (widget.requestData.paymentMethod == 'bank' && widget.requestData.accountNumber.isEmpty) {
        _showToast('Please select a Bank Account');
        return;
      }
      if (widget.requestData.hasGst && widget.requestData.gstNumber.isEmpty) {
        _showToast('Please select a GST number');
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 2) {
      final success = await _bookPickupKey.currentState?.validateAndSubmit(_termsAccepted);
      if (success == true) {
        // Success dialog is shown by step_book_pickup, and then it navigates away.
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  void _onUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Check if the screen is wide enough for a side-by-side layout (Desktop/Web)
    final isWide = MediaQuery.of(context).size.width > 900;

    return WillPopScope(
      onWillPop: () async {
        if (_currentStep > 0) {
          _previousStep();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text('Sell E-Waste', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
          centerTitle: true,
        ),
        drawer: isWide ? null : const MenuScreen(),
        body: Column(
          children: [
            // Header: Custom Stepper
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              color: Colors.white,
              child: _buildStepper(isWide),
            ),
            const Divider(height: 1),

            // Main Content Area
            Expanded(
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Main Pane
                        Expanded(
                          flex: 2,
                          child: _buildActiveStep(),
                        ),
                        const VerticalDivider(width: 1),
                        // Right Sidebar
                        SizedBox(
                          width: 350,
                          child: SingleChildScrollView(
                            child: SellSummarySidebar(
                              requestData: widget.requestData,
                              currentStep: _currentStep,
                              totalSteps: 3,
                              onNext: _nextStep,
                              onBack: _previousStep,
                              isMobile: false,
                              termsAccepted: _termsAccepted,
                              onTermsChanged: (v) {
                                setState(() {
                                  _termsAccepted = v ?? false;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(child: _buildActiveStep()),
                            // Push the body up to leave room for the bottom sticky sidebar
                            const SizedBox(height: 250), 
                          ],
                        ),
                        // Mobile bottom sticky summary
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: SellSummarySidebar(
                            requestData: widget.requestData,
                            currentStep: _currentStep,
                            totalSteps: 3,
                            onNext: _nextStep,
                            onBack: _previousStep,
                            isMobile: true,
                            termsAccepted: _termsAccepted,
                            onTermsChanged: (v) {
                              setState(() {
                                _termsAccepted = v ?? false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper(bool isWide) {
    if (!isWide) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepIndicator(0, ''),
          _buildStepLine(0),
          _buildStepIndicator(1, ''),
          _buildStepLine(1),
          _buildStepIndicator(2, ''),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepIndicator(0, 'Choose Products'),
        _buildStepLine(0),
        _buildStepIndicator(1, 'Get Paid'),
        _buildStepLine(1),
        _buildStepIndicator(2, 'Book Pickup'),
      ],
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    bool isActive = _currentStep == stepIndex;
    bool isCompleted = _currentStep > stepIndex;

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? AppColors.primary : (isActive ? AppColors.primary : Colors.grey.shade300),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text('${stepIndex + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        if (title.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
              color: isActive || isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepLine(int stepIndex) {
    bool isCompleted = _currentStep > stepIndex;
    return Container(
      width: 40,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      height: 2,
      color: isCompleted ? AppColors.primary : Colors.grey.shade300,
    );
  }

  Widget _buildActiveStep() {
    switch (_currentStep) {
      case 0:
        return StepChooseProducts(requestData: widget.requestData, onUpdate: _onUpdate);
      case 1:
        return StepGetPaid(requestData: widget.requestData, onUpdate: _onUpdate);
      case 2:
        return StepBookPickup(key: _bookPickupKey, requestData: widget.requestData, onUpdate: _onUpdate);
      default:
        return const SizedBox();
    }
  }
}
