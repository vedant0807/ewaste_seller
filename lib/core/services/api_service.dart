import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:seller_ewaste/core/services/session_manager.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Handle localhost URL correctly for Android Emulator vs other platforms
  // String get baseUrl {
  //   return Platform.isAndroid ? 'https://ewasteapi.techgigs.in' : 'https://ewasteapi.techgigs.in';
  // }

  static const String baseUrl = "http://192.168.1.6:3000";
  // static const String baseUrl = "https://ewasteapi.techgigs.in";
  // static const String baseUrl = "http://10.39.42.95:3000";




  /// Fetch list of cities
  Future<http.Response> getCities() async {
    final url = Uri.parse('$baseUrl/api/admin/service-zones/cities');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile'
      }
    ).timeout(const Duration(seconds: 10));
    return response;
  }

  /// Sends the Firebase ID token to the backend to authenticate the user
  Future<http.Response> firebaseLogin(String idToken) async {
    final url = Uri.parse('$baseUrl/api/auth/firebase-login');

    debugPrint('--- API REQUEST ---');
    debugPrint('POST: $url');
    debugPrint('Headers: { Content-Type: application/json, Authorization: Bearer <token_hidden>, x-source-ewaste: mobile }');
    
    final bodyData = jsonEncode({
      'firebaseToken': idToken,
    });
    debugPrint('Body: $bodyData');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer $idToken',
        'x-source-ewaste': 'mobile'
      },
      body: bodyData,
    ).timeout(const Duration(seconds: 10));

    debugPrint('--- API RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    return response;
  }

  /// Checks if service is available in a given pincode
  Future<http.Response> checkPincode(String pincode) async {
    final url = Uri.parse('$baseUrl/api/service/check-pincode');
    
    debugPrint('--- CHECK PINCODE REQUEST ---');
    debugPrint('POST: $url');
    
    final bodyData = jsonEncode({
      'cityId': 'default',
      'pincode': pincode,
    });
    debugPrint('Body: $bodyData');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile'
      },
      body: bodyData,
    ).timeout(const Duration(seconds: 10));

    debugPrint('--- CHECK PINCODE RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    return response;
  }

  /// Registers a new seller
  Future<http.Response> registerSeller(String name, String phoneNumber, String pincode) async {
    final url = Uri.parse('$baseUrl/api/seller/register');
    
    debugPrint('--- REGISTER REQUEST ---');
    debugPrint('POST: $url');
    
    final bodyData = jsonEncode({
      'name': name,
      'phoneNumber': phoneNumber,
      'pincode': pincode,
    });
    debugPrint('Body: $bodyData');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile'
      },
      body: bodyData,
    ).timeout(const Duration(seconds: 10));

    debugPrint('--- REGISTER RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    return response;
  }

  /// Fetches the dashboard summary
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final url = Uri.parse('$baseUrl/api/seller/dashboard-stats');
    final token = await SessionManager().getAccessToken() ?? '';
    
    debugPrint('--- DASHBOARD SUMMARY REQUEST ---');
    debugPrint('GET: $url');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    debugPrint('--- DASHBOARD SUMMARY RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load dashboard data: ${response.statusCode}');
    }
  }

  /// Fetches categories
  Future<http.Response> getCategories() async {
    final url = Uri.parse('$baseUrl/api/categories');
    
    debugPrint('--- CATEGORIES REQUEST ---');
    debugPrint('GET: $url');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile'
      },
    ).timeout(const Duration(seconds: 10));

    debugPrint('--- CATEGORIES RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    return response;
  }

  /// Fetches the user's sell requests
  Future<http.Response> getMyRequests() async {
    final url = Uri.parse('$baseUrl/api/seller/my-requests');
    final token = await SessionManager().getAccessToken();
    print("token--$token");
    
    debugPrint('--- MY REQUESTS ---');
    debugPrint('GET: $url');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- MY REQUESTS RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');

    return response;
  }

  /// Fetches the user's wallet data and transactions
  Future<http.Response> getWalletData() async {
    final url = Uri.parse('$baseUrl/api/seller/wallet');
    final token = await SessionManager().getAccessToken();
    
    debugPrint('--- WALLET REQUEST ---');
    debugPrint('GET: $url');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- WALLET RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');

    return response;
  }

  /// Fetches the user's wallet transaction timeline with pagination
  Future<http.Response> getWalletTimeline({int page = 1, int limit = 10}) async {
    final url = Uri.parse('$baseUrl/api/seller/wallet/timeline?page=$page&limit=$limit');
    final token = await SessionManager().getAccessToken();
    
    debugPrint('--- WALLET TIMELINE REQUEST ---');
    debugPrint('GET: $url');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- WALLET TIMELINE RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    return response;
  }

  /// Fetches orders with pagination
  Future<http.Response> getOrders({int page = 1, int limit = 10}) async {
    final url = Uri.parse('$baseUrl/api/orders?page=$page&limit=$limit');
    final token = await SessionManager().getAccessToken();
    
    debugPrint('--- GET ORDERS REQUEST ---');
    debugPrint('GET: $url');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- GET ORDERS RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');

    return response;
  }

  /// Fetches the seller's profile
  Future<Map<String, dynamic>> getProfile() async {
    final url = Uri.parse('$baseUrl/api/seller/profile');
    final token = await SessionManager().getAccessToken() ?? '';
    
    debugPrint('--- PROFILE REQUEST ---');
    debugPrint('GET: $url');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    debugPrint('--- PROFILE RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load profile data: ${response.statusCode}');
    }
  }

  /// Updates the seller's profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/api/seller/profile');
    final token = await SessionManager().getAccessToken() ?? '';
    
    debugPrint('--- UPDATE PROFILE REQUEST ---');
    debugPrint('PUT: $url');
    debugPrint('Payload: ${jsonEncode(data)}');
    
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- UPDATE PROFILE RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update profile data: ${response.statusCode}');
    }
  }

  /// Adds a new address for the seller
  Future<void> addAddress(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/api/seller/addresses');
    final token = await SessionManager().getAccessToken() ?? '';
    
    debugPrint('--- ADD ADDRESS REQUEST ---');
    debugPrint('POST: $url');
    debugPrint('Payload: ${jsonEncode(data)}');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- ADD ADDRESS RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add address: ${response.statusCode}');
    }
  }

  /// Edits an existing address for the seller
  Future<void> editAddress(int id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/api/seller/addresses/edit/$id');
    final token = await SessionManager().getAccessToken() ?? '';
    
    debugPrint('--- EDIT ADDRESS REQUEST ---');
    debugPrint('PUT: $url');
    debugPrint('Payload: ${jsonEncode(data)}');
    
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- EDIT ADDRESS RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to edit address: ${response.statusCode}');
    }
  }

  /// Deletes an address for the seller
  Future<void> deleteAddress(int id) async {
    final url = Uri.parse('$baseUrl/api/seller/addresses/delete/$id');
    final token = await SessionManager().getAccessToken() ?? '';
    
    debugPrint('--- DELETE ADDRESS REQUEST ---');
    debugPrint('DELETE: $url');
    
    final response = await http.delete(
      url,
      headers: {
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- DELETE ADDRESS RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to delete address: ${response.statusCode}');
    }
  }

  /// Adds a new UPI account for the seller
  Future<void> addUpiAccount(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/api/seller/upi-accounts');
    final token = await SessionManager().getAccessToken() ?? '';
    
    debugPrint('--- ADD UPI REQUEST ---');
    debugPrint('POST: $url');
    debugPrint('Payload: ${jsonEncode(data)}');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- ADD UPI RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add UPI: ${response.statusCode}');
    }
  }

  /// Edits an existing UPI account for the seller
  Future<void> editUpiAccount(int id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/api/seller/upi-accounts/edit/$id');
    final token = await SessionManager().getAccessToken() ?? '';
    
    debugPrint('--- EDIT UPI REQUEST ---');
    debugPrint('PUT: $url');
    debugPrint('Payload: ${jsonEncode(data)}');
    
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- EDIT UPI RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to edit UPI: ${response.statusCode}');
    }
  }

  /// Deletes a UPI account for the seller
  Future<void> deleteUpiAccount(int id) async {
    final url = Uri.parse('$baseUrl/api/seller/upi-accounts/delete/$id');
    final token = await SessionManager().getAccessToken() ?? '';
    
    debugPrint('--- DELETE UPI REQUEST ---');
    debugPrint('DELETE: $url');
    
    final response = await http.delete(
      url,
      headers: {
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- DELETE UPI RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to delete UPI: ${response.statusCode}');
    }
  }

  /// Adds a new bank account for the seller
  Future<void> addBankAccount(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/api/seller/bank-accounts');
    final token = await SessionManager().getAccessToken() ?? '';
    
    debugPrint('--- ADD BANK REQUEST ---');
    debugPrint('POST: $url');
    debugPrint('Payload: ${jsonEncode(data)}');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- ADD BANK RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add bank account: ${response.statusCode}');
    }
  }

  /// Edits an existing bank account for the seller
  Future<void> editBankAccount(int id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/api/seller/bank-accounts/edit/$id');
    final token = await SessionManager().getAccessToken() ?? '';
    
    debugPrint('--- EDIT BANK REQUEST ---');
    debugPrint('PUT: $url');
    debugPrint('Payload: ${jsonEncode(data)}');
    
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- EDIT BANK RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to edit bank account: ${response.statusCode}');
    }
  }

  /// Deletes a bank account for the seller
  Future<void> deleteBankAccount(int id) async {
    final url = Uri.parse('$baseUrl/api/seller/bank-accounts/delete/$id');
    final token = await SessionManager().getAccessToken() ?? '';
    
    debugPrint('--- DELETE BANK REQUEST ---');
    debugPrint('DELETE: $url');
    
    final response = await http.delete(
      url,
      headers: {
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- DELETE BANK RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to delete bank account: ${response.statusCode}');
    }
  }

  /// Adds a new GST number for the seller
  Future<void> addGstNumber(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/api/seller/gst-numbers');
    final token = await SessionManager().getAccessToken() ?? '';
    
    debugPrint('--- ADD GST REQUEST ---');
    debugPrint('POST: $url');
    debugPrint('Payload: ${jsonEncode(data)}');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- ADD GST RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add GST number: ${response.statusCode}');
    }
  }

  /// Edits an existing GST number for the seller
  Future<void> editGstNumber(int id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/api/seller/gst-numbers/edit/$id');
    final token = await SessionManager().getAccessToken() ?? '';
    
    debugPrint('--- EDIT GST REQUEST ---');
    debugPrint('PUT: $url');
    debugPrint('Payload: ${jsonEncode(data)}');
    
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- EDIT GST RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to edit GST number: ${response.statusCode}');
    }
  }

  /// Deletes a GST number for the seller
  Future<void> deleteGstNumber(int id) async {
    final url = Uri.parse('$baseUrl/api/seller/gst-numbers/delete/$id');
    final token = await SessionManager().getAccessToken() ?? '';
    
    debugPrint('--- DELETE GST REQUEST ---');
    debugPrint('DELETE: $url');
    
    final response = await http.delete(
      url,
      headers: {
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- DELETE GST RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to delete GST number: ${response.statusCode}');
    }
  }

  /// 1. Fetches presigned URL for S3 upload
  Future<Map<String, dynamic>> getPresignedUrl(String fileName, String contentType) async {
    final url = Uri.parse('$baseUrl/api/upload/presigned');
    final token = await SessionManager().getAccessToken() ?? '';

    debugPrint('--- GET PRESIGNED URL REQUEST ---');
    debugPrint('POST: $url');
    final bodyData = jsonEncode({
      'fileName': fileName,
      'contentType': contentType,
    });
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
      body: bodyData,
    ).timeout(const Duration(seconds: 10));

    debugPrint('--- GET PRESIGNED URL RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get presigned URL: ${response.statusCode}');
    }
  }

  /// 2. Uploads the file directly to S3 using the presigned URL
  Future<void> uploadImageToS3(String uploadUrl, Uint8List fileBytes, String contentType) async {
    final url = Uri.parse(uploadUrl);
    debugPrint('--- S3 PUT UPLOAD REQUEST ---');
    
    final response = await http.put(
      url,
      headers: {
        'Content-Type': contentType,
      },
      body: fileBytes,
    ).timeout(const Duration(seconds: 60)); // Larger timeout for file upload

    debugPrint('--- S3 PUT UPLOAD RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    if (response.statusCode != 200) {
      throw Exception('Failed to upload image to S3: ${response.statusCode}');
    }
  }

  /// 3. Submits the final sell request
  Future<Map<String, dynamic>> submitSellRequest(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/api/sell-requests');
    final token = await SessionManager().getAccessToken() ?? '';
    
    debugPrint('--- SUBMIT SELL REQUEST ---');
    debugPrint('POST: $url');
    
    final bodyData = jsonEncode(payload);
    debugPrint('Payload: $bodyData');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
      body: bodyData,
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- SUBMIT SELL RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to submit sell request: ${response.statusCode} - ${response.body}');
    }
  }

  /// Updates a sell request (used for accepting/rejecting negotiated price)
  Future<Map<String, dynamic>> updateSellRequest(String id, Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/api/sell-requests/$id');
    final token = await SessionManager().getAccessToken() ?? '';
    
    debugPrint('--- UPDATE SELL REQUEST ---');
    debugPrint('PUT: $url');
    
    final bodyData = jsonEncode(payload);
    debugPrint('Payload: $bodyData');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
      body: bodyData,
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- UPDATE SELL RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update sell request: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> submitBulkEnquiry(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/api/bulk-enquiries');
    final token = await SessionManager().getAccessToken() ?? '';
    
    debugPrint('--- SUBMIT BULK ENQUIRY ---');
    debugPrint('POST: $url');
    
    final bodyData = jsonEncode(payload);
    debugPrint('Payload: $bodyData');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
      body: bodyData,
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- BULK ENQUIRY RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to submit bulk enquiry: ${response.statusCode} - ${response.body}');
    }
  }

  /// Request wallet withdrawal
  Future<Map<String, dynamic>> requestWithdrawal(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/api/seller/wallet/withdrawals');
    final token = await SessionManager().getAccessToken() ?? '';
    
    debugPrint('--- SUBMIT WITHDRAWAL REQUEST ---');
    debugPrint('POST: $url');
    debugPrint('Payload: ${jsonEncode(payload)}');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-source-ewaste': 'mobile',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 15));

    debugPrint('--- WITHDRAWAL RESPONSE ---');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to submit withdrawal: ${response.statusCode} - ${response.body}');
    }
  }
}
