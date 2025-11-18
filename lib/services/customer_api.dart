import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../utils/api_utils.dart';

/// Customer DTO – MATCHES com.snowCool.dto.CustomerDTO
class CustomerDTO {
  final int id;
  final String name;
  final String? address;
  final String contactNumber;
  final String? email;
  final String? reminder;
  final double? deposite;
  final List<Map<String, dynamic>>? items;

  CustomerDTO({
    required this.id,
    required this.name,
    this.address,
    required this.contactNumber,
    this.email,
    this.reminder,
    this.deposite,
    this.items,    
  });

  factory CustomerDTO.fromJson(Map<String, dynamic> json) {
    return CustomerDTO(
      id: _parseInt(json['id']),
      name: json['name']?.toString().trim() ?? '',
      address: json['address']?.toString().trim(),
      contactNumber: json['contactNumber']?.toString().trim() ?? '',
      email: json['email']?.toString().trim(),
      reminder: json['reminder']?.toString().trim(),
      deposite: _parseDouble(json['deposite']),
      items: json['items']
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return 0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'contactNumber': contactNumber,
    'email': email,
  };
}

/// Paginated response model for Customer page API
class CustomerPageResponse {
  final List<CustomerDTO> content;
  final int totalPages;
  final int totalElements;
  final int size;
  final int number;

  CustomerPageResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.size,
    required this.number,
  });

  factory CustomerPageResponse.fromJson(Map<String, dynamic> json) {
    final contentList =
        (json['content'] as List<dynamic>?)
            ?.map((e) => CustomerDTO.fromJson(e))
            .toList() ??
        [];
    return CustomerPageResponse(
      content: contentList,
      totalPages: json['totalPages'] ?? 1,
      totalElements: json['totalElements'] ?? contentList.length,
      size: json['size'] ?? 10,
      number: json['number'] ?? 0,
    );
  }
}

/// UPDATED CustomerApi with pagination and existing CRUD methods
class CustomerApi {
  final String baseUrl;

  CustomerApi({String? baseUrl})
    : baseUrl =
          (baseUrl ??
                  (ApiConfig.baseUrl is Function
                      ? (ApiConfig.baseUrl as Function)()
                      : ApiConfig.baseUrl))
              .toString();

  String _normalizeBaseUrl() {
    return baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }

