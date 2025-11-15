// application_settings_api.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

// Conditional import for File (only on mobile, ignored on web)

import 'package:snow_trading_cool/utils/api_config.dart';

/// ---------------------------------------------------------------------------
/// DTO – matches the JSON that the Spring controller returns
/// ---------------------------------------------------------------------------
class ApplicationSettingsDTO {
  final int? id;
  final String? logoBase64; // <-- Base64 string (sent to backend)
  final String? signatureBase64; // <-- Base64 string
  final String? invoicePrefix;
  final String? challanNumberFormat;
  final int? challanSequence;
  final String? challanSequenceResetPolicy;
  final String? sequenceLastResetDate;
  final String? createdAt;
  final String? updatedAt;
  final String? termsAndConditions;

  ApplicationSettingsDTO({
    this.id,
    this.logoBase64,
    this.signatureBase64,
    this.invoicePrefix,
    this.challanNumberFormat,
    this.challanSequence,
    this.challanSequenceResetPolicy,
    this.sequenceLastResetDate,
    this.createdAt,
    this.updatedAt,
    this.termsAndConditions,
  });

  /// -------------------------------------------------
  /// Convert JSON from backend → DTO
  /// Backend sends:
  ///   "logo": [137,80,78,71,...]   (byte array)
  ///   "signature": [...]
  /// -------------------------------------------------
  factory ApplicationSettingsDTO.fromJson(Map<String, dynamic> json) {
    return ApplicationSettingsDTO(
      id: json['id'] as int?,
      logoBase64: _encodeByteArray(json['logo']),
      signatureBase64: _encodeByteArray(json['signature']),
      invoicePrefix: json['invoicePrefix'] as String?,
      challanNumberFormat: json['challanNumberFormat'] as String?,
      challanSequence: json['challanSequence'] as int?,
      challanSequenceResetPolicy: json['challanSequenceResetPolicy'] as String?,
      sequenceLastResetDate: json['sequenceLastResetDate'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      termsAndConditions: json['termsAndConditions'] as String?,
    );
  }

  /// Helper: turn a JSON list of ints (byte array) → Base64 string
  static String? _encodeByteArray(dynamic data) {
    if (data == null) return null;
    if (data is List<int>) {
      return base64Encode(data);
    }
    // Some back‑ends send a string already – pass through
    if (data is String) return data;
    return null;
  }

  /// -------------------------------------------------
  /// Convert DTO → JSON for POST / PUT
  /// -------------------------------------------------
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    if (logoBase64 != null) map['logo'] = logoBase64;
    if (signatureBase64 != null) map['signature'] = signatureBase64;
    if (invoicePrefix != null) map['invoicePrefix'] = invoicePrefix;
    if (challanNumberFormat != null)
      map['challanNumberFormat'] = challanNumberFormat;
    if (challanSequence != null) map['challanSequence'] = challanSequence;
    if (challanSequenceResetPolicy != null)
      map['challanSequenceResetPolicy'] = challanSequenceResetPolicy;
    if (sequenceLastResetDate != null)
      map['sequenceLastResetDate'] = sequenceLastResetDate;
    if (termsAndConditions != null)
      map['termsAndConditions'] = termsAndConditions;
    return map;
  }
}

/// ---------------------------------------------------------------------------
/// API client
/// ---------------------------------------------------------------------------
class ApplicationSettingsApi {
  final String _baseUrl = ApiConfig.baseUrl;

  final String token;

  ApplicationSettingsApi({required this.token});

  /// GET /getSettings
  Future<ApplicationSettingsDTO?> getSettings() async {
    final uri = Uri.parse('$_baseUrl/api/v1/settings/getSettings');
    final response = await http
        .get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ApplicationSettingsDTO.fromJson(json);
    } else if (response.statusCode == 204) {
      return null; // No settings yet
    } else {
      throw Exception(
        'Failed to load settings: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// POST /create  or  PUT /update
  Future<ApplicationSettingsDTO> _send(
    String method,
    ApplicationSettingsDTO dto,
  ) async {
    final url = method == 'POST'
        ? '$_baseUrl/api/v1/settings//create'
        : '$_baseUrl/api/v1/settings/update';
    final body = jsonEncode(dto.toJson());

    final request = http.Request(method, Uri.parse(url))
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Content-Type'] = 'application/json'
      ..body = body;

    final streamed = await request.send().timeout(const Duration(seconds: 15));
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      return ApplicationSettingsDTO.fromJson(json);
    } else {
      throw Exception('$method failed: ${resp.statusCode} – ${resp.body}');
    }
  }

  Future<ApplicationSettingsDTO> createSettings(ApplicationSettingsDTO dto) =>
      _send('POST', dto);

  Future<ApplicationSettingsDTO> updateSettings(ApplicationSettingsDTO dto) =>
      _send('PUT', dto);
}
