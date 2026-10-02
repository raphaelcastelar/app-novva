import 'package:dio/dio.dart';

abstract interface class DocumentsRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchDocuments();
}

class DioDocumentsRemoteDataSource implements DocumentsRemoteDataSource {
  const DioDocumentsRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<Map<String, dynamic>>> fetchDocuments() async {
    final response = await _dio.get<Map<String, dynamic>>(
      'documents',
      queryParameters: const {'page': 1, 'limit': 100},
    );
    final items = response.data?['items'];
    if (items is! List) {
      throw const FormatException('Resposta inválida ao carregar documentos.');
    }

    return items
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }
}
