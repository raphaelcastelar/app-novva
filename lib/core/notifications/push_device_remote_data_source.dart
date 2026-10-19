import 'package:dio/dio.dart';

class PushDeviceRemoteDataSource {
  const PushDeviceRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> register(String token) async {
    await _dio.put<void>(
      'devices/current',
      data: {
        'token': token,
        'platform': 'IOS',
      },
    );
  }

  Future<void> remove(String token) async {
    await _dio.delete<void>(
      'devices/current',
      data: {'token': token},
    );
  }
}
