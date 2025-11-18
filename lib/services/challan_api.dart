// challan_api.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../utils/token_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

// Safe web-only import (won't cause errors on mobile/desktop)
import 'dart:html' as html if (dart.library.html) 'dart:html';

class ChallanApi {
  final String baseUrl;
  final TokenManager _tokenManager = TokenManager();

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
  // DOWNLOAD & SHOW PDF FROM BACKEND (Best & Final Method)
  // -------------------------------------------------------------------------
  Future<void> downloadAndShowPdf(int challanId) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final url = Uri.parse('$normalizedBase/api/v1/challans/download/$challanId');

    try {
      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode != 200) {
        throw Exception("HTTP ${response.statusCode}");
      }

      final bytes = response.bodyBytes;
      final fileName = 'Challan_$challanId.pdf';

      // ── WEB ──
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
        html.Url.revokeObjectUrl(url);
        return;
      }

      // ── MOBILE (Android/iOS) ──
      if (Platform.isAndroid || Platform.isIOS) {
        final dir = await getApplicationCacheDirectory();
        final file = File("${dir.path}/$fileName");
        await file.writeAsBytes(bytes);

        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Challan #$challanId - Snowcool Trading Co.');
        return;
      }

      // ── DESKTOP (Windows/Mac/Linux) ──
      final dir =
          await getDownloadsDirectory() ?? await getTemporaryDirectory();
      final file = File("${dir.path}/$fileName");
      await file.writeAsBytes(bytes);

      final uri = Uri.file(file.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await Clipboard.setData(ClipboardData(text: file.path));
        debugPrint("PDF saved to: ${file.path} (path copied to clipboard)");
      }
    } catch (e) {
      debugPrint("PDF download failed for challan $challanId: $e");
      rethrow;
    }
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
    // required String contactNumber,
    required List<Map<String, dynamic>> items,
    // required String email,
    required String date,
    String? address,
    required String? purchaseOrderNumber,
    double? depositeAmount,
    required String deliveryDetails,
    String? depositeNarration,
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
        'depositeNarration': depositeNarration,
        if (address != null && address.isNotEmpty) 'address': address,
        'date': date,
        'challanNumber': 'AUTO',
        if (purchaseOrderNumber != null && purchaseOrderNumber.isNotEmpty) 'purchaseOrderNumber': purchaseOrderNumber,
        if (depositeAmount != null) 'depositAmount': depositeAmount,
        'deliveryDetails': deliveryDetails,
        'items': items
            .map(
              (item) => {
                'name': item['name'],
                'type': item['type'],
                'qty': item['qty'],
                'srNo': item['srNo'],
                'batchRef': item['srNo'],
              },
            )
            .toList(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/challans/create'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      return response.statusCode == 201 || response.statusCode == 200;
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
                final qty = item['qty'];
                return sum +
                    ((qty is int)
                        ? qty
                        : (qty is num)
                        ? qty.toInt()
                        : 0);
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
  // GET SINGLE CHALLAN
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
          'purchaseOrderNumber': data['purchaseOrderNumber'] ?? '',
          'depositAmount': data['depositAmount'] ?? '',
          'deliveryDetails': data['deliveryDetails'] ?? '',
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching challan: $e');
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // DELETE MULTIPLE CHALLANS
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
      final response = await http
          .post(url, headers: _getHeaders(), body: jsonEncode(ids))
          .timeout(const Duration(seconds: 15));
      return response.statusCode >= 200 && response.statusCode < 300;
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
    // required String contactNumber,
    required List<Map<String, dynamic>> items,
    required String date,
    // required String email,
    required String deliveryDetails,
    required String? purchaseOrderNumber,
    required double? depositeAmount,
    String? depositeNarration,
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
        'deliveryDetails': deliveryDetails,
        'purchaseOrderNumber': purchaseOrderNumber,
        'depositAmount': depositeAmount,
        'depositeNarration': depositeNarration,
        'date': date,
        'items': items
            .map(
              (item) => {
                'name': item['name'],
                'type': item['type'],
                'qty': item['qty'],
                'srNo': item['srNo'],
                'batchRef': item['srNo'],
              },
            )
            .toList(),
      };

      final resp = await http
          .put(url, headers: _getHeaders(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      return resp.statusCode >= 200 && resp.statusCode < 300;
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
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      debugPrint('Error deleting challan: $e');
      return false;
    }
  }
}
