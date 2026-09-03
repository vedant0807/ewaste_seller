import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/core/services/api_service.dart';
import 'package:seller_ewaste/features/requests/request_detail_screen.dart';
import 'package:seller_ewaste/features/main/main_screen.dart';
import 'package:seller_ewaste/features/menu/menu_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String? _error;
  String _activeFilter = 'All Requests';

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      final response = await ApiService().getMyRequests();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> parsedRequests = [];
        if (data is List) {
          parsedRequests = data;
        } else if (data is Map) {
          if (data.containsKey('requests')) {
            parsedRequests = data['requests'] as List<dynamic>;
          } else if (data.containsKey('data')) {
            parsedRequests = data['data'] as List<dynamic>;
          }
        }
        if (mounted) {
          setState(() {
            _requests = parsedRequests;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load requests';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to fetch requests';
          _isLoading = false;
        });
      }
    }
  }

  int _getFilterCount(String filter) {
    if (filter == 'All Requests') return _requests.length;
    if (filter == 'Requested') return _requests.where((r) => (r['statusStep'] as int? ?? 1) <= 2).length;
    if (filter == 'Scheduled') return _requests.where((r) => (r['statusStep'] as int? ?? 1) == 3).length;
    if (filter == 'Completed') return _requests.where((r) => (r['statusStep'] as int? ?? 1) >= 4).length;
    if (filter == 'Cancelled') return _requests.where((r) => r['status']?.toString().toUpperCase() == 'CANCELLED').length;
    return 0;
  }

  List<dynamic> get _filteredRequests {
    if (_activeFilter == 'All Requests') return _requests;
    if (_activeFilter == 'Requested') return _requests.where((r) => (r['statusStep'] as int? ?? 1) <= 2).toList();
    if (_activeFilter == 'Scheduled') return _requests.where((r) => (r['statusStep'] as int? ?? 1) == 3).toList();
    if (_activeFilter == 'Completed') return _requests.where((r) => (r['statusStep'] as int? ?? 1) >= 4).toList();
    if (_activeFilter == 'Cancelled') return _requests.where((r) => r['status']?.toString().toUpperCase() == 'CANCELLED').toList();
    return _requests;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      drawer: const MenuScreen(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchRequests,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 16),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Text('My Requests', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 18),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Text('Track the progress of your sell requests.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 16),
              // Search & Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by item or request ID...',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.tune, color: Colors.grey.shade700, size: 18),
                          const SizedBox(width: 6),
                          Text('Filter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down, color: Colors.grey.shade700, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Add New Item Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.shopping_bag_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Have more e-waste to sell?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                          const SizedBox(height: 2),
                          Text('Add new items and book a doorstep pickup.', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)), (route) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text('+ Add New Item', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Filter Chips
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    'All Requests', 'Requested', 'Scheduled', 'Completed', 'Cancelled'
                  ].map((filter) {
                    final isActive = _activeFilter == filter;
                    final count = _getFilterCount(filter);
                    return GestureDetector(
                      onTap: () => setState(() => _activeFilter = filter),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isActive ? AppColors.primary : Colors.grey.shade300),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            Text(filter, style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(count.toString(), style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              // Loading / Error / List
              if (_isLoading)
                const Padding(padding: EdgeInsets.all(32.0), child: Center(child: CircularProgressIndicator()))
              else if (_error != null)
                Padding(padding: const EdgeInsets.all(32.0), child: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))))
              else if (_filteredRequests.isEmpty)
                const Padding(padding: EdgeInsets.all(40.0), child: Center(child: Text('No requests found.', style: TextStyle(color: Colors.grey, fontSize: 16))))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: _filteredRequests.length,
                  itemBuilder: (context, index) {
                    return _RequestCard(data: _filteredRequests[index] as Map<String, dynamic>, onRefresh: _fetchRequests);
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Future<void> Function() onRefresh;
  
  const _RequestCard({required this.data, required this.onRefresh});

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year} • ${hour.toString().padLeft(2, '0')}:$min $ampm';
    } catch (_) {
      return isoString;
    }
  }

  Widget _buildStepNode(String title, bool isCompleted, String? dateStr) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.primary : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: isCompleted ? AppColors.primary : Colors.grey.shade300, width: 1.5),
            ),
            child: Icon(Icons.check, color: isCompleted ? Colors.white : Colors.transparent, size: 12),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isCompleted ? AppColors.primary : Colors.grey.shade500), textAlign: TextAlign.center, maxLines: 2),
          if (dateStr != null) ...[
            const SizedBox(height: 2),
            Text(dateStr, style: TextStyle(fontSize: 7, color: Colors.grey.shade500), textAlign: TextAlign.center),
          ]
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isCompleted) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20), // Align with circles
        height: 1.5,
        color: isCompleted ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildStepper(int currentStep, String date) {
    // Mapping mockup steps to simple logic
    // Steps: Requested, Approved, Scheduled, Collected, Paid in Wallet, Certificate
    final d1 = currentStep >= 1 ? date.split(' • ')[0] + '\n' + date.split(' • ')[1] : null;
    final d2 = currentStep >= 2 ? '' : null;
    final d3 = currentStep >= 3 ? '' : null;
    final d4 = currentStep >= 4 ? '' : null;
    final d5 = currentStep >= 5 ? '' : null;
    final d6 = currentStep >= 6 ? '' : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildStepNode('Requested', currentStep >= 1, d1),
        _buildStepLine(currentStep >= 2),
        _buildStepNode('Approved', currentStep >= 2, d2),
        _buildStepLine(currentStep >= 3),
        _buildStepNode('Scheduled', currentStep >= 3, d3),
        _buildStepLine(currentStep >= 4),
        _buildStepNode('Collected', currentStep >= 4, d4),
        _buildStepLine(currentStep >= 5),
        _buildStepNode('Paid in\nWallet', currentStep >= 5, d5),
        _buildStepLine(currentStep >= 6),
        _buildStepNode('Certificate', currentStep >= 6, d6),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final device = data['device'] ?? 'Unknown Device';
    final reqId = data['requestNumber'] ?? '';
    final date = _formatDate(data['createdAt']);
    
    // Price logic
    final estPrice = data['estimatedPrice'];
    final negPrice = data['negotiatedPrice'];
    final finalPrice = data['finalPrice'];
    final displayPrice = finalPrice ?? negPrice ?? estPrice ?? 0;
    
    final statusStep = data['statusStep'] as int? ?? 1;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailScreen(data: data)));
        onRefresh();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Center(
                      child: (data['categoryImageUrl'] != null)
                          ? Image.network(data['categoryImageUrl'], height: 32)
                          : const Icon(Icons.devices, color: Colors.grey, size: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Details & Stepper
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(device, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, color: AppColors.primary, size: 10),
                              SizedBox(width: 4),
                              Text('Offer Accepted', style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('$reqId • $date', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        // Stepper
                        _buildStepper(statusStep, date),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom section
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.sell_rounded, color: AppColors.primary, size: 12),
                              SizedBox(width: 4),
                              Text('Final Price', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('₹$displayPrice', style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text('Confirmed price after accepted\ncounter-offer', style: TextStyle(color: Colors.grey.shade600, fontSize: 8)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(12)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFFFF4E5), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFFE0B2))),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF57C00), size: 16),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('The amount shown is an approximate value. The final amount will be confirmed after we inspect your item.', style: TextStyle(fontSize: 8, color: Color(0xFFE65100), fontWeight: FontWeight.w600, height: 1.3)),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 16),
                          ],
                        ),
                      ),
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
}
