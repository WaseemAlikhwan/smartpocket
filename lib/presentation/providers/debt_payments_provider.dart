import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/debt_payment_entity.dart';
import 'repository_providers.dart';

final debtPaymentsProvider =
    FutureProvider.autoDispose.family<List<DebtPaymentEntity>, String>((ref, debtId) async {
  return ref.watch(debtRepositoryProvider).getPaymentsForDebt(debtId);
});
