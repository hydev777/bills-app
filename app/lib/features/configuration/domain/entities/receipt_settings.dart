import 'package:equatable/equatable.dart';

class ReceiptSettings extends Equatable {
  const ReceiptSettings({
    this.showProducts = true,
    this.showUnitPrices = true,
    this.showSubtotal = true,
    this.showTax = true,
    this.showTotal = true,
    this.showCashReceived = true,
    this.showChange = true,
  });

  final bool showProducts;
  final bool showUnitPrices;
  final bool showSubtotal;
  final bool showTax;
  final bool showTotal;
  final bool showCashReceived;
  final bool showChange;

  static const defaults = ReceiptSettings();

  ReceiptSettings copyWith({
    bool? showProducts,
    bool? showUnitPrices,
    bool? showSubtotal,
    bool? showTax,
    bool? showTotal,
    bool? showCashReceived,
    bool? showChange,
  }) {
    return ReceiptSettings(
      showProducts: showProducts ?? this.showProducts,
      showUnitPrices: showUnitPrices ?? this.showUnitPrices,
      showSubtotal: showSubtotal ?? this.showSubtotal,
      showTax: showTax ?? this.showTax,
      showTotal: showTotal ?? this.showTotal,
      showCashReceived: showCashReceived ?? this.showCashReceived,
      showChange: showChange ?? this.showChange,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'showProducts': showProducts,
      'showUnitPrices': showUnitPrices,
      'showSubtotal': showSubtotal,
      'showTax': showTax,
      'showTotal': showTotal,
      'showCashReceived': showCashReceived,
      'showChange': showChange,
    };
  }

  factory ReceiptSettings.fromJson(Map<String, Object?> json) {
    return ReceiptSettings(
      showProducts: json['showProducts'] as bool? ?? true,
      showUnitPrices: json['showUnitPrices'] as bool? ?? true,
      showSubtotal: json['showSubtotal'] as bool? ?? true,
      showTax: json['showTax'] as bool? ?? true,
      showTotal: json['showTotal'] as bool? ?? true,
      showCashReceived: json['showCashReceived'] as bool? ?? true,
      showChange: json['showChange'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
    showProducts,
    showUnitPrices,
    showSubtotal,
    showTax,
    showTotal,
    showCashReceived,
    showChange,
  ];
}

