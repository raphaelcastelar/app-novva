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
}
