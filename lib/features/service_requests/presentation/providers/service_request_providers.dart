import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/service_request_remote_datasource.dart';
import '../../data/repositories/service_request_repository_impl.dart';
import '../../domain/entities/service_request_drafts.dart';
import '../../domain/repositories/service_request_repository.dart';
import '../../domain/usecases/submit_service_requests.dart';

final serviceRequestDioProvider = Provider(
  (ref) => DioClient(ref.watch(tokenManagerProvider)).dio,
);
final serviceRequestRemoteDataSourceProvider =
    Provider<ServiceRequestRemoteDataSource>(
  (ref) => DioServiceRequestRemoteDataSource(
    ref.watch(serviceRequestDioProvider),
  ),
);
final serviceRequestRepositoryProvider = Provider<ServiceRequestRepository>(
  (ref) => ServiceRequestRepositoryImpl(
    ref.watch(serviceRequestRemoteDataSourceProvider),
  ),
);
final submitDocumentRequestProvider = Provider(
  (ref) => SubmitDocumentRequest(ref.watch(serviceRequestRepositoryProvider)),
);
final submitInvoiceRequestProvider = Provider(
  (ref) => SubmitInvoiceRequest(ref.watch(serviceRequestRepositoryProvider)),
);
final pendingInvoiceDraftProvider =
    StateProvider<InvoiceRequestDraft?>((_) => null);
final requestSubmissionProvider =
    StateProvider<AsyncValue<CreatedServiceRequest?>>(
  (_) => const AsyncData(null),
);

final invoiceDraftSavingProvider = StateProvider<AsyncValue<void>>(
  (_) => const AsyncData(null),
);

final invoiceDescriptionFavoritesProvider = StateNotifierProvider.autoDispose<
    InvoiceDescriptionFavoritesController,
    AsyncValue<List<InvoiceDescriptionFavorite>>>(
  (ref) => InvoiceDescriptionFavoritesController(
    ref.watch(serviceRequestRepositoryProvider),
  ),
);

class InvoiceDescriptionFavoritesController
    extends StateNotifier<AsyncValue<List<InvoiceDescriptionFavorite>>> {
  InvoiceDescriptionFavoritesController(this._repository)
      : super(const AsyncLoading()) {
    load();
  }

  final ServiceRequestRepository _repository;

  Future<void> load() async {
    state = await AsyncValue.guard(
      _repository.fetchInvoiceDescriptionFavorites,
    );
  }

  Future<void> toggle(String description) async {
    final items = [...?state.valueOrNull];
    final index = items.indexWhere((item) => item.description == description);
    if (index >= 0) {
      final favorite = items[index];
      await _repository.removeInvoiceDescriptionFavorite(favorite.id);
      items.removeAt(index);
    } else {
      items.add(await _repository.favoriteInvoiceDescription(description));
    }
    state = AsyncData(items);
  }
}
