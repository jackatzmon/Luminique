import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../app/config/theme.dart';
import '../../app/config/routes.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../services/auth_service.dart';
import '../../providers/upload_provider.dart';
import '../../widgets/upload_progress_card.dart';

class GuestUploadScreen extends StatefulWidget {
  final String? eventId;

  const GuestUploadScreen({super.key, this.eventId});

  @override
  State<GuestUploadScreen> createState() => _GuestUploadScreenState();
}

class _GuestUploadScreenState extends State<GuestUploadScreen> {
  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();
  final TextEditingController _captionController = TextEditingController();

  Event? _event;
  String? _deviceId;
  bool _isLoading = true;
  String? _error;
  bool _captionsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    if (widget.eventId == null) {
      setState(() {
        _error = 'No event specified';
        _isLoading = false;
      });
      return;
    }

    try {
      // Get device ID
      _deviceId = await _authService.getDeviceId();

      // Load event
      final event = await _eventService.getEvent(widget.eventId!);

      if (event == null) {
        setState(() {
          _error = 'Event not found';
          _isLoading = false;
        });
        return;
      }

      if (!event.isActive) {
        setState(() {
          _error = 'This event is not currently accepting photos';
          _isLoading = false;
        });
        return;
      }

      // Check if device is blocked
      if (event.settings.blockedDeviceIds.contains(_deviceId)) {
        setState(() {
          _error = 'Your device has been blocked from this event';
          _isLoading = false;
        });
        return;
      }

      // Record device visit
      await _authService.recordGuestDevice(widget.eventId!);

      // Configure upload provider
      final uploadProvider = context.read<UploadProvider>();
      uploadProvider.configure(
        eventId: widget.eventId!,
        deviceId: _deviceId!,
      );

      setState(() {
        _event = event;
        _captionsEnabled = event.settings.captionsEnabled;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load event: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickPhotos() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final uploadProvider = context.read<UploadProvider>();

      // Add files to upload queue
      for (final file in result.files) {
        if (file.bytes != null) {
          uploadProvider.addFile(
            file.name,
            file.bytes!,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting photos: $e'),
          backgroundColor: LuminiqueTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _startUpload() async {
    final uploadProvider = context.read<UploadProvider>();

    // Set caption if enabled
    if (_captionsEnabled && _captionController.text.isNotEmpty) {
      uploadProvider.setCaption(_captionController.text);
    }

    await uploadProvider.startUpload();

    // Navigate to success screen if any uploads succeeded
    if (uploadProvider.hasSuccessfulUploads && mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.uploadSuccess);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: LuminiqueTheme.darkBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  LuminiqueTheme.accentColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading event...',
                style: GoogleFonts.raleway(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: LuminiqueTheme.darkBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: LuminiqueTheme.errorColor,
                ),
                const SizedBox(height: 24),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: LuminiqueTheme.darkBackground,
      body: SafeArea(
        child: Consumer<UploadProvider>(
          builder: (context, uploadProvider, child) {
            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Brand
                        Text(
                          'LUMINIQUE',
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 8,
                            color: Colors.white,
                          ),
                        ).animate().fadeIn(duration: 500.ms),

                        const SizedBox(height: 8),

                        // Event name
                        if (_event != null)
                          Text(
                            _event!.name.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 4,
                              color: LuminiqueTheme.accentColor,
                            ),
                          ).animate(delay: 200.ms).fadeIn(duration: 500.ms),

                        const SizedBox(height: 32),

                        // Upload area
                        _buildUploadArea(uploadProvider),

                        const SizedBox(height: 24),

                        // Caption input
                        if (_captionsEnabled && uploadProvider.uploadQueue.isNotEmpty)
                          _buildCaptionInput(),
                      ],
                    ),
                  ),
                ),

                // Upload queue
                if (uploadProvider.uploadQueue.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = uploadProvider.uploadQueue[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: UploadProgressCard(
                              item: item,
                              onRemove: () => uploadProvider.removeItem(item.id),
                              onRetry: () => uploadProvider.retryItem(item.id),
                            ),
                          );
                        },
                        childCount: uploadProvider.uploadQueue.length,
                      ),
                    ),
                  ),

                // Upload button
                if (uploadProvider.uploadQueue.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildUploadButton(uploadProvider),
                    ),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUploadArea(UploadProvider uploadProvider) {
    return GestureDetector(
      onTap: uploadProvider.isUploading ? null : _pickPhotos,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        decoration: BoxDecoration(
          color: LuminiqueTheme.darkCard,
          border: Border.all(
            color: LuminiqueTheme.accentColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 64,
              color: LuminiqueTheme.accentColor,
            ),
            const SizedBox(height: 16),
            Text(
              'TAP TO SELECT PHOTOS',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can select multiple photos',
              style: GoogleFonts.raleway(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ).animate(delay: 400.ms).fadeIn(duration: 500.ms).scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1, 1),
            duration: 500.ms,
          ),
    );
  }

  Widget _buildCaptionInput() {
    return TextField(
      controller: _captionController,
      style: GoogleFonts.raleway(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Add a caption (optional)',
        hintStyle: GoogleFonts.raleway(color: Colors.white38),
        filled: true,
        fillColor: LuminiqueTheme.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: LuminiqueTheme.accentColor,
            width: 2,
          ),
        ),
        prefixIcon: Icon(
          Icons.comment_outlined,
          color: Colors.white54,
        ),
      ),
      maxLength: 100,
    ).animate(delay: 600.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildUploadButton(UploadProvider uploadProvider) {
    if (uploadProvider.allComplete) {
      return Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 48,
            color: LuminiqueTheme.successColor,
          ),
          const SizedBox(height: 12),
          Text(
            uploadProvider.statusMessage,
            style: GoogleFonts.raleway(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    uploadProvider.clearQueue();
                  },
                  child: Text(
                    'ADD MORE',
                    style: GoogleFonts.montserrat(letterSpacing: 2),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(
                      AppRoutes.uploadSuccess,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LuminiqueTheme.accentColor,
                  ),
                  child: Text(
                    'DONE',
                    style: GoogleFonts.montserrat(letterSpacing: 2),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: uploadProvider.isUploading || uploadProvider.pendingCount == 0
            ? null
            : _startUpload,
        style: ElevatedButton.styleFrom(
          backgroundColor: LuminiqueTheme.accentColor,
          disabledBackgroundColor: LuminiqueTheme.accentColor.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: uploadProvider.isUploading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    uploadProvider.statusMessage.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
                'UPLOAD ${uploadProvider.pendingCount} PHOTO${uploadProvider.pendingCount != 1 ? 'S' : ''}',
                style: GoogleFonts.montserrat(
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
