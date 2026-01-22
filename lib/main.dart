import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'app/config/firebase_options.dart';
import 'services/auth_service.dart';
import 'services/photo_service.dart';
import 'services/event_service.dart';
import 'services/moderation_service.dart';
import 'services/network_service.dart';
import 'services/local_server_service.dart';
import 'providers/app_state_provider.dart';
import 'providers/slideshow_provider.dart';
import 'providers/upload_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize services
  final networkService = NetworkService();
  await networkService.initialize();

  final localServerService = LocalServerService();
  final moderationService = ModerationService();
  final photoService = PhotoService();
  final eventService = EventService();
  final authService = AuthService();

  runApp(
    MultiProvider(
      providers: [
        // Services
        Provider<NetworkService>.value(value: networkService),
        Provider<LocalServerService>.value(value: localServerService),
        Provider<ModerationService>.value(value: moderationService),
        Provider<PhotoService>.value(value: photoService),
        Provider<EventService>.value(value: eventService),
        Provider<AuthService>.value(value: authService),

        // State Providers
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(networkService: networkService),
        ),
        ChangeNotifierProvider(
          create: (_) => SlideshowProvider(photoService: photoService),
        ),
        ChangeNotifierProvider(
          create: (_) => UploadProvider(
            photoService: photoService,
            moderationService: moderationService,
          ),
        ),
      ],
      child: const LuminiqueApp(),
    ),
  );
}
