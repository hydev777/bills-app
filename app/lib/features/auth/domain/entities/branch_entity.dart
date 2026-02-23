import 'package:equatable/equatable.dart';

class BranchEntity extends Equatable {
  const BranchEntity({
    required this.id,
    required this.name,
    required this.code,
    this.isPrimary = false,
    this.canLogin = true,
  });

  final int id;
  final String name;
  final String code;
  final bool isPrimary;
  final bool canLogin;

  @override
  List<Object?> get props => [id, name, code, isPrimary, canLogin];
}
