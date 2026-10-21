import '../../domain/entities/service_request_drafts.dart';
import '../../domain/repositories/service_request_repository.dart';
import '../datasources/service_request_remote_datasource.dart';

class ServiceRequestRepositoryImpl implements ServiceRequestRepository {
  const ServiceRequestRepositoryImpl(this._remote);
  final ServiceRequestRemoteDataSource _remote;

  @override
  Future<CreatedServiceRequest> submitDocument(
      DocumentRequestDraft draft) async {
    final json = await _remote.createDocument(draft);
    return CreatedServiceRequest(
      id: json['id'] as String,
      status: json['status'] as String,
    );
  }

  @override
  Future<CreatedServiceRequest> submitInvoice(InvoiceRequestDraft draft) async {
    final json = await _remote.createInvoice(draft);
    return CreatedServiceRequest(
      id: json['id'] as String,
      status: json['status'] as String,
    );
  }

  @override
  Future<InvoiceRequestDraft?> fetchInvoiceDraft() async {
    final json = await _remote.fetchInvoiceDraft();
    return json == null ? null : InvoiceRequestDraft.fromJson(json);
  }

  @override
  Future<void> saveInvoiceDraft(InvoiceRequestDraft draft) async {
    await _remote.saveInvoiceDraft(draft);
  }

  @override
  Future<void> deleteInvoiceDraft() => _remote.deleteInvoiceDraft();

  @override
  Future<List<InvoiceDescriptionFavorite>>
      fetchInvoiceDescriptionFavorites() async {
    final items = await _remote.fetchInvoiceDescriptionFavorites();
    return items
        .map(InvoiceDescriptionFavorite.fromJson)
        .toList(growable: false);
  }

  @override
  Future<InvoiceDescriptionFavorite> favoriteInvoiceDescription(
      String description) async {
    final json = await _remote.favoriteInvoiceDescription(description);
    return InvoiceDescriptionFavorite.fromJson(json);
  }

  @override
  Future<void> removeInvoiceDescriptionFavorite(String id) =>
      _remote.removeInvoiceDescriptionFavorite(id);
}
