import 'package:equatable/equatable.dart';

class ItbisRateEntity extends Equatable {
  const ItbisRateEntity({
    required this.id,
    required this.name,
    required this.percentage,
  });

  final int id;
  final String name;
  final double percentage;

  @override
  List<Object?> get props => [id, name, percentage];
}
