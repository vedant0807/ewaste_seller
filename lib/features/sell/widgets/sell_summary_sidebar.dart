import 'package:flutter/material.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/features/sell/models/sell_request_model.dart';

class SellSummarySidebar extends StatelessWidget {
  final SellRequestModel requestData;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final bool isMobile;
  final bool termsAccepted;
  final ValueChanged<bool?>? onTermsChanged;

  const SellSummarySidebar({
    super.key,
    required this.requestData,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    this.onBack,
    this.isMobile = false,
    this.termsAccepted = false,
    this.onTermsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? double.infinity : 350,
      padding: EdgeInsets.fromLTRB(20, 20, 20, isMobile ? 32 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isMobile ? const BorderRadius.vertical(top: Radius.circular(24)) : BorderRadius.circular(16),
        border: isMobile ? null : Border.all(color: Colors.grey.shade200),
        boxShadow: isMobile
            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
          ],
          
          if (requestData.items.isNotEmpty || requestData.currentItem.selectedCategoryModel != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
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
                  requestData.totalEstimatedPriceRange,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          if (currentStep == 2 && onTermsChanged != null) ...[
            CheckboxListTile(
              value: termsAccepted,
              onChanged: onTermsChanged,
              title: const Text('I agree to the terms and final physical inspection.', style: TextStyle(fontSize: 13)),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
            ),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              if (currentStep > 0) ...[
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      child: const Text('Back', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      currentStep == totalSteps - 1 ? 'Confirm My Request' : 'Next Step',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
