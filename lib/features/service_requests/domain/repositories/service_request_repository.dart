import '../entities/service_request_drafts.dart';

abstract interface class ServiceRequestRepository {
  Future<CreatedServiceRequest> submitDocument(DocumentRequestDraft draft);
  Future<CreatedServiceRequest> submitInvoice(InvoiceRequestDraft draft);
}
