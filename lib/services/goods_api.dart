// goods_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../utils/api_utils.dart';

class GoodsDTO {
  final String name;
  final int? id;

  GoodsDTO({required this.name, this.id});

  factory GoodsDTO.fromJson(Map<String, dynamic> json) {
    return GoodsDTO(
      name: json['name'] as String,
      id: json['id'] as int?,
    );
  }
}

class GoodsApi {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<GoodsDTO>> getAllGoods() async {
    final normalized = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final url = Uri.parse('$normalized/api/v1/goods/getAllGoods');
    final headers = ApiUtils.getAuthenticatedHeaders();

    try {
      final resp = await http.get(url, headers: headers).timeout(const Duration(seconds: 10));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final List<dynamic> data = jsonDecode(resp.body);
        return data.map((e) => GoodsDTO.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}