import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../utils/api_utils.dart';

class ChallanApi {
  final String baseUrl;

  ChallanApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<bool> challanData(
    int customerId,
    String customerName,
    String challanType,
    String location,
    String transporter,
    String vehicleNumber,
    String driverName,
    String driverNumber,
    String mobileNumber,
    String smallRegularQty,
    String smallRegularSrNo,
    String smallFloronQty,
    String smallFloronSrNo,
    String bigRegularQty,
    String bigRegularSrNo,
    String bigFloronQty,
    String bigFloronSrNo,
    String date, // ADDED: Only this parameter
  ) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/challans/create');

    // Parse numeric fields, defaulting to 0 if parsing fails
    int parsedCustomerId = customerId;
    int parseQty(String value) => int.tryParse(value) ?? 0;

    // Build items list expected by backend. Ensure we always send an array
    // (even if empty) so backend code that iterates items doesn't get NPE.
    final List<Map<String, dynamic>> items = [];

    final int sRegQty = parseQty(smallRegularQty);
    if (sRegQty > 0 || (smallRegularSrNo.isNotEmpty)) {
      items.add({
        'product': 'SMALL_REGULAR',
        'quantity': sRegQty,
        'serialNumber': smallRegularSrNo,
      });
    }

    final int sFlorQty = parseQty(smallFloronQty);
    if (sFlorQty > 0 || (smallFloronSrNo.isNotEmpty)) {
      items.add({
        'product': 'SMALL_FLORON',
        'quantity': sFlorQty,
        'serialNumber': smallFloronSrNo,
      });
    }

    final int bRegQty = parseQty(bigRegularQty);
    if (bRegQty > 0 || (bigRegularSrNo.isNotEmpty)) {
      items.add({
        'product': 'BIG_REGULAR',
        'quantity': bRegQty,
        'serialNumber': bigRegularSrNo,
      });
    }

    final int bFlorQty = parseQty(bigFloronQty);
    if (bFlorQty > 0 || (bigFloronSrNo.isNotEmpty)) {
      items.add({
        'product': 'BIG_FLORON',
        'quantity': bFlorQty,
        'serialNumber': bigFloronSrNo,
      });
    }

    // Parse mobile number into a digit-only string for customerPhoneNo
    String parsePhone(String value) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      return digits;
    }

    final String customerPhoneNo = parsePhone(mobileNumber);

    final requestObj = {
      // DTO expects customerId (int) and customerName
      'customerId': parsedCustomerId,
      'customerName': customerName,
      'challanType': challanType,
      // DTO property names
      'siteLocation': location,
      'transporter': transporter,
      'vehicleNumber': vehicleNumber,
      'driverName': driverName,
      'driverNumber': driverNumber,
      // Map phone to DTO.contactNumber
      'contactNumber': customerPhoneNo,
      'items': items, // always present
      'date': date, // ADDED: Send date
    };

    // Log the complete request object in a readable format
    log('Challan Save Request:');
    log(const JsonEncoder.withIndent('  ').convert(requestObj));

    final body = jsonEncode(requestObj);

    // Get authenticated headers
    final headers = ApiUtils.getAuthenticatedHeaders();

    log('ChallanApi: headers=$headers');

    try {
      final resp = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      // Print response for debugging
      log('ChallanApi Response Status: ${resp.statusCode}');
      log('ChallanApi Response Body:');
      try {
        // Try to format the response JSON if it's valid JSON
        final respJson = jsonDecode(resp.body);
        log(const JsonEncoder.withIndent('  ').convert(respJson));
      } catch (e) {
        // If not valid JSON, print as is
        log(resp.body);
      }

      // Treat any 2xx response as success. Many APIs return the created
      // entity (not a {"success":true} envelope) which previously made
      // the client conclude failure.
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return true;
      } else if (resp.statusCode == 401) {
        log('ChallanApi: 401 Unauthorized - Missing or invalid token');
        return false;
      } else {
        log('ChallanApi: HTTP ${resp.statusCode} - ${resp.body}');
        return false;
      }
    } catch (e) {
      // You may want to log the error in real app
      return false;
    }
  }
}