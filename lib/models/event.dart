import 'package:cloud_firestore/cloud_firestore.dart';

enum EventStatus {
  draft,      // Event created but not active
  active,     // Event is live, accepting uploads
  paused,     // Temporarily paused
  ended,      // Event has ended
  archived,   // Event is archived
}

enum NetworkMode {
  internet,   // Using cloud/internet
  local,      // Using local Wi-Fi network
  hybrid,     // Auto-switch based on connectivity
}

class Event {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final EventStatus status;
  final DateTime createdAt;
  final DateTime? startTime;
  final DateTime? endTime;
  final EventSettings settings;
  final EventBranding branding;
  final NetworkSettings networkSettings;
  final EventStats stats;

  Event({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    this.status = EventStatus.draft,
    required this.createdAt,
    this.startTime,
    this.endTime,
    EventSettings? settings,
    EventBranding? branding,
    NetworkSettings? networkSettings,
    EventStats? stats,
  })  : settings = settings ?? EventSettings(),
        branding = branding ?? EventBranding(),
        networkSettings = networkSettings ?? NetworkSettings(),
        stats = stats ?? EventStats();

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      ownerId: data['ownerId'] ?? '',
      status: EventStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => EventStatus.draft,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: (data['startTime'] as Timestamp?)?.toDate(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      settings: data['settings'] != null
          ? EventSettings.fromMap(data['settings'])
          : EventSettings(),
      branding: data['branding'] != null
          ? EventBranding.fromMap(data['branding'])
          : EventBranding(),
      networkSettings: data['networkSettings'] != null
          ? NetworkSettings.fromMap(data['networkSettings'])
          : NetworkSettings(),
      stats: data['stats'] != null
          ? EventStats.fromMap(data['stats'])
          : EventStats(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'settings': settings.toMap(),
      'branding': branding.toMap(),
      'networkSettings': networkSettings.toMap(),
      'stats': stats.toMap(),
    };
  }

  Event copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    EventStatus? status,
    DateTime? createdAt,
    DateTime? startTime,
    DateTime? endTime,
    EventSettings? settings,
    EventBranding? branding,
    NetworkSettings? networkSettings,
    EventStats? stats,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      settings: settings ?? this.settings,
      branding: branding ?? this.branding,
      networkSettings: networkSettings ?? this.networkSettings,
      stats: stats ?? this.stats,
    );
  }

  /// Generate upload URL for guests
  String getUploadUrl(String baseUrl) {
    return '$baseUrl/e/$id';
  }

  /// Generate slideshow URL
  String getSlideshowUrl(String baseUrl) {
    return '$baseUrl/slideshow?event=$id';
  }

  bool get isActive => status == EventStatus.active;
  bool get canUpload => status == EventStatus.active && settings.uploadsEnabled;
}

class EventSettings {
  final bool uploadsEnabled;
  final bool moderationEnabled;
  final bool autoApprove;          // Skip moderation queue
  final bool votingEnabled;
  final bool captionsEnabled;
  final int maxPhotosPerDevice;
  final int slideshowIntervalSeconds;
  final bool showCaptionsOnSlideshow;
  final bool showVotesOnSlideshow;
  final List<String> blockedDeviceIds;

  EventSettings({
    this.uploadsEnabled = true,
    this.moderationEnabled = true,
    this.autoApprove = false,
    this.votingEnabled = false,
    this.captionsEnabled = true,
    this.maxPhotosPerDevice = 50,
    this.slideshowIntervalSeconds = 5,
    this.showCaptionsOnSlideshow = true,
    this.showVotesOnSlideshow = false,
    this.blockedDeviceIds = const [],
  });

