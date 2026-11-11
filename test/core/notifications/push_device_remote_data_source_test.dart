import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novva_app/core/notifications/push_device_remote_data_source.dart';

void main() {
  Future<Map<String, dynamic>> registeredPayload(
      TargetPlatform platform) async {
    late Map<String, dynamic> payload;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            payload = Map<String, dynamic>.from(options.data as Map);
            handler.resolve(Response(requestOptions: options, statusCode: 204));
          },
        ),
      );
    await PushDeviceRemoteDataSource(dio, platform: platform)
        .register('fcm-token');
    return payload;
  }

  test('registra dispositivos Android como ANDROID', () async {
    expect(
      await registeredPayload(TargetPlatform.android),
      {'token': 'fcm-token', 'platform': 'ANDROID'},
    );
  });

  test('registra dispositivos iOS como IOS', () async {
    expect(
      await registeredPayload(TargetPlatform.iOS),
      {'token': 'fcm-token', 'platform': 'IOS'},
    );
  });
}
