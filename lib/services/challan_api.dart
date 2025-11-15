// challan_api.dart
import 'dart:convert';
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
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // -------------------------------------------------------------------------
  // CREATE CHALLAN
  // -------------------------------------------------------------------------
  Future<bool> createChallan({
    int? customerId,
    required String customerName,
    required String challanType,
    required String location,
    required String transporter,
    required String vehicleNumber,
    required String driverName,
    required String driverNumber,
    required String contactNumber,
    required List<Map<String, dynamic>> items,
    required String email,
    required String date,
    String? address,
  }) async {
    try {
      final Map<String, dynamic> body = {
        if (customerId != null) 'customerId': customerId,
        'customerName': customerName,
        'challanType': challanType,
        'siteLocation': location,
        'transporter': transporter,
        'vehicleNumber': vehicleNumber,
        'driverName': driverName,
        'driverNumber': driverNumber,
        'contactNumber': contactNumber,
        'email': email,
        if (address != null && address.isNotEmpty) 'address': address,
        'date': date,
        'challanNumber': 'AUTO',
        'items': items
            .map(
              (item) => {
                'name': item['name'],
                'qty': item['qty'],
                'srNo': item['srNo'],
                'batchRef': item['srNo'],
              },
            )
            .toList(),
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
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/challans/getAllChallan');

    try {
      final resp = await http
          .get(url, headers: _getHeaders())
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final List<dynamic> jsonList = jsonDecode(resp.body);
        return jsonList.map((j) {
          final String typeStr = j['challanType'] ?? 'RECEIVE';
          final String displayType =
              typeStr.substring(0, 1) + typeStr.substring(1).toLowerCase();

          final List<dynamic>? itemsList = j['items'] as List<dynamic>?;
          final int totalQty =
              itemsList?.fold<int>(0, (int sum, dynamic item) {
                final dynamic qty = item['qty'];
                return sum + ((qty is int) ? qty : 0);
              }) ??
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
  // GET SINGLE CHALLAN — FIXED: Now returns email, address, etc.
  // -------------------------------------------------------------------------
  Future<Map<String, dynamic>?> getChallan(int id) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/challans/getByChallanId/$id');

    try {
      final resp = await http
          .get(url, headers: _getHeaders())
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;

        // ENSURE all required fields are present (even if null)
        return {
          'id': data['id'],
          'customerId': data['customerId'],
          'customerName': data['customerName'] ?? '',
          'contactNumber': data['contactNumber'] ?? '',
          'customerEmail': data['email'] ?? '',
          'siteLocation': data['siteLocation'] ?? '',
          'transporter': data['transporter'] ?? '',
          'vehicleNumber': data['vehicleNumber'] ?? '',
          'driverName': data['driverName'] ?? '',
          'driverNumber': data['driverNumber'] ?? '',
          'date': data['date'] ?? '',
          'challanType': data['challanType'] ?? 'RECEIVE',
          'items': data['items'] ?? [],
        };
      } else {
        debugPrint(
          'Failed to fetch challan: ${resp.statusCode} - ${resp.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching challan: $e');
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // DELETE MULTIPLE CHALLANS — NOW USING http (consistent with rest of API)
  // -------------------------------------------------------------------------
  Future<bool> deleteMultipleChallans(List<int> ids) async {
    if (ids.isEmpty) return false;

    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse(
      '$normalizedBase/api/v1/challans/deleteMultipleChallans',
    );

    try {
      debugPrint('Deleting multiple challans: $ids');

      final response = await http
          .post(url, headers: _getHeaders(), body: jsonEncode(ids))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Multiple challans deleted successfully');
        return true;
      } else {
        debugPrint(
          'Delete multiple failed: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Exception in deleteMultipleChallans: $e');
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // UPDATE CHALLAN
  // -------------------------------------------------------------------------
  Future<bool> updateChallan({
    required int challanId,
    int? customerId,
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
    required String email,
    String? address,
  }) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse(
      '$normalizedBase/api/v1/challans/updateChallanById/$challanId',
    );

    try {
      final Map<String, dynamic> body = {
        if (customerId != null) 'customerId': customerId,
        'customerName': customerName,
        'challanType': challanType,
        'siteLocation': location,
        'transporter': transporter,
        'vehicleNumber': vehicleNumber,
        'driverName': driverName,
        'driverNumber': driverNumber,
        'contactNumber': contactNumber,
        'email': email,
        if (address != null && address.isNotEmpty) 'address': address,
        'date': date,
        'items': items
            .map(
              (item) => {
                'name': item['name'],
                'qty': item['qty'],
                'srNo': item['srNo'],
                'batchRef': item['srNo'],
              },
            )
            .toList(),
      };

      debugPrint('Update Payload: ${jsonEncode(body)}');

      final resp = await http
          .put(url, headers: _getHeaders(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        debugPrint('Challan Updated Successfully');
        return true;
      } else {
        debugPrint('Update Failed: ${resp.statusCode} - ${resp.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating challan: $e');
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // DELETE SINGLE CHALLAN
  // -------------------------------------------------------------------------
  Future<bool> deleteChallan(int id) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse(
      '$normalizedBase/api/v1/challans/deleteChallanById/$id',
    );

    try {
      final resp = await http
          .delete(url, headers: _getHeaders())
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        debugPrint('Challan $id deleted successfully');
        return true;
      } else {
        debugPrint('Delete failed: ${resp.statusCode} - ${resp.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting challan: $e');
      return false;
    }
  }
}
