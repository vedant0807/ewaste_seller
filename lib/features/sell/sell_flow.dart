import 'package:flutter/material.dart';
import 'package:seller_ewaste/features/sell/models/sell_request_model.dart';
import 'package:seller_ewaste/features/sell/screens/sell_wizard_screen.dart';

class SellFlowEntryPoint extends StatefulWidget {
  const SellFlowEntryPoint({super.key});

  @override
  State<SellFlowEntryPoint> createState() => _SellFlowEntryPointState();
}

class _SellFlowEntryPointState extends State<SellFlowEntryPoint> {
  late SellRequestModel _requestData;

  @override
  void initState() {
    super.initState();
    _requestData = SellRequestModel();
  }

  @override
  Widget build(BuildContext context) {
    return SellWizardScreen(requestData: _requestData);
  }
}
