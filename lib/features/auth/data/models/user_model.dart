import '../../domain/entities/user.dart';

/// User role enum matching backend
enum UserRole {
  RENTER,
  OWNER,
  ADMIN;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => UserRole.RENTER,
    );
  }
}

/// User status enum matching backend
enum UserStatus {
  ACTIVE,
  PENDING,
  BLOCKED;

  static UserStatus fromString(String value) {
    return UserStatus.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => UserStatus.ACTIVE,
    );
  }
}

/// User model for API responses
/// Field names must match the JSON returned by NestJS exactly
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String? avatarUrl;
  final UserRole role;
  final UserStatus status;
  final double trustScore;
  final String? idCardNum;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
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

  /// Parse from JSON response
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: UserRole.fromString(json['role'] as String),
      status: UserStatus.fromString(json['status'] as String),
      trustScore: (json['trustScore'] as num).toDouble(),
      idCardNum: json['idCardNum'] as String?,
      address: json['address'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'role': role.name,
      'status': status.name,
      'trustScore': trustScore,
      'idCardNum': idCardNum,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Convert to domain entity
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
      role: role.name,
      status: status.name,
      trustScore: trustScore,
      idCardNum: idCardNum,
      address: address,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

