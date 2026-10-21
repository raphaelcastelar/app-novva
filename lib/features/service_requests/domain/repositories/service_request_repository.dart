import '../entities/service_request_drafts.dart';

abstract interface class ServiceRequestRepository {
  Future<CreatedServiceRequest> submitDocument(DocumentRequestDraft draft);
  Future<CreatedServiceRequest> submitInvoice(InvoiceRequestDraft draft);
  Future<InvoiceRequestDraft?> fetchInvoiceDraft();
  Future<void> saveInvoiceDraft(InvoiceRequestDraft draft);
  Future<void> deleteInvoiceDraft();
  Future<List<InvoiceDescriptionFavorite>> fetchInvoiceDescriptionFavorites();
  Future<InvoiceDescriptionFavorite> favoriteInvoiceDescription(
    String description,
  );
  Future<void> removeInvoiceDescriptionFavorite(String id);
}
