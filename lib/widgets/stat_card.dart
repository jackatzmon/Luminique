import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/config/theme.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Colors.white70;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LuminiqueTheme.darkCard,
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: cardColor,
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: cardColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.raleway(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
