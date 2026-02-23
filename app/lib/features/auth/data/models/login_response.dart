import 'package:app/features/auth/data/models/branch_model.dart';
import 'package:app/features/auth/data/models/user_model.dart';

class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.user,
    this.accessibleBranches = const [],
  });

  final String token;
  final UserModel user;
  final List<BranchModel> accessibleBranches;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final branchesList = json['accessibleBranches'] as List<dynamic>?;
    final branches = branchesList
            ?.map((e) => BranchModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return LoginResponse(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessibleBranches: branches,
    );
  }
}