  factory EventSettings.fromMap(Map<String, dynamic> map) {
    return EventSettings(
      uploadsEnabled: map['uploadsEnabled'] ?? true,
      moderationEnabled: map['moderationEnabled'] ?? true,
      autoApprove: map['autoApprove'] ?? false,
      votingEnabled: map['votingEnabled'] ?? false,
      captionsEnabled: map['captionsEnabled'] ?? true,
      maxPhotosPerDevice: map['maxPhotosPerDevice'] ?? 50,
      slideshowIntervalSeconds: map['slideshowIntervalSeconds'] ?? 5,
      showCaptionsOnSlideshow: map['showCaptionsOnSlideshow'] ?? true,
      showVotesOnSlideshow: map['showVotesOnSlideshow'] ?? false,
      blockedDeviceIds: List<String>.from(map['blockedDeviceIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uploadsEnabled': uploadsEnabled,
      'moderationEnabled': moderationEnabled,
      'autoApprove': autoApprove,
      'votingEnabled': votingEnabled,
      'captionsEnabled': captionsEnabled,
      'maxPhotosPerDevice': maxPhotosPerDevice,
      'slideshowIntervalSeconds': slideshowIntervalSeconds,
      'showCaptionsOnSlideshow': showCaptionsOnSlideshow,
      'showVotesOnSlideshow': showVotesOnSlideshow,
      'blockedDeviceIds': blockedDeviceIds,
    };
  }

  EventSettings copyWith({
    bool? uploadsEnabled,
    bool? moderationEnabled,
    bool? autoApprove,
    bool? votingEnabled,
    bool? captionsEnabled,
    int? maxPhotosPerDevice,
    int? slideshowIntervalSeconds,
    bool? showCaptionsOnSlideshow,
    bool? showVotesOnSlideshow,
    List<String>? blockedDeviceIds,
  }) {
    return EventSettings(
      uploadsEnabled: uploadsEnabled ?? this.uploadsEnabled,
      moderationEnabled: moderationEnabled ?? this.moderationEnabled,
      autoApprove: autoApprove ?? this.autoApprove,
      votingEnabled: votingEnabled ?? this.votingEnabled,
      captionsEnabled: captionsEnabled ?? this.captionsEnabled,
      maxPhotosPerDevice: maxPhotosPerDevice ?? this.maxPhotosPerDevice,
      slideshowIntervalSeconds: slideshowIntervalSeconds ?? this.slideshowIntervalSeconds,
      showCaptionsOnSlideshow: showCaptionsOnSlideshow ?? this.showCaptionsOnSlideshow,
      showVotesOnSlideshow: showVotesOnSlideshow ?? this.showVotesOnSlideshow,
      blockedDeviceIds: blockedDeviceIds ?? this.blockedDeviceIds,
    );
  }
}

class EventBranding {
  final String? logoUrl;
  final String? backgroundImageUrl;
  final String primaryColor;
  final String secondaryColor;
  final String? overlayText;
  final String? watermarkUrl;
  final double watermarkOpacity;
  final String fontFamily;

  EventBranding({
    this.logoUrl,
    this.backgroundImageUrl,
    this.primaryColor = '#6C5CE7',
    this.secondaryColor = '#A29BFE',
    this.overlayText,
    this.watermarkUrl,
    this.watermarkOpacity = 0.3,
    this.fontFamily = 'Poppins',
  });

  factory EventBranding.fromMap(Map<String, dynamic> map) {
    return EventBranding(
      logoUrl: map['logoUrl'],
      backgroundImageUrl: map['backgroundImageUrl'],
      primaryColor: map['primaryColor'] ?? '#6C5CE7',
      secondaryColor: map['secondaryColor'] ?? '#A29BFE',
      overlayText: map['overlayText'],
      watermarkUrl: map['watermarkUrl'],
      watermarkOpacity: (map['watermarkOpacity'] ?? 0.3).toDouble(),
      fontFamily: map['fontFamily'] ?? 'Poppins',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'logoUrl': logoUrl,
      'backgroundImageUrl': backgroundImageUrl,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'overlayText': overlayText,
      'watermarkUrl': watermarkUrl,
      'watermarkOpacity': watermarkOpacity,
      'fontFamily': fontFamily,
    };
  }
}

class NetworkSettings {
  final NetworkMode mode;
  final String localWifiName;
  final String localWifiPassword;
  final String? localServerIp;
  final int localServerPort;

  NetworkSettings({
    this.mode = NetworkMode.hybrid,
    this.localWifiName = 'DJ-PARTY-NET',
    this.localWifiPassword = '',
    this.localServerIp,
    this.localServerPort = 8080,
  });

  factory NetworkSettings.fromMap(Map<String, dynamic> map) {
    return NetworkSettings(
      mode: NetworkMode.values.firstWhere(
        (e) => e.name == map['mode'],
        orElse: () => NetworkMode.hybrid,
      ),
      localWifiName: map['localWifiName'] ?? 'DJ-PARTY-NET',
      localWifiPassword: map['localWifiPassword'] ?? '',
      localServerIp: map['localServerIp'],
      localServerPort: map['localServerPort'] ?? 8080,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mode': mode.name,
      'localWifiName': localWifiName,
      'localWifiPassword': localWifiPassword,
      'localServerIp': localServerIp,
      'localServerPort': localServerPort,
    };
  }
}

class EventStats {
  final int totalUploads;
  final int approvedPhotos;
  final int rejectedPhotos;
  final int flaggedPhotos;
  final int totalVotes;
  final int uniqueDevices;

  EventStats({
    this.totalUploads = 0,
    this.approvedPhotos = 0,
    this.rejectedPhotos = 0,
    this.flaggedPhotos = 0,
    this.totalVotes = 0,
    this.uniqueDevices = 0,
  });

  factory EventStats.fromMap(Map<String, dynamic> map) {
    return EventStats(
      totalUploads: map['totalUploads'] ?? 0,
      approvedPhotos: map['approvedPhotos'] ?? 0,
      rejectedPhotos: map['rejectedPhotos'] ?? 0,
      flaggedPhotos: map['flaggedPhotos'] ?? 0,
      totalVotes: map['totalVotes'] ?? 0,
      uniqueDevices: map['uniqueDevices'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalUploads': totalUploads,
      'approvedPhotos': approvedPhotos,
      'rejectedPhotos': rejectedPhotos,
      'flaggedPhotos': flaggedPhotos,
      'totalVotes': totalVotes,
      'uniqueDevices': uniqueDevices,
    };
  }
}