  // ---------------------------------------------------------------------------
  // PAGINATED FETCH METHOD
  // ---------------------------------------------------------------------------
  Future<CustomerPageResponse> getCustomersPage({
    int page = 0,
    int size = 10,
  }) async {
    final normalizedBase = _normalizeBaseUrl();
    final url = Uri.parse(
      '$normalizedBase/api/v1/customers/page',
    ).replace(queryParameters: {'page': '$page', 'size': '$size'});

    final headers = ApiUtils.getAuthenticatedHeaders();
    try {
      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final jsonBody = jsonDecode(resp.body);
        return CustomerPageResponse.fromJson(jsonBody);
      } else if (resp.statusCode == 403) {
        throw Exception('Access denied: Admin only');
      } else if (resp.statusCode == 401) {
        throw Exception('Unauthorized - Login again');
      } else {
        throw Exception('Failed to fetch customers page: ${resp.statusCode}');
      }
    } catch (e) {
      print('getCustomersPage error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // SEARCH BY NAME, MOBILE, OR EMAIL
  // ---------------------------------------------------------------------------
  Future<List<CustomerDTO>> searchCustomers({
    String? name,
    String? contactNumber,
    String? email,
  }) async {
    final Map<String, String> params = {};
    if (name != null && name.trim().isNotEmpty) {
      params['name'] = name.trim();
    }
    if (contactNumber != null && contactNumber.trim().isNotEmpty) {
      final digits = contactNumber.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 2) {
        params['contactNumber'] = digits;
      }
    }
    if (email != null && email.trim().isNotEmpty) {
      params['email'] = email.trim();
    }

    if (params.isEmpty) return [];

    final normalizedBase = _normalizeBaseUrl();
    final url = Uri.parse(
      '$normalizedBase/api/v1/customers/search',
    ).replace(queryParameters: params);
    final headers = ApiUtils.getAuthenticatedHeaders();

    try {
      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(resp.body);
        return jsonList.map((json) => CustomerDTO.fromJson(json)).toList();
      } else if (resp.statusCode == 403) {
        throw Exception('Access denied: Admin only');
      } else if (resp.statusCode == 401) {
        throw Exception('Unauthorized - Login again');
      } else {
        print('Search failed: ${resp.statusCode} ${resp.body}');
        return [];
      }
    } catch (e) {
      print('Search error: $e');
      throw Exception('Search failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // NON-PAGINATED GET ALL (Still usable)
  // ---------------------------------------------------------------------------
  Future<List<CustomerDTO>> getAllCustomers() async {
    final url = Uri.parse(
      '${_normalizeBaseUrl()}/api/v1/customers/getAllCustomers',
    );
    final headers = ApiUtils.getAuthenticatedHeaders();
    final resp = await http
        .get(url, headers: headers)
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(resp.body);
      return jsonList.map((json) => CustomerDTO.fromJson(json)).toList();
    }
    throw Exception('Failed to load customers');
  }

  // ---------------------------------------------------------------------------
  // CRUD OPERATIONS
  // ---------------------------------------------------------------------------

  Future<CustomerResponse> createCustomer({
    required String name,
    required String contactNumber,
    required String email,
    required String address,
    String? reminder,
    double? deposite,
    List<Map<String, dynamic>>? items,
  }) async {
    final url = Uri.parse('${_normalizeBaseUrl()}/api/v1/customers/save');
    final body = jsonEncode({
      'name': name.trim(),
      'contactNumber': contactNumber.trim(),
      'email': email.trim(),
      'address': address.trim(),
      'reminder': reminder,
      'deposite': deposite,
      'items': items,
    });
    final headers = ApiUtils.getAuthenticatedHeaders();
    final resp = await http
        .post(url, headers: headers, body: body)
        .timeout(const Duration(seconds: 10));

    // Treat 200/201 as success even if backend doesn't send { success: true }
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      try {
        final dynamic decoded = resp.body.isEmpty ? {} : jsonDecode(resp.body);
        if (decoded is Map<String, dynamic>) {
          // If API already returns a wrapper, honor it
          if (decoded.containsKey('success') || decoded.containsKey('data')) {
            return CustomerResponse.fromJson(decoded);
          }
          // If API returns the created entity directly, mark success=true
          final dto = CustomerDTO.fromJson(decoded);
          final msg = decoded['message']?.toString();
          return CustomerResponse(success: true, message: msg, data: dto);
        } else {
          // Non-map payload (e.g., plain string) but HTTP success
          return CustomerResponse(
            success: true,
            message: decoded?.toString() ?? 'Created',
            data: null,
          );
        }
      } catch (_) {
        // JSON parse failed but HTTP status indicates success
        return CustomerResponse(success: true, message: 'Created', data: null);
      }
    }
    throw Exception('Failed to create customer');
  }

  Future<CustomerResponse> getCustomerById(String id) async {
    final url = Uri.parse('${_normalizeBaseUrl()}/api/v1/customers/$id');
    final headers = ApiUtils.getAuthenticatedHeaders();
    final resp = await http
        .get(url, headers: headers)
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200)
      return CustomerResponse.fromJson(jsonDecode(resp.body));
    throw Exception('Customer not found');
  }

  Future<CustomerResponse> updateCustomer(
    int id,
    String name,
    String mobile,
    String email,
    String address,
  ) async {
    final url = Uri.parse('${_normalizeBaseUrl()}/api/v1/customers/update/$id');
    final body = jsonEncode({
      'name': name.trim(),
      'contactNumber': mobile.trim(),
      'email': email.trim(),
      'address': address.trim(),
    });
    final headers = ApiUtils.getAuthenticatedHeaders();
    final resp = await http
        .put(url, headers: headers, body: body)
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200 || resp.statusCode == 204) {
      return CustomerResponse(success: true, message: 'Updated');
    }
    throw Exception('Update failed');
  }

  Future<CustomerResponse> deleteCustomer(int id) async {
    final url = Uri.parse(
      '${_normalizeBaseUrl()}/api/v1/customers/deleteById/$id',
    );
    final headers = ApiUtils.getAuthenticatedHeaders();
    final resp = await http
        .delete(url, headers: headers)
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200 || resp.statusCode == 204) {
      return CustomerResponse(success: true, message: 'Deleted');
    }
    throw Exception('Delete failed');
  }
}

class CustomerResponse {
  final bool success;
  final String? message;
  final CustomerDTO? data;

  CustomerResponse({required this.success, this.message, this.data});

  factory CustomerResponse.fromJson(Map<String, dynamic> json) {
    return CustomerResponse(
      success: json['success'] == true || json['data'] != null,
      message: json['message']?.toString(),
      data: json['data'] != null ? CustomerDTO.fromJson(json['data']) : null,
    );
  }
}
