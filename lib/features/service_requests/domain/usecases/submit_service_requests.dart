import '../entities/service_request_drafts.dart';
import '../repositories/service_request_repository.dart';

class SubmitDocumentRequest {
  const SubmitDocumentRequest(this._repository);
  final ServiceRequestRepository _repository;
  Future<CreatedServiceRequest> call(DocumentRequestDraft draft) =>
      _repository.submitDocument(draft);
}

class SubmitInvoiceRequest {
  const SubmitInvoiceRequest(this._repository);
  final ServiceRequestRepository _repository;
  Future<CreatedServiceRequest> call(InvoiceRequestDraft draft) =>
      _repository.submitInvoice(draft);
}
