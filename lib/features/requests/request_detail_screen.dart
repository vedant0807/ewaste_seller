import 'package:flutter/material.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:seller_ewaste/core/services/api_service.dart';

class RequestDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const RequestDetailScreen({super.key, required this.data});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  late Map<String, dynamic> _data;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.data);
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return isoString;
    }
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString);
      int hour = dt.hour;
      String ampm = 'am';
      if (hour >= 12) {
        ampm = 'pm';
        if (hour > 12) hour -= 12;
      }
      if (hour == 0) hour = 12;
      return '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm';
    } catch (_) {
      return '';
    }
  }

  Future<void> _handleOffer(bool accept) async {
    setState(() => _isSubmitting = true);
    try {
      final reqId = _data['id']?.toString() ?? '';
      await ApiService().updateSellRequest(reqId, {
        'quotedPriceAccepted': accept,
      });
      
      if (mounted) {
        setState(() {
          _data['quotedPriceAccepted'] = accept;
          if (accept) {
             _data['estimatedPrice'] = _data['negotiatedPrice'];
             _data['negotiatedPrice'] = null;
          } else {
             // Backend usually sets status to rejected if needed, or we just leave it.
             _data['status'] = 'Rejected';
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(accept ? 'Offer Accepted!' : 'Offer Rejected')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update offer: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = _data['device'] ?? 'Unknown Device';
    final date = _formatDate(_data['createdAt']);
    final time = _formatTime(_data['createdAt']);
    final estimatedPrice = _data['estimatedPrice']?.toString() ?? '0';
    final negotiatedPrice = _data['negotiatedPrice']?.toString();
    final quotedPriceAccepted = _data['quotedPriceAccepted'] == true;
    final status = _data['status']?.toString().toUpperCase() ?? 'PLACED';
    final step = _data['statusStep'] as int? ?? 1;
    final payoutMethod = _data['payout']?['preferredMethod'] ?? 'Wallet';
    final addressObj = _data['address'] as Map<String, dynamic>? ?? {};
    final fName = addressObj['firstName'] ?? '';
    final lName = addressObj['lastName'] ?? '';
    final customerName = '$fName $lName'.trim();
    final customerMobile = addressObj['phone'] ?? 'N/A';
    final customerEmail = addressObj['email'] ?? 'N/A';
    final addressType = addressObj['addressType']?.toString().toUpperCase() ?? 'HOME';
    
    // Construct full address
    final addrLine = addressObj['address'] ?? '';
    final city = addressObj['city'] ?? '';
    final state = addressObj['state'] ?? '';
    final pin = addressObj['pincode'] ?? '';
    final fullAddress = [addrLine, city, state, pin].where((s) => s.toString().isNotEmpty).join(', ');

    // Extract images
    final images = _data['images'] as List<dynamic>? ?? [];

    // Notes might contain pickup date/timeslot if we embedded it there
    final notes = _data['notes']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        titleSpacing: 0,
        title: const Text('Detail Pickup Request', style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: Column(
        children: [
          // Top Banner
          Container(
            color: AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Order Status : $status',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(date, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    if (time.isNotEmpty) Text(time, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tracking Progress
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _TrackerProgress(currentStep: step, payoutMethod: payoutMethod),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                  
                  // Products Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.devices_other_rounded, size: 28),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  if (negotiatedPrice != null && !quotedPriceAccepted) ...[
                                    Text('Estimated: ₹$estimatedPrice', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 13)),
                                    Text('New Offer: ₹$negotiatedPrice', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                                  ] else ...[
                                    Text('Price: ₹$estimatedPrice', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        if (negotiatedPrice != null && !quotedPriceAccepted && status != 'REJECTED') ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Admin sent a new price offer. Do you accept?', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange)),
                                const SizedBox(height: 12),
                                _isSubmitting ? const Center(child: CircularProgressIndicator()) : Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _handleOffer(false),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.red),
                                          foregroundColor: Colors.red,
                                        ),
                                        child: const Text('Reject'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _handleOffer(true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                        ),
                                        child: const Text('Accept'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Images Section
                  if (images.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Images', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Image.network(
                                    images[index],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],

                  const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

                  // Notes / Timeslot
                  if (notes.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Details : $notes',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                  ],

                  const SizedBox(height: 16),

                  // Customer Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: DottedBorder(
                      options: RectDottedBorderOptions(
                        color: AppColors.primary,
                        strokeWidth: 1.5,
                        dashPattern: const [6, 4],
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Customer Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                            const SizedBox(height: 8),
                            Text('Customer Name : $customerName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Customer Mobile : ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(customerMobile, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Customer Email : ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Expanded(child: Text(customerEmail, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Customer Address
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Customer Address:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, color: Colors.red, size: 28),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(addressType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(
                                    fullAddress,
                                    style: const TextStyle(fontSize: 13, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          

        ],
      ),
    );
  }
}

class _TrackerProgress extends StatelessWidget {
  final int currentStep;
  final String payoutMethod;

  const _TrackerProgress({required this.currentStep, required this.payoutMethod});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (label: 'Requested', color: const Color(0xFF6B7280), icon: Icons.check_rounded),
      (label: 'Approved', color: const Color(0xFF3B82F6), icon: Icons.check_rounded),
      (label: 'Scheduled', color: const Color(0xFFF59E0B), icon: Icons.check_rounded),
      (label: 'Collected', color: const Color(0xFF8B5CF6), icon: Icons.check_rounded),
      (label: 'Paid', color: const Color(0xFF10B981), icon: Icons.currency_rupee_rounded),
      (label: 'Certificate', color: const Color(0xFFD1D5DB), icon: Icons.workspace_premium_rounded),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (i) {
        final isCompleted = i < currentStep - 1;
        final isCurrent = i == currentStep - 1;
        final isFuture = i > currentStep - 1;
        
        final stepData = steps[i];
        final nodeColor = isFuture ? const Color(0xFFE5E7EB) : stepData.color;
        
        final leftLineColor = i == 0 ? Colors.transparent : (i < currentStep ? const Color(0xFF10B981) : const Color(0xFFE5E7EB));
        final rightLineColor = i == steps.length - 1 ? Colors.transparent : (i < currentStep - 1 ? const Color(0xFF10B981) : const Color(0xFFE5E7EB));

        return Expanded(
          child: Column(
            children: [
              SizedBox(
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Container(height: 2, color: leftLineColor)),
                        Expanded(child: Container(height: 2, color: rightLineColor)),
                      ],
                    ),
                    Container(
                      width: isCurrent ? 36 : 24,
                      height: isCurrent ? 36 : 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent ? nodeColor.withValues(alpha: 0.2) : Colors.transparent,
                      ),
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFuture ? Colors.white : nodeColor,
                            border: isFuture ? Border.all(color: nodeColor, width: 2) : null,
                          ),
                          child: Icon(
                            isCompleted ? Icons.check_rounded : (isCurrent ? stepData.icon : null),
                            size: 14,
                            color: isFuture ? Colors.transparent : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stepData.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent ? nodeColor : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
