import 'package:dio/dio.dart';

import '../../domain/entities/service_request_drafts.dart';

abstract interface class ServiceRequestRemoteDataSource {
  Future<Map<String, dynamic>> createDocument(DocumentRequestDraft draft);
  Future<Map<String, dynamic>> createInvoice(InvoiceRequestDraft draft);
  Future<Map<String, dynamic>?> fetchInvoiceDraft();
  Future<Map<String, dynamic>> saveInvoiceDraft(InvoiceRequestDraft draft);
  Future<void> deleteInvoiceDraft();
  Future<List<Map<String, dynamic>>> fetchInvoiceDescriptionFavorites();
  Future<Map<String, dynamic>> favoriteInvoiceDescription(String description);
  Future<void> removeInvoiceDescriptionFavorite(String id);
}

class DioServiceRequestRemoteDataSource
    implements ServiceRequestRemoteDataSource {
  const DioServiceRequestRemoteDataSource(this._dio);
  final Dio _dio;

  @override
  Future<Map<String, dynamic>> createDocument(
      DocumentRequestDraft draft) async {
    final now = DateTime.now();
    final response = await _dio.post<Map<String, dynamic>>(
      'documents',
      data: {
        'title': draft.title,
        'category': draft.category,
        'description': draft.description,
        if (draft.documentTypeId != null)
          'documentTypeId': draft.documentTypeId,
        'month': now.month,
        'year': now.year,
      },
    );
    return response.data!;
  }

  @override
  Future<Map<String, dynamic>> createInvoice(InvoiceRequestDraft draft) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'invoices',
      data: {
        'takerCnpj': draft.takerCnpj.replaceAll(RegExp(r'\D'), ''),
        'takerName': draft.takerName,
        'municipality': draft.municipality,
        'serviceDate': draft.serviceDate.toIso8601String().split('T').first,
        'amount': draft.amount,
        'taxationCode': draft.taxationCode,
        'description': draft.description,
      },
    );
    return response.data!;
  }

  Map<String, dynamic> _invoiceData(InvoiceRequestDraft draft) => {
        'takerCnpj': draft.takerCnpj.replaceAll(RegExp(r'\D'), ''),
        'takerName': draft.takerName,
        'municipality': draft.municipality,
        'serviceDate': draft.serviceDate.toIso8601String().split('T').first,
        'amount': draft.amount,
        'taxationCode': draft.taxationCode,
        'description': draft.description,
      };

  @override
  Future<Map<String, dynamic>?> fetchInvoiceDraft() async {
    final response = await _dio.get<Map<String, dynamic>?>('invoice-draft');
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> saveInvoiceDraft(
    InvoiceRequestDraft draft,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      'invoice-draft',
      data: _invoiceData(draft),
    );
    return response.data!;
  }

  @override
  Future<void> deleteInvoiceDraft() => _dio.delete<void>('invoice-draft');

  @override
  Future<List<Map<String, dynamic>>> fetchInvoiceDescriptionFavorites() async {
    final response =
        await _dio.get<List<dynamic>>('invoice-description-favorites');
    return (response.data ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> favoriteInvoiceDescription(
    String description,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'invoice-description-favorites',
      data: {'description': description},
    );
    return response.data!;
  }

  @override
  Future<void> removeInvoiceDescriptionFavorite(String id) =>
      _dio.delete<void>('invoice-description-favorites/$id');
}
