import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/config/theme.dart';
import '../../app/config/routes.dart';

class WifiConnectScreen extends StatelessWidget {
  final String wifiName;
  final String wifiPassword;
  final String? eventId;

  const WifiConnectScreen({
    super.key,
    required this.wifiName,
    required this.wifiPassword,
    this.eventId,
  });

  void _copyPassword(BuildContext context) {
    if (wifiPassword.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: wifiPassword));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password copied to clipboard',
            style: GoogleFonts.raleway(),
          ),
          backgroundColor: LuminiqueTheme.successColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _continueToUpload(BuildContext context) {
    if (eventId != null) {
      Navigator.of(context).pushReplacementNamed(
        '${AppRoutes.guestUpload}?event=$eventId',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminiqueTheme.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(),

              // Wi-Fi icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LuminiqueTheme.accentColor.withOpacity(0.1),
                  border: Border.all(
                    color: LuminiqueTheme.accentColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.wifi,
                  size: 48,
                  color: LuminiqueTheme.accentColor,
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

              const SizedBox(height: 40),

              // Title
              Text(
                'CONNECT TO WI-FI',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4,
                  color: Colors.white,
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 500.ms),

              const SizedBox(height: 16),

              Text(
                'Please connect to the event Wi-Fi network to upload photos',
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ).animate(delay: 300.ms).fadeIn(duration: 500.ms),

              const SizedBox(height: 48),

              // Network info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: LuminiqueTheme.darkCard,
                  border: Border.all(
                    color: Colors.white12,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Network name
                    Row(
                      children: [
                        Icon(
                          Icons.wifi,
                          color: Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Network Name',
                          style: GoogleFonts.raleway(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        wifiName,
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    if (wifiPassword.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 24),

                      // Password
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: Colors.white54,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Password',
                            style: GoogleFonts.raleway(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              wifiPassword,
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _copyPassword(context),
                            icon: Icon(
                              Icons.copy,
                              color: LuminiqueTheme.accentColor,
                            ),
                            tooltip: 'Copy password',
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ).animate(delay: 400.ms).fadeIn(duration: 500.ms).slideY(
                    begin: 0.1,
                    end: 0,
                    duration: 500.ms,
                  ),

              const SizedBox(height: 32),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LuminiqueTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: LuminiqueTheme.accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Go to Settings > Wi-Fi and select "$wifiName"',
                        style: GoogleFonts.raleway(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 600.ms).fadeIn(duration: 500.ms),

              const Spacer(),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _continueToUpload(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LuminiqueTheme.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: Text(
                    "I'M CONNECTED",
                    style: GoogleFonts.montserrat(
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ).animate(delay: 800.ms).fadeIn(duration: 500.ms),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
