import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/notices_remote_datasource.dart';
import '../../data/notices_repository_impl.dart';
import '../../domain/entities/notice_item.dart';
import '../../domain/repositories/notices_repository.dart';

final noticesRepositoryProvider = Provider<NoticesRepository>((ref) =>
    NoticesRepositoryImpl(NoticesRemoteDataSource(
        DioClient(ref.watch(tokenManagerProvider)).dio)));
final noticesProvider = FutureProvider.autoDispose<List<NoticeItem>>(
    (ref) => ref.watch(noticesRepositoryProvider).fetchNotices());
