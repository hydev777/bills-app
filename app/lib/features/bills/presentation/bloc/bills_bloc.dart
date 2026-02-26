import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/bills/domain/entities/bill_entity.dart';
import 'package:app/features/bills/domain/usecases/get_bills_usecase.dart';
import 'package:app/features/bills/domain/usecases/get_bill_by_id_usecase.dart';
import 'package:app/features/bills/domain/usecases/get_bill_by_public_id_usecase.dart';

import 'bills_event.dart';
import 'bills_state.dart';

class BillsBloc extends Bloc<BillsEvent, BillsState> {
  BillsBloc({
    required GetBillsUseCase getBillsUseCase,
    required GetBillByIdUseCase getBillByIdUseCase,
    required GetBillByPublicIdUseCase getBillByPublicIdUseCase,
  })  : _getBillsUseCase = getBillsUseCase,
        _getBillByIdUseCase = getBillByIdUseCase,
        _getBillByPublicIdUseCase = getBillByPublicIdUseCase,
        super(const BillsInitial()) {
    on<BillsLoaded>(_onBillsLoaded);
    on<BillSearchRequested>(_onBillSearchRequested);
  }

  final GetBillsUseCase _getBillsUseCase;
  final GetBillByIdUseCase _getBillByIdUseCase;
  final GetBillByPublicIdUseCase _getBillByPublicIdUseCase;

  Future<void> _onBillsLoaded(
    BillsLoaded event,
    Emitter<BillsState> emit,
  ) async {
    emit(const BillsLoading());

    final result = await _getBillsUseCase.call(
      status: event.status,
      userId: event.userId,
      clientId: event.clientId,
      limit: event.limit,
      offset: event.offset,
    );

    result.fold(
      onSuccess: (data) => emit(
        BillsLoadedState(
          bills: data.bills,
          total: data.total,
          limit: data.limit,
          offset: data.offset,
        ),
      ),
      onFailure: (f) => emit(BillsError(f.displayMessage)),
    );
  }

  Future<void> _onBillSearchRequested(
    BillSearchRequested event,
    Emitter<BillsState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      add(const BillsLoaded());
      return;
    }

    final id = int.tryParse(query);
    Result<BillEntity, Failure> result;
    if (id != null) {
      result = await _getBillByIdUseCase.call(id: id);
    } else {
      result = await _getBillByPublicIdUseCase.call(publicId: query);
    }

    await result.when<Future<void>>(
      success: (bill) async {
        emit(
          BillsLoadedState(
            bills: [bill],
            total: 1,
            limit: 1,
            offset: 0,
            activeSearchQuery: query,
          ),
        );
      },
      failure: (f) async {
        emit(BillsError(f.displayMessage));
      },
    );
  }
}

