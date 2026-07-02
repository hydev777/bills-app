import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/features/configuration/domain/entities/receipt_settings.dart';
import 'package:app/features/configuration/domain/usecases/get_receipt_settings_usecase.dart';
import 'package:app/features/configuration/domain/usecases/save_receipt_settings_usecase.dart';

import 'receipt_configuration_state.dart';

class ReceiptConfigurationCubit extends Cubit<ReceiptConfigurationState> {
  ReceiptConfigurationCubit({
    required GetReceiptSettingsUseCase getReceiptSettingsUseCase,
    required SaveReceiptSettingsUseCase saveReceiptSettingsUseCase,
  }) : _getReceiptSettingsUseCase = getReceiptSettingsUseCase,
       _saveReceiptSettingsUseCase = saveReceiptSettingsUseCase,
       super(const ReceiptConfigurationState());

  final GetReceiptSettingsUseCase _getReceiptSettingsUseCase;
  final SaveReceiptSettingsUseCase _saveReceiptSettingsUseCase;

  Future<void> load() async {
    emit(state.copyWith(status: ReceiptConfigurationStatus.loading));
    final result = await _getReceiptSettingsUseCase();
    final failure = result.errorOrNull;
    final settings = result.valueOrNull;
    if (failure != null || settings == null) {
      emit(
        state.copyWith(
          status: ReceiptConfigurationStatus.error,
          message: failure?.displayMessage ?? 'No se pudo cargar el recibo',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ReceiptConfigurationStatus.loaded,
        settings: settings,
        clearMessage: true,
      ),
    );
  }

  Future<void> updateSettings(ReceiptSettings settings) async {
    emit(state.copyWith(settings: settings));
    final result = await _saveReceiptSettingsUseCase(settings);
    final failure = result.errorOrNull;
    if (failure != null) {
      emit(
        state.copyWith(
          status: ReceiptConfigurationStatus.error,
          message: failure.displayMessage,
        ),
      );
    }
  }
}

