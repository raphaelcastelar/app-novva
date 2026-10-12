import 'package:dio/dio.dart';

class NoticesRemoteDataSource {
  const NoticesRemoteDataSource(this.dio);
  final Dio dio;
  Future<List<Map<String, dynamic>>> list() async {
    final response = await dio.get<List<dynamic>>('notices');
    return (response.data ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<void> markRead(String id) => dio.post<void>('notices/$id/read');
  Future<List<int>> download(String id) async =>
      (await dio.get<List<int>>('notices/$id/file',
              options: Options(responseType: ResponseType.bytes)))
          .data ??
      const [];
}
