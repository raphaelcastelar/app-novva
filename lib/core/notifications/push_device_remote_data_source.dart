import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class PushDeviceRemoteDataSource {
  const PushDeviceRemoteDataSource(this._dio, {TargetPlatform? platform})
      : _platform = platform;

  final Dio _dio;
  final TargetPlatform? _platform;

  /// Valor aceito pela API em `PushPlatform` (`IOS` ou `ANDROID`).
  @visibleForTesting
  String get platformName =>
      (_platform ?? defaultTargetPlatform) == TargetPlatform.android
          ? 'ANDROID'
          : 'IOS';

  Future<void> register(String token) async {
    await _dio.put<void>(
      'devices/current',
      data: {
        'token': token,
        'platform': platformName,
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
