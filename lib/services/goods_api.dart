// goods_api.dart
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../utils/api_utils.dart';

class GoodsDTO {
  final String name;
  final int? id;

  GoodsDTO({required this.name, this.id});

  factory GoodsDTO.fromJson(Map<String, dynamic> json) {
    return GoodsDTO(name: json['name'] as String, id: json['id'] as int?);
  }
}

class GoodsApi {
  final String baseUrl = ApiConfig.baseUrl;

  Future<bool> goods(String productName) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$normalizedBase/api/v1/goods/save');
    final body = jsonEncode({'name': productName});

    // Get authenticated headers
    final headers = ApiUtils.getAuthenticatedHeaders();

    log('GoodsApi: POST $uri');
    log('GoodsApi: Sending product name: "$productName"');
    log('GoodsApi: body=$body');
    log('GoodsApi: headers=$headers');

    try {
      final resp = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      // Print response for debugging
      log('GoodsApi: status=${resp.statusCode}');
      log('GoodsApi: response=${resp.body}');

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        try {
          final Map<String, dynamic> jsonResp = jsonDecode(resp.body);
          log('GoodsApi: Parsed response: $jsonResp');

          // Accept multiple success indicators
          if (jsonResp['success'] == true) return true;
          if (jsonResp['token'] != null) return true;
          if (jsonResp['message'] != null) return true;
          if (jsonResp['id'] != null) return true; // Product saved with ID
          if (jsonResp.containsKey('data')) return true;

          // If we get a 2xx status, assume success even if format is unexpected
          log('GoodsApi: 2xx status received, treating as success');
          return true;
        } catch (e) {
          // Could not parse JSON — but 2xx status means success
          log('GoodsApi: JSON decode error but 2xx status: $e');
          log('GoodsApi: Raw response body: ${resp.body}');
          return true; // Treat as success since we got 200
        }
      } else if (resp.statusCode == 401) {
        log('GoodsApi: 401 Unauthorized - Missing or invalid token');
        return false;
      } else {
        log('GoodsApi: HTTP ${resp.statusCode} - ${resp.body}');
        return false;
      }
    } catch (e) {
      // You may want to log the error in real app
      return false;
    }
  }

  Future<List<GoodsDTO>> getAllGoods() async {
    final normalized = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalized/api/v1/goods/getAllGoods');
    final headers = ApiUtils.getAuthenticatedHeaders();

    try {
      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final List<dynamic> data = jsonDecode(resp.body);
        return data.map((e) => GoodsDTO.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateGood(int id, String name) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$normalizedBase/api/v1/goods/update/$id');
    final headers = ApiUtils.getAuthenticatedHeaders();
    final body = jsonEncode({'name': name});
    try {
      final resp = await http
          .put(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteGood(int id) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$normalizedBase/api/v1/goods/deleteById/$id');
    final headers = ApiUtils.getAuthenticatedHeaders();
    try {
      final resp = await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
