import 'package:app/features/reports/domain/usecases/get_bill_report_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'reports_event.dart';
import 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  ReportsBloc({required GetBillReportUseCase getBillReportUseCase})
    : _getBillReportUseCase = getBillReportUseCase,
      super(const ReportsInitial()) {
    on<ReportsLoaded>(_onReportsLoaded);
  }

  final GetBillReportUseCase _getBillReportUseCase;

  Future<void> _onReportsLoaded(
    ReportsLoaded event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading(period: event.period, anchorDate: event.anchorDate));
    final result = await _getBillReportUseCase.call(
      period: event.period,
      anchorDate: event.anchorDate,
    );
    result.fold(
      onSuccess: (report) => emit(ReportsLoadedState(report)),
      onFailure: (failure) => emit(
        ReportsError(
          message: failure.displayMessage,
          period: event.period,
          anchorDate: event.anchorDate,
        ),
      ),
    );
  }
}
