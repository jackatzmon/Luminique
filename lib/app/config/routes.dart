import 'package:flutter/material.dart';

import '../../screens/splash/splash_screen.dart';
import '../../screens/guest/guest_upload_screen.dart';
import '../../screens/guest/upload_success_screen.dart';
import '../../screens/guest/wifi_connect_screen.dart';
import '../../screens/slideshow/slideshow_screen.dart';
import '../../screens/admin/admin_login_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/event_setup_screen.dart';
import '../../screens/admin/photo_moderation_screen.dart';
import '../../screens/admin/settings_screen.dart';
import '../../screens/admin/gallery_export_screen.dart';

class AppRoutes {
  // Splash & Entry
  static const String splash = '/';

  // Guest Routes
  static const String guestUpload = '/upload';
  static const String uploadSuccess = '/upload/success';
  static const String wifiConnect = '/wifi-connect';

  // Slideshow Routes
  static const String slideshow = '/slideshow';

  // Admin Routes
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String eventSetup = '/admin/event/setup';
  static const String photoModeration = '/admin/moderation';
  static const String settings = '/admin/settings';
  static const String galleryExport = '/admin/gallery/export';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Parse the route and extract any event ID from query parameters
    final uri = Uri.parse(settings.name ?? '/');
    final eventId = uri.queryParameters['event'];

    switch (uri.path) {
      case splash:
        return _fadeRoute(const SplashScreen());

      // Guest Routes
      case guestUpload:
        return _fadeRoute(GuestUploadScreen(eventId: eventId));

      case uploadSuccess:
        return _fadeRoute(const UploadSuccessScreen());

      case wifiConnect:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(
          WifiConnectScreen(
            wifiName: args?['wifiName'] ?? 'DJ-PARTY-NET',
            wifiPassword: args?['wifiPassword'] ?? '',
            eventId: args?['eventId'],
          ),
        );

      // Slideshow Routes
      case slideshow:
        return _fadeRoute(SlideshowScreen(eventId: eventId));

      // Admin Routes
      case adminLogin:
        return _fadeRoute(const AdminLoginScreen());

      case adminDashboard:
        return _slideRoute(const AdminDashboardScreen());

      case eventSetup:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideRoute(
          EventSetupScreen(eventId: args?['eventId']),
        );

      case photoModeration:
        return _slideRoute(const PhotoModerationScreen());

      case AppRoutes.settings:
        return _slideRoute(const SettingsScreen());

      case galleryExport:
        return _slideRoute(const GalleryExportScreen());

      default:
        // Handle event-specific upload URLs like /e/abc123
        if (uri.path.startsWith('/e/')) {
          final eventId = uri.path.substring(3);
          return _fadeRoute(GuestUploadScreen(eventId: eventId));
        }

        return _fadeRoute(
          Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Page not found',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    uri.path,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  static PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRouteBuilder _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
