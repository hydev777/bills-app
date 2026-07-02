import 'package:equatable/equatable.dart';

import 'package:app/features/configuration/domain/entities/receipt_settings.dart';

enum ReceiptConfigurationStatus { initial, loading, loaded, error }

class ReceiptConfigurationState extends Equatable {
  const ReceiptConfigurationState({
    this.status = ReceiptConfigurationStatus.initial,
    this.settings = ReceiptSettings.defaults,
    this.message,
  });

  final ReceiptConfigurationStatus status;
  final ReceiptSettings settings;
  final String? message;

  ReceiptConfigurationState copyWith({
    ReceiptConfigurationStatus? status,
    ReceiptSettings? settings,
    String? message,
    bool clearMessage = false,
  }) {
    return ReceiptConfigurationState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, settings, message];
}

