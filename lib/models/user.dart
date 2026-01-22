import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin,      // Full access
  dj,         // Can manage events
  guest,      // Can only upload
}

class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final List<String> eventIds;  // Events this user owns/manages
  final UserPreferences preferences;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.role = UserRole.dj,
    required this.createdAt,
    this.lastLoginAt,
    this.eventIds = const [],
    UserPreferences? preferences,
  }) : preferences = preferences ?? UserPreferences();

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.dj,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      eventIds: List<String>.from(data['eventIds'] ?? []),
      preferences: data['preferences'] != null
          ? UserPreferences.fromMap(data['preferences'])
          : UserPreferences(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'eventIds': eventIds,
      'preferences': preferences.toMap(),
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    List<String>? eventIds,
    UserPreferences? preferences,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      eventIds: eventIds ?? this.eventIds,
      preferences: preferences ?? this.preferences,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get canManageEvents => role == UserRole.admin || role == UserRole.dj;
}

class UserPreferences {
  final bool darkMode;
  final bool notificationsEnabled;
  final String defaultNetworkMode;
  final int defaultSlideshowInterval;

  UserPreferences({
    this.darkMode = true,
    this.notificationsEnabled = true,
    this.defaultNetworkMode = 'hybrid',
    this.defaultSlideshowInterval = 5,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      darkMode: map['darkMode'] ?? true,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      defaultNetworkMode: map['defaultNetworkMode'] ?? 'hybrid',
      defaultSlideshowInterval: map['defaultSlideshowInterval'] ?? 5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'darkMode': darkMode,
      'notificationsEnabled': notificationsEnabled,
      'defaultNetworkMode': defaultNetworkMode,
      'defaultSlideshowInterval': defaultSlideshowInterval,
    };
  }
}

/// Represents a guest device (no login required)
class GuestDevice {
  final String deviceId;
  final String? deviceModel;
  final int uploadCount;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final bool isBlocked;

  GuestDevice({
    required this.deviceId,
    this.deviceModel,
    this.uploadCount = 0,
    required this.firstSeenAt,
    required this.lastSeenAt,
    this.isBlocked = false,
  });

  factory GuestDevice.fromMap(Map<String, dynamic> map) {
    return GuestDevice(
      deviceId: map['deviceId'] ?? '',
      deviceModel: map['deviceModel'],
      uploadCount: map['uploadCount'] ?? 0,
      firstSeenAt: (map['firstSeenAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeenAt: (map['lastSeenAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isBlocked: map['isBlocked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'deviceModel': deviceModel,
      'uploadCount': uploadCount,
      'firstSeenAt': Timestamp.fromDate(firstSeenAt),
      'lastSeenAt': Timestamp.fromDate(lastSeenAt),
      'isBlocked': isBlocked,
    };
  }
}
