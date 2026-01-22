import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/config/theme.dart';
import '../../app/config/routes.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../services/auth_service.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/slideshow_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/network_mode_toggle.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();

  Event? _activeEvent;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final appState = context.read<AppStateProvider>();
    final user = appState.currentUser;

    if (user == null) {
      // Try to get current user
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        appState.setCurrentUser(currentUser);
      } else {
        // Not logged in, redirect to login
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.adminLogin);
        }
        return;
      }
    }

    // Load active events
    final userId = appState.currentUser?.id ?? '';
    if (userId.isNotEmpty) {
      final events = await _eventService.getActiveEvents(userId);
      if (events.isNotEmpty) {
        setState(() {
          _activeEvent = events.first;
          appState.setCurrentEvent(_activeEvent);
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createEvent() async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.eventSetup);
    if (result != null && result is Event) {
      setState(() {
        _activeEvent = result;
        context.read<AppStateProvider>().setCurrentEvent(result);
      });
    }
  }

  Future<void> _startEvent() async {
    if (_activeEvent == null) return;

    await _eventService.startEvent(_activeEvent!.id);
    final updated = await _eventService.getEvent(_activeEvent!.id);
    if (updated != null) {
      setState(() {
        _activeEvent = updated;
        context.read<AppStateProvider>().setCurrentEvent(updated);
      });
    }
  }

  Future<void> _pauseEvent() async {
    if (_activeEvent == null) return;

    await _eventService.pauseEvent(_activeEvent!.id);
    final updated = await _eventService.getEvent(_activeEvent!.id);
    if (updated != null) {
      setState(() {
        _activeEvent = updated;
      });
    }
  }

  Future<void> _endEvent() async {
    if (_activeEvent == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LuminiqueTheme.darkCard,
        title: Text(
          'End Event?',
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        content: Text(
          'This will stop accepting new photos. You can still view the gallery.',
          style: GoogleFonts.raleway(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: LuminiqueTheme.errorColor,
            ),
            child: Text(
              'End Event',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _eventService.endEvent(_activeEvent!.id);
      final updated = await _eventService.getEvent(_activeEvent!.id);
      if (updated != null) {
        setState(() {
          _activeEvent = updated;
        });
      }
    }
  }

  void _openSlideshow() {
    if (_activeEvent == null) return;
    Navigator.of(context).pushNamed(
      '${AppRoutes.slideshow}?event=${_activeEvent!.id}',
    );
  }

  void _signOut() async {
    await _authService.signOut();
    context.read<AppStateProvider>().reset();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.adminLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: LuminiqueTheme.darkBackground,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              LuminiqueTheme.accentColor,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: LuminiqueTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: LuminiqueTheme.darkSurface,
        title: Text(
          'LUMINIQUE',
          style: GoogleFonts.montserrat(
            letterSpacing: 4,
            fontWeight: FontWeight.w300,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _activeEvent == null ? _buildNoEventView() : _buildDashboard(),
      floatingActionButton: _activeEvent == null
          ? FloatingActionButton.extended(
              onPressed: _createEvent,
              backgroundColor: LuminiqueTheme.accentColor,
              icon: const Icon(Icons.add),
              label: Text(
                'NEW EVENT',
                style: GoogleFonts.montserrat(letterSpacing: 2),
              ),
            )
          : null,
    );
  }

  Widget _buildNoEventView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_outlined,
            size: 80,
            color: Colors.white24,
          ).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 24),
          Text(
            'NO ACTIVE EVENT',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              letterSpacing: 4,
              color: Colors.white54,
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 500.ms),
          const SizedBox(height: 12),
          Text(
            'Create an event to start accepting photos',
            style: GoogleFonts.raleway(
              fontSize: 14,
              color: Colors.white38,
            ),
          ).animate(delay: 300.ms).fadeIn(duration: 500.ms),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final event = _activeEvent!;
    final uploadUrl = _eventService.getUploadUrl(event.id, 'https://yourdomain.com');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event header
          _buildEventHeader(event),

          const SizedBox(height: 32),

          // Quick actions
          _buildQuickActions(event),

          const SizedBox(height: 32),

          // Statistics
          _buildStatistics(event),

          const SizedBox(height: 32),

          // QR Code section
          _buildQRSection(event),

          const SizedBox(height: 32),

          // Network mode
          _buildNetworkSection(event),

          const SizedBox(height: 32),

          // Event controls
          _buildEventControls(event),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildEventHeader(Event event) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LuminiqueTheme.darkCard,
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: event.isActive
                            ? LuminiqueTheme.successColor
                            : Colors.white38,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      event.status.name.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        letterSpacing: 2,
                        color: event.isActive
                            ? LuminiqueTheme.successColor
                            : Colors.white54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  event.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                if (event.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    event.description!,
                    style: GoogleFonts.raleway(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRoutes.eventSetup,
                arguments: {'eventId': event.id},
              );
            },
            icon: const Icon(Icons.edit_outlined),
            color: Colors.white54,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildQuickActions(Event event) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.slideshow,
            label: 'SLIDESHOW',
            onPressed: _openSlideshow,
            color: LuminiqueTheme.accentColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionButton(
            icon: Icons.photo_library_outlined,
            label: 'MODERATION',
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.photoModeration,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionButton(
            icon: Icons.download_outlined,
            label: 'EXPORT',
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.galleryExport,
            ),
          ),
        ),
      ],
    ).animate(delay: 200.ms).fadeIn(duration: 500.ms);
  }

  Widget _buildStatistics(Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STATISTICS',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            letterSpacing: 2,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.upload_outlined,
                value: '${event.stats.totalUploads}',
                label: 'Total Uploads',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.check_circle_outline,
                value: '${event.stats.approvedPhotos}',
                label: 'Approved',
                color: LuminiqueTheme.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.flag_outlined,
                value: '${event.stats.flaggedPhotos}',
                label: 'Flagged',
                color: LuminiqueTheme.warningColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.devices_outlined,
                value: '${event.stats.uniqueDevices}',
                label: 'Devices',
              ),
            ),
          ],
        ),
      ],
    ).animate(delay: 400.ms).fadeIn(duration: 500.ms);
  }

  Widget _buildQRSection(Event event) {
    final uploadUrl = 'https://yourdomain.com/e/${event.id}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GUEST QR CODE',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            letterSpacing: 2,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: LuminiqueTheme.darkCard,
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: QrImageView(
                  data: uploadUrl,
                  version: QrVersions.auto,
                  size: 150,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 24),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan to upload photos',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Guests can scan this QR code with their phone camera to access the upload page.',
                      style: GoogleFonts.raleway(
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Print or share QR code
                      },
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: Text(
                        'PRINT QR',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate(delay: 600.ms).fadeIn(duration: 500.ms);
  }

  Widget _buildNetworkSection(Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NETWORK MODE',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            letterSpacing: 2,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 16),
        NetworkModeToggle(event: event),
      ],
    ).animate(delay: 800.ms).fadeIn(duration: 500.ms);
  }

  Widget _buildEventControls(Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EVENT CONTROLS',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            letterSpacing: 2,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (event.status == EventStatus.draft)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startEvent,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    'START EVENT',
                    style: GoogleFonts.montserrat(letterSpacing: 2),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LuminiqueTheme.successColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            if (event.status == EventStatus.active) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pauseEvent,
                  icon: const Icon(Icons.pause),
                  label: Text(
                    'PAUSE',
                    style: GoogleFonts.montserrat(letterSpacing: 2),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LuminiqueTheme.warningColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _endEvent,
                  icon: const Icon(Icons.stop),
                  label: Text(
                    'END EVENT',
                    style: GoogleFonts.montserrat(letterSpacing: 2),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LuminiqueTheme.errorColor,
                    side: BorderSide(color: LuminiqueTheme.errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
            if (event.status == EventStatus.paused)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startEvent,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    'RESUME',
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
      ],
    ).animate(delay: 1000.ms).fadeIn(duration: 500.ms);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LuminiqueTheme.darkCard,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(
              color: color?.withOpacity(0.3) ?? Colors.white12,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color ?? Colors.white70,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  letterSpacing: 1,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
