import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/documents_remote_datasource.dart';
import '../../data/repositories/documents_repository_impl.dart';
import '../../domain/entities/document_item.dart';
import '../../domain/repositories/documents_repository.dart';
import '../../domain/usecases/fetch_documents.dart';

final documentRequestFeedbackProvider = StateProvider<bool>((_) => false);

final documentsDioProvider = Provider(
  (ref) => DioClient(ref.watch(tokenManagerProvider)).dio,
);

final documentsRemoteDataSourceProvider = Provider<DocumentsRemoteDataSource>(
  (ref) => DioDocumentsRemoteDataSource(ref.watch(documentsDioProvider)),
);

final documentsRepositoryProvider = Provider<DocumentsRepository>(
  (ref) => DocumentsRepositoryImpl(
    ref.watch(documentsRemoteDataSourceProvider),
  ),
);

final fetchDocumentsProvider = Provider(
  (ref) => FetchDocuments(ref.watch(documentsRepositoryProvider)),
);

final documentsProvider = StateNotifierProvider.autoDispose<DocumentsController,
    AsyncValue<List<DocumentItem>>>(
  (ref) => DocumentsController(ref.watch(fetchDocumentsProvider)),
);

class DocumentsController
    extends StateNotifier<AsyncValue<List<DocumentItem>>> {
  DocumentsController(
    this._fetchDocuments, {
    Duration? refreshInterval = const Duration(seconds: 10),
  }) : super(const AsyncLoading()) {
    unawaited(refresh(showLoading: true));
    if (refreshInterval != null) {
      _timer = Timer.periodic(
        refreshInterval,
        (_) => unawaited(refresh()),
      );
    }
  }

  final FetchDocuments _fetchDocuments;
  Timer? _timer;
  bool _isRefreshing = false;

  Future<void> refresh({bool showLoading = false}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    final previous = state.valueOrNull;
    if (showLoading && previous == null) {
      state = const AsyncLoading();
    }

    try {
      state = AsyncData(await _fetchDocuments());
    } catch (error, stackTrace) {
      if (previous == null) {
        state = AsyncError(error, stackTrace);
      }
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
