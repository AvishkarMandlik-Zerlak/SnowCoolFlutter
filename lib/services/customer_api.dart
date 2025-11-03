import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../utils/api_utils.dart';

/// Customer DTO – used by CustomerApi and ChallanScreen
class CustomerDTO {
  final int id;
  final String name;
  final String? address;
  final String contactNumber;
  final String? email;

  CustomerDTO({
    required this.id,
    required this.name,
    this.address,
    required this.contactNumber,
    this.email,
  });

  factory CustomerDTO.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return CustomerDTO(
      id: parseId(json['id']),
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      contactNumber: json['contactNumber']?.toString() ?? '',
      email: json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'contactNumber': contactNumber,
      'email': email,
    };
  }
}

class CustomerApi {
  final String baseUrl;

  CustomerApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<List<CustomerDTO>> searchCustomers(String? nameQuery) async {
    if (nameQuery?.isEmpty ?? true) {
      return [];
    }

    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final queryParams = <String, String>{
      if (nameQuery != null) 'name': nameQuery,
    };

    final url = Uri.parse('$normalizedBase/api/v1/customers/search')
        .replace(queryParameters: queryParams);

    final headers = ApiUtils.getAuthenticatedHeaders();

    try {
      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(resp.body) as List<dynamic>;
        return jsonList
            .map((json) => CustomerDTO.fromJson(json))
            .toList();
      } else if (resp.statusCode == 401) {
        throw Exception('Unauthorized - Please log in again');
      } else {
        throw Exception('Failed to search customers');
      }
    } catch (e) {
      throw Exception('Error searching customers: $e');
    }
  }
}