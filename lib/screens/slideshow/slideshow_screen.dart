import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../app/config/theme.dart';
import '../../models/event.dart';
import '../../models/photo.dart';
import '../../services/event_service.dart';
import '../../providers/slideshow_provider.dart';
import '../../providers/app_state_provider.dart';

class SlideshowScreen extends StatefulWidget {
  final String? eventId;

  const SlideshowScreen({super.key, this.eventId});

  @override
  State<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<SlideshowScreen> {
  final EventService _eventService = EventService();

  Event? _event;
  bool _isLoading = true;
  String? _error;
  bool _showControls = true;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _loadEvent();
    _hideControlsAfterDelay();
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
      final event = await _eventService.getEvent(widget.eventId!);

      if (event == null) {
        setState(() {
          _error = 'Event not found';
          _isLoading = false;
        });
        return;
      }

      // Start listening to photos
      final slideshowProvider = context.read<SlideshowProvider>();
      slideshowProvider.startListening(widget.eventId!);
      slideshowProvider.setInterval(event.settings.slideshowIntervalSeconds);
      slideshowProvider.play();

      setState(() {
        _event = event;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load event: $e';
        _isLoading = false;
      });
    }
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  void _toggleFullScreen() {
    setState(() => _isFullScreen = !_isFullScreen);

    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
                'Loading slideshow...',
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
                style: GoogleFonts.raleway(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Photo display
            Consumer<SlideshowProvider>(
              builder: (context, provider, child) {
                if (!provider.hasPhotos) {
                  return _buildWaitingScreen();
                }

                return _buildPhotoDisplay(provider);
              },
            ),

            // Controls overlay
            if (_showControls) _buildControlsOverlay(),

            // Brand watermark
            Positioned(
              bottom: 20,
              right: 20,
              child: Opacity(
                opacity: 0.3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'LUMINIQUE',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4,
                        color: Colors.white,
                      ),
                    ),
                    if (_event != null)
                      Text(
                        _event!.name.toUpperCase(),
                        style: GoogleFonts.raleway(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: Colors.white54,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.white24,
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2000.ms, color: Colors.white10),
          const SizedBox(height: 32),
          Text(
            'WAITING FOR PHOTOS',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              letterSpacing: 8,
              color: Colors.white54,
            ),
          ).animate().fadeIn(duration: 800.ms),
          const SizedBox(height: 16),
          Text(
            'Scan the QR code to upload your photos',
            style: GoogleFonts.raleway(
              fontSize: 14,
              color: Colors.white38,
            ),
          ).animate(delay: 300.ms).fadeIn(duration: 500.ms),
        ],
      ),
    );
  }

  Widget _buildPhotoDisplay(SlideshowProvider provider) {
    final photo = provider.currentPhoto;
    if (photo == null) return const SizedBox();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: Container(
        key: ValueKey(photo.id),
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo
            if (photo.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: photo.imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      LuminiqueTheme.accentColor,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.white24,
                  ),
                ),
              )
            else if (photo.localPath != null)
              Image.network(
                photo.localPath!,
                fit: BoxFit.contain,
              ),

            // Caption overlay
            if (photo.caption != null &&
                photo.caption!.isNotEmpty &&
                _event?.settings.showCaptionsOnSlideshow == true)
              Positioned(
                bottom: 80,
                left: 40,
                right: 40,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    photo.caption!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.raleway(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Votes overlay
            if (_event?.settings.showVotesOnSlideshow == true && photo.votes > 0)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: LuminiqueTheme.accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${photo.votes}',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Consumer<SlideshowProvider>(
      builder: (context, provider, child) {
        return AnimatedOpacity(
          opacity: _showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black54,
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black54,
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
            child: Column(
              children: [
                // Top bar
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Back button
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                          color: Colors.white,
                        ),

                        const Spacer(),

                        // Photo counter
                        if (provider.hasPhotos)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${provider.currentIndex + 1} / ${provider.photoCount}',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),

                        const Spacer(),

                        // Fullscreen button
                        IconButton(
                          onPressed: _toggleFullScreen,
                          icon: Icon(
                            _isFullScreen
                                ? Icons.fullscreen_exit
                                : Icons.fullscreen,
                          ),
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Previous
                      IconButton(
                        onPressed: provider.previousPhoto,
                        icon: const Icon(Icons.skip_previous),
                        iconSize: 40,
                        color: Colors.white,
                      ),

                      const SizedBox(width: 24),

                      // Play/Pause
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: LuminiqueTheme.accentColor,
                        ),
                        child: IconButton(
                          onPressed: provider.togglePlayPause,
                          icon: Icon(
                            provider.isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                          iconSize: 40,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 24),

                      // Next
                      IconButton(
                        onPressed: provider.nextPhoto,
                        icon: const Icon(Icons.skip_next),
                        iconSize: 40,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
