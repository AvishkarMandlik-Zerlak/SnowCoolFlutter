import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../utils/token_manager.dart'; // ← ADD THIS IMPORT

/// Structured response from the login API.
class LoginResponse {
  final bool success;
  final String? message; // human readable message
  final String? field; // 'username' | 'password' | null
  final String? token;
  final int? id;
  final String? role;

  // ──────────────────────────────────────────────────────────────
  // NEW PERMISSION FLAGS (added)
  // ──────────────────────────────────────────────────────────────
  final bool? canCreateCustomers;
  final bool? canManageChallans;
  final bool? canManageGoodsItems;
  final bool? canManageProfiles;
  final bool? canManageSettings;
  final bool? canManagePassbook; // NEW

  LoginResponse({
    required this.success,
    this.message,
    this.field,
    this.token,
    this.id,
    this.role,
    // NEW
    this.canCreateCustomers,
    this.canManageChallans,
    this.canManageGoodsItems,
    this.canManageProfiles,
    this.canManageSettings,
    this.canManagePassbook,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] == true || json['token'] != null,
      message: json['message']?.toString(),
      field: json['field']?.toString(),
      token: json['token']?.toString(),
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      role: json['role']?.toString(),
      // NEW: Extract permission booleans
      canCreateCustomers: json['canCreateCustomers'] as bool?,
      canManageChallans: json['canManageChallans'] as bool?,
      canManageGoodsItems: json['canManageGoodsItems'] as bool?,
      canManageProfiles: json['canManageProfiles'] as bool?,
      canManageSettings: json['canManageSettings'] as bool?,
      canManagePassbook: json['canManagePassbook'] as bool?, // NEW
    );
  }

  /// Helper to convert back to JSON (used for TokenManager)
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'id': id,
      'role': role,
      'canCreateCustomers': canCreateCustomers,
      'canManageChallans': canManageChallans,
      'canManageGoodsItems': canManageGoodsItems,
      'canManageProfiles': canManageProfiles,
      'canManageSettings': canManageSettings,
      'canManagePassbook': canManagePassbook,
    };
  }
}

/// Simple login API wrapper.
class LoginApi {
  final String baseUrl;

  LoginApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Sends username and password to backend and returns a [LoginResponse].
  /// The backend is expected to return JSON like:
  /// { "success": false, "message": "Invalid username", "field": "username" }
  Future<LoginResponse> login(String username, String password) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$normalizedBase/api/v1/auth/login');
    final body = jsonEncode({'username': username, 'password': password});

    // Debug prints (ok during development)
    print('LoginApi: POST $uri');
    print('LoginApi: body=$body');

    try {
      final resp = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 10));

      print('LoginApi: status=${resp.statusCode}');
      print('LoginApi: response=${resp.body}');

      if (resp.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonResp =
              jsonDecode(resp.body) as Map<String, dynamic>;
          final loginResponse = LoginResponse.fromJson(jsonResp);

          // ──────────────────────────────────────────────────────
          // NEW: Save all data to TokenManager on successful login
          // ──────────────────────────────────────────────────────
          final tm = TokenManager();
          tm.setToken(loginResponse.token);
          tm.setId(loginResponse.id);
          tm.setRole(loginResponse.role);
          tm.setPermissionsFromJson(jsonResp); // ← Saves all can* flags

          return loginResponse;
        } catch (e) {
          print('LoginApi: failed to decode JSON: $e');
          return LoginResponse(
            success: false,
            message: 'Invalid server response',
          );
        }
      } else {
        // Handle authentication errors with proper user-friendly messages
        if (resp.statusCode == 400 || resp.statusCode == 401) {
          // Try to parse error message from body first
          try {
            final Map<String, dynamic> jsonResp =
                jsonDecode(resp.body) as Map<String, dynamic>;
            final response = LoginResponse.fromJson(jsonResp);
            // If no specific message, provide default incorrect credentials message
            return LoginResponse(
              success: false,
              message:
                  response.message ??
                  'Incorrect username or password. Please check your credentials and try again.',
              field: response.field,
            );
          } catch (_) {
            // If can't parse response, return default authentication error
            return LoginResponse(
              success: false,
              message:
                  'Incorrect username or password. Please check your credentials and try again.',
            );
          }
        } else {
          // For other status codes, try to parse error or show generic message
          try {
            final Map<String, dynamic> jsonResp =
                jsonDecode(resp.body) as Map<String, dynamic>;
            return LoginResponse.fromJson(jsonResp);
          } catch (_) {
            return LoginResponse(
              success: false,
              message: 'Unable to connect to server. Please try again later.',
            );
          }
        }
      }
    } on TimeoutException catch (e) {
      print('LoginApi: network error: $e');
      return LoginResponse(success: false, message: 'Network error: Timeout');
    } catch (e) {
      print('LoginApi: network error: $e');
      return LoginResponse(success: false, message: 'Network error: $e');
    }
  }
}