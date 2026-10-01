import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/service_request_remote_datasource.dart';
import '../../data/repositories/service_request_repository_impl.dart';
import '../../domain/entities/service_request_drafts.dart';
import '../../domain/repositories/service_request_repository.dart';
import '../../domain/usecases/submit_service_requests.dart';

const localDoctor = LocalDoctorIdentity(
  cpf: '12831146747',
  name: 'Dra. Marina Almeida',
  email: 'marina@example.com',
  company: 'Clínica Marina Saúde',
  crm: 'CRM 52.184-SP',
  specialty: 'Cardiologia',
);

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
final pendingInvoiceDraftProvider = StateProvider<InvoiceRequestDraft?>((_) => null);
final requestSubmissionProvider = StateProvider<AsyncValue<CreatedServiceRequest?>>(
  (_) => const AsyncData(null),
);
