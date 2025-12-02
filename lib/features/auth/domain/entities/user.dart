import 'package:equatable/equatable.dart';

/// User entity - pure Dart object without any JSON logic
/// This is the domain representation of a user
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String? avatarUrl;
  final String role;
  final String status;
  final double trustScore;
  final String? idCardNum;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    this.avatarUrl,
    required this.role,
    required this.status,
    required this.trustScore,
    this.idCardNum,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if user is a renter
  bool get isRenter => role == 'RENTER';

  /// Check if user is an owner
  bool get isOwner => role == 'OWNER';

  /// Check if user is an admin
  bool get isAdmin => role == 'ADMIN';

  /// Check if user is active
  bool get isActive => status == 'ACTIVE';

  /// Check if user is pending verification
  bool get isPending => status == 'PENDING';

  /// Check if user is blocked
  bool get isBlocked => status == 'BLOCKED';

  /// Get display role name
  String get displayRole {
    switch (role) {
      case 'RENTER':
        return 'Người thuê xe';
      case 'OWNER':
        return 'Chủ xe';
      case 'ADMIN':
        return 'Quản trị viên';
      default:
        return role;
    }
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        phone,
        avatarUrl,
        role,
        status,
        trustScore,
        idCardNum,
        address,
        createdAt,
        updatedAt,
      ];

  UserEntity copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? role,
    String? status,
    double? trustScore,
    String? idCardNum,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      trustScore: trustScore ?? this.trustScore,
      idCardNum: idCardNum ?? this.idCardNum,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

