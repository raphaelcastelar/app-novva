import 'package:dio/dio.dart';

import '../domain/entities/taker.dart';

class TakersRemoteDataSource {
  const TakersRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<Taker>> fetch() async {
    final response = await _dio.get<List<dynamic>>('takers');
    return (response.data ?? const [])
        .map((item) => Taker.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }

  Future<Taker> create({
    required String name,
    required String cnpj,
    required String municipality,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'takers',
      data: {
        'name': name.trim(),
        'cnpj': cnpj.replaceAll(RegExp(r'\D'), ''),
        'municipality': municipality.trim(),
      },
    );
    return Taker.fromJson(response.data!);
  }

  Future<Taker> update(
    String id, {
    required String name,
    required String cnpj,
    required String municipality,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      'takers/$id',
      data: {
        'name': name.trim(),
        'cnpj': cnpj.replaceAll(RegExp(r'\D'), ''),
        'municipality': municipality.trim(),
      },
    );
    return Taker.fromJson(response.data!);
  }

  Future<void> delete(String id) => _dio.delete<void>('takers/$id');
}
