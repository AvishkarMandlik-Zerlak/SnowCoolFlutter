import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../utils/api_utils.dart';

class CustomerResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data; // For getById: {id, name, mobile, email, address}

  CustomerResponse({required this.success, this.message, this.data});

  factory CustomerResponse.fromJson(Map<String, dynamic> json) {
    return CustomerResponse(
      success: json['success'] == true || json['data'] != null,
      message: json['message']?.toString(),
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

class CustomerApi {
  final String baseUrl;

  CustomerApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<CustomerResponse> createCustomer({
    required String name,
    required String mobile,
    required String email,
    required String address,
  }) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/customer/create'); // Assuming endpoint
    final body = jsonEncode({
      'name': name,
      'mobile': mobile,
      'email': email,
      'address': address,
    });

    log('CustomerApi create: POST $url');
    log('CustomerApi create: body=$body');

    // Token internal from TokenManager
    final headers = ApiUtils.getAuthenticatedHeaders();

    log('CustomerApi create: headers=$headers');

    try {
      final resp = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      log('CustomerApi create: status=${resp.statusCode}');
      log('CustomerApi create: response=${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        try {
          final Map<String, dynamic> jsonResp = jsonDecode(resp.body);
          return CustomerResponse.fromJson(jsonResp);
        } catch (e) {
          log('CustomerApi create: failed to decode JSON: $e');
          return CustomerResponse(
            success: false,
            message: 'Invalid server response',
          );
        }
      } else {
        return CustomerResponse(
          success: false,
          message: 'Failed to create customer. Please try again.',
        );
      }
    } catch (e) {
      log('CustomerApi create: network error: $e');
      return CustomerResponse(success: false, message: 'Network error: $e');
    }
  }

  Future<CustomerResponse> getCustomerById(String customerId) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/customer/$customerId'); // Assuming endpoint

    log('CustomerApi getById: GET $url');

    final headers = ApiUtils.getAuthenticatedHeaders();

    log('CustomerApi getById: headers=$headers');

    try {
      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      log('CustomerApi getById: status=${resp.statusCode}');
      log('CustomerApi getById: response=${resp.body}');

      if (resp.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonResp = jsonDecode(resp.body);
          return CustomerResponse.fromJson(jsonResp);
        } catch (e) {
          log('CustomerApi getById: failed to decode JSON: $e');
          return CustomerResponse(
            success: false,
            message: 'Invalid server response',
          );
        }
      } else {
        return CustomerResponse(
          success: false,
          message: 'Customer not found. Please check the ID.',
        );
      }
    } catch (e) {
      log('CustomerApi getById: network error: $e');
      return CustomerResponse(success: false, message: 'Network error: $e');
    }
  }
}