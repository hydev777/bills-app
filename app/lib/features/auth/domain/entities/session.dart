import 'package:equatable/equatable.dart';

import 'branch_entity.dart';
import 'user_entity.dart';

class Session extends Equatable {
  const Session({
    required this.token,
    required this.user,
    this.accessibleBranches = const [],
    this.selectedBranchId,
  });

  final String token;
  final UserEntity user;
  final List<BranchEntity> accessibleBranches;
  final int? selectedBranchId;

  @override
  List<Object?> get props => [token, user, accessibleBranches, selectedBranchId];
}
