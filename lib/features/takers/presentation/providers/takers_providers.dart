import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/takers_remote_data_source.dart';
import '../../domain/entities/taker.dart';

final takersRemoteDataSourceProvider = Provider(
  (ref) => TakersRemoteDataSource(
    DioClient(ref.watch(tokenManagerProvider)).dio,
  ),
);

final takersProvider = StateNotifierProvider.autoDispose<TakersController,
    AsyncValue<List<Taker>>>(
  (ref) => TakersController(ref.watch(takersRemoteDataSourceProvider)),
);

class TakersController extends StateNotifier<AsyncValue<List<Taker>>> {
  TakersController(this._remote) : super(const AsyncLoading()) {
    load();
  }

  final TakersRemoteDataSource _remote;

  Future<void> load() async {
    final previous = state.valueOrNull;
    if (previous == null) state = const AsyncLoading();
    try {
      state = AsyncData(await _remote.fetch());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<Taker> save({
    Taker? existing,
    required String name,
    required String cnpj,
    required String municipality,
  }) async {
    final saved = existing == null
        ? await _remote.create(
            name: name,
            cnpj: cnpj,
            municipality: municipality,
          )
        : await _remote.update(
            existing.id,
            name: name,
            cnpj: cnpj,
            municipality: municipality,
          );
    final items = [...?state.valueOrNull];
    items.removeWhere((item) => item.id == saved.id);
    items.add(saved);
    items.sort(
      (first, second) =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    );
    state = AsyncData(items);
    return saved;
  }

  Future<void> remove(String id) async {
    await _remote.delete(id);
    state = AsyncData(
      [...?state.valueOrNull]..removeWhere((item) => item.id == id),
    );
  }
}
