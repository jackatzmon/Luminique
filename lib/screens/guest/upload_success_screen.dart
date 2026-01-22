import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/config/theme.dart';

class UploadSuccessScreen extends StatelessWidget {
  const UploadSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminiqueTheme.darkBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: LuminiqueTheme.successColor.withOpacity(0.1),
                    border: Border.all(
                      color: LuminiqueTheme.successColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 60,
                    color: LuminiqueTheme.successColor,
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    )
                    .then()
                    .shimmer(duration: 1000.ms, color: Colors.white24),

                const SizedBox(height: 48),

                // Thank you text
                Text(
                  'THANK YOU!',
                  style: GoogleFonts.montserrat(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 8,
                    color: Colors.white,
                  ),
                ).animate(delay: 300.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 16),

                // Description
                Text(
                  'Your photos have been uploaded successfully',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ).animate(delay: 500.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 8),

                Text(
                  'They will appear on the slideshow shortly',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ).animate(delay: 600.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 60),

                // Action button
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    'UPLOAD MORE PHOTOS',
                    style: GoogleFonts.montserrat(letterSpacing: 2),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ).animate(delay: 800.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 80),

                // Brand footer
                Column(
                  children: [
                    Text(
                      'LUMINIQUE',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 6,
                        color: Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'EVENTS GROUP',
                      style: GoogleFonts.raleway(
                        fontSize: 10,
                        letterSpacing: 4,
                        color: Colors.white24,
                      ),
                    ),
                  ],
                ).animate(delay: 1000.ms).fadeIn(duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
