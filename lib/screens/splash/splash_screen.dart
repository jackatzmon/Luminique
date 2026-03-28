import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/config/theme.dart';
import '../../app/config/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    try {
      // Check URL for event parameter or default to admin login
      final uri = Uri.base;
      final eventId = uri.queryParameters['event'];

      if (eventId != null && eventId.isNotEmpty) {
        // Guest accessing upload page
        Navigator.of(context).pushReplacementNamed(
          '${AppRoutes.guestUpload}?event=$eventId',
        );
      } else if (uri.path.startsWith('/e/')) {
        // Short event URL
        Navigator.of(context).pushReplacementNamed(uri.path);
      } else if (uri.path == AppRoutes.slideshow) {
        final slideshowRoute = eventId != null && eventId.isNotEmpty
            ? '${AppRoutes.slideshow}?event=$eventId'
            : AppRoutes.slideshow;
        Navigator.of(context).pushReplacementNamed(slideshowRoute);
      } else {
        // Default to admin login
        Navigator.of(context).pushReplacementNamed(AppRoutes.adminLogin);
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.adminLogin);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminiqueTheme.darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / Brand Name
            Text(
              'LUMINIQUE',
              style: GoogleFonts.montserrat(
                fontSize: 48,
                fontWeight: FontWeight.w300,
                letterSpacing: 16,
                color: Colors.white,
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms)
                .slideY(begin: -0.2, end: 0, duration: 800.ms),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              'EVENTS GROUP',
              style: GoogleFonts.raleway(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                letterSpacing: 8,
                color: Colors.white54,
              ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 600.ms),

            const SizedBox(height: 60),

            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  LuminiqueTheme.accentColor.withOpacity(0.7),
                ),
              ),
            )
                .animate(delay: 600.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            // Tagline
            Text(
              'Photo Stream',
              style: GoogleFonts.raleway(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: 4,
                color: Colors.white38,
              ),
            )
                .animate(delay: 800.ms)
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
