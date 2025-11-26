// challan_api.dart
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../utils/token_manager.dart'; // JWT token manager

class ChallanApi {
  final String baseUrl;
  final TokenManager _tokenManager = TokenManager(); // Singleton

  ChallanApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  // -------------------------------------------------------------------------
  // Headers with JWT
  // -------------------------------------------------------------------------
  Map<String, String> _getHeaders() {
    final token = _tokenManager.getToken();
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // -------------------------------------------------------------------------
  // CREATE CHALLAN
  // -------------------------------------------------------------------------
  Future<bool> createChallan({
    required int customerId,
    required String customerName,
    required String challanType,
    required String location,
    required String transporter,
    required String vehicleNumber,
    required String driverName,
    required String driverNumber,
    required String contactNumber,
    required List<Map<String, dynamic>> items,
    required String date,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'customerId': customerId,
        'customerName': customerName,
        'challanType': challanType,
        'siteLocation': location,
        'transporter': transporter,
        'vehicleNumber': vehicleNumber,
        'driverName': driverName,
        'driverNumber': driverNumber,   // <-- EXACT KEY
        'contactNumber': contactNumber,
        'date': date,                   // <-- EXACT KEY
        'challanNumber': 'AUTO',        // <-- EXACT KEY (backend will generate)
        'items': items.map((item) => {
              'name': item['product'],
              'qty': item['quantity'],
              'srNo': item['serialNumber'],
              'batchRef': item['serialNumber'], // required by backend
            }).toList(),
      };

      debugPrint('Sending Challan Payload: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/challans/create'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('Challan Created: $responseData');
        return true;
      } else {
        debugPrint('Create Failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception in createChallan: $e');
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // FETCH ALL CHALLANS
  // -------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchAllChallans() async {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/challans/getAllChallan');

    try {
      final resp = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 10));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final List<dynamic> jsonList = jsonDecode(resp.body);
        return jsonList.map((j) {
          final String typeStr = j['challanType'] ?? 'RECEIVE';
          final String displayType = typeStr.substring(0, 1) + typeStr.substring(1).toLowerCase();

          // ---- Safe qty sum ----
          final List<dynamic>? itemsList = j['items'] as List<dynamic>?;
          final int totalQty = itemsList?.fold<int>(
                0,
                (int sum, dynamic item) {
                  final dynamic qty = item['qty'];
                  return sum + ((qty is int) ? qty : 0);
                },
              ) ??
              0;

          return {
            'id': j['id'].toString(),
            'name': j['customerName'] ?? '',
            'type': displayType,
            'location': j['siteLocation'] ?? '',
            'qty': totalQty.toString(),
            'date': j['date'] ?? '',
          };
        }).toList();
      } else {
        throw Exception('Failed to fetch challans: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching challans: $e');
      throw Exception('Error fetching challans: $e');
    }
  }

  // -------------------------------------------------------------------------
  // GET SINGLE CHALLAN
  // -------------------------------------------------------------------------
  Future<Map<String, dynamic>> getChallan(int id) async {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/challans/getByChallanId/$id');

    try {
      final resp = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 10));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch challan: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching challan: $e');
      throw Exception('Error fetching challan: $e');
    }
  }

  // -------------------------------------------------------------------------
  // UPDATE CHALLAN
  // -------------------------------------------------------------------------
  Future<bool> updateChallan(int id, Map<String, dynamic> dto) async {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/challans/updateChallanById/$id');

    try {
      final resp = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(dto),
      ).timeout(const Duration(seconds: 10));

      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      debugPrint('Error updating challan: $e');
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // DELETE CHALLAN
  // -------------------------------------------------------------------------
  Future<bool> deleteChallan(int id) async {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/challans/deleteChallanById/$id');

    try {
      final resp = await http.delete(url, headers: _getHeaders()).timeout(const Duration(seconds: 10));

      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      debugPrint('Error deleting challan: $e');
      return false;
    }
  }
}