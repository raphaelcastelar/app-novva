import 'package:dio/dio.dart';

import '../../domain/entities/service_request_drafts.dart';

abstract interface class ServiceRequestRemoteDataSource {
  Future<Map<String, dynamic>> createDocument(DocumentRequestDraft draft);
  Future<Map<String, dynamic>> createInvoice(InvoiceRequestDraft draft);
}

class DioServiceRequestRemoteDataSource
    implements ServiceRequestRemoteDataSource {
  const DioServiceRequestRemoteDataSource(this._dio);
  final Dio _dio;

  @override
  Future<Map<String, dynamic>> createDocument(DocumentRequestDraft draft) async {
    final now = DateTime.now();
    final response = await _dio.post<Map<String, dynamic>>(
      'mobile/documents/',
      data: {
        'doctor': draft.doctor.toJson(),
        'title': draft.title,
        'category': draft.category,
        'description': draft.description,
        'month': now.month,
        'year': now.year,
      },
    );
    return response.data!;
  }

  @override
  Future<Map<String, dynamic>> createInvoice(InvoiceRequestDraft draft) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'mobile/invoices/',
      data: {
        'doctor': draft.doctor.toJson(),
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
}
