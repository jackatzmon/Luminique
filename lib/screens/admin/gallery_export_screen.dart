import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app/config/theme.dart';
import '../../models/photo.dart';
import '../../services/photo_service.dart';
import '../../providers/app_state_provider.dart';

class GalleryExportScreen extends StatefulWidget {
  const GalleryExportScreen({super.key});

  @override
  State<GalleryExportScreen> createState() => _GalleryExportScreenState();
}

class _GalleryExportScreenState extends State<GalleryExportScreen> {
  final PhotoService _photoService = PhotoService();

  bool _isExporting = false;
  int _totalPhotos = 0;
  int _exportedPhotos = 0;
  String? _downloadUrl;

  @override
  void initState() {
    super.initState();
    _loadPhotoCount();
  }

  Future<void> _loadPhotoCount() async {
    final eventId = context.read<AppStateProvider>().currentEvent?.id;
    if (eventId == null) return;

    final counts = await _photoService.getPhotoCountsByStatus(eventId);
    setState(() {
      _totalPhotos = counts[PhotoStatus.approved] ?? 0;
    });
  }

  Future<void> _startExport() async {
    final eventId = context.read<AppStateProvider>().currentEvent?.id;
    if (eventId == null) return;

    setState(() {
      _isExporting = true;
      _exportedPhotos = 0;
    });

    try {
      // Get all approved photo URLs
      final urls = await _photoService.getPhotoUrlsForExport(eventId);

      // In a real implementation, you would:
      // 1. Create a Cloud Function to zip the photos
      // 2. Or download them one by one and create a zip client-side
      // 3. Or use a service like Firebase Extensions

      // For now, simulate export progress
      for (var i = 0; i < urls.length; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
          _exportedPhotos = i + 1;
        });
      }

      // Generate mock download URL
      setState(() {
        _downloadUrl = 'https://storage.googleapis.com/luminique/exports/$eventId.zip';
        _isExporting = false;
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: LuminiqueTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = context.read<AppStateProvider>().currentEvent;

    return Scaffold(
      backgroundColor: LuminiqueTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: LuminiqueTheme.darkSurface,
        title: Text(
          'EXPORT GALLERY',
          style: GoogleFonts.montserrat(letterSpacing: 2),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: LuminiqueTheme.darkCard,
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 40,
                    color: LuminiqueTheme.accentColor,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event?.name ?? 'Unknown Event',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_totalPhotos approved photos',
                          style: GoogleFonts.raleway(
                            fontSize: 14,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Export options
            Text(
              'EXPORT OPTIONS',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                letterSpacing: 2,
                color: Colors.white54,
              ),
            ),

            const SizedBox(height: 16),

            _buildExportOption(
              icon: Icons.archive_outlined,
              title: 'Download ZIP',
              subtitle: 'Export all photos as a ZIP file',
              onTap: _totalPhotos > 0 && !_isExporting ? _startExport : null,
            ),

            _buildExportOption(
              icon: Icons.link,
              title: 'Share Gallery Link',
              subtitle: 'Generate a shareable gallery link for clients',
              onTap: () {
                // TODO: Implement share link
              },
            ),

            _buildExportOption(
              icon: Icons.cloud_upload_outlined,
              title: 'Export to Google Drive',
              subtitle: 'Upload directly to your Google Drive',
              onTap: null, // Coming soon
              badge: 'COMING SOON',
            ),

            const SizedBox(height: 32),

            // Export progress
            if (_isExporting) ...[
              Text(
                'EXPORTING...',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  letterSpacing: 2,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: LuminiqueTheme.darkCard,
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Processing photos',
                          style: GoogleFonts.raleway(color: Colors.white70),
                        ),
                        Text(
                          '$_exportedPhotos / $_totalPhotos',
                          style: GoogleFonts.montserrat(
                            color: LuminiqueTheme.accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _totalPhotos > 0
                          ? _exportedPhotos / _totalPhotos
                          : 0,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        LuminiqueTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Download ready
            if (_downloadUrl != null) ...[
              Text(
                'DOWNLOAD READY',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  letterSpacing: 2,
                  color: LuminiqueTheme.successColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: LuminiqueTheme.successColor.withOpacity(0.1),
                  border: Border.all(
                    color: LuminiqueTheme.successColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 48,
                      color: LuminiqueTheme.successColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your gallery is ready for download!',
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Trigger download
                        },
                        icon: const Icon(Icons.download),
                        label: Text(
                          'DOWNLOAD ZIP',
                          style: GoogleFonts.montserrat(letterSpacing: 2),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LuminiqueTheme.successColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Info note
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
                      'Only approved photos will be included in the export.',
                      style: GoogleFonts.raleway(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    String? badge,
  }) {
    final isDisabled = onTap == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: LuminiqueTheme.darkCard,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: isDisabled ? Colors.white24 : Colors.white70,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDisabled ? Colors.white38 : Colors.white,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badge,
                                style: GoogleFonts.montserrat(
                                  fontSize: 9,
                                  letterSpacing: 1,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.raleway(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isDisabled)
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
