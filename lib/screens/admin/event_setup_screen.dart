import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app/config/theme.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../providers/app_state_provider.dart';

class EventSetupScreen extends StatefulWidget {
  final String? eventId;

  const EventSetupScreen({super.key, this.eventId});

  @override
  State<EventSetupScreen> createState() => _EventSetupScreenState();
}

class _EventSetupScreenState extends State<EventSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _wifiNameController = TextEditingController(text: 'DJ-PARTY-NET');
  final _wifiPasswordController = TextEditingController();

  final EventService _eventService = EventService();

  Event? _existingEvent;
  bool _isLoading = false;
  bool _isSaving = false;

  // Settings
  bool _moderationEnabled = true;
  bool _votingEnabled = false;
  bool _captionsEnabled = true;
  int _slideshowInterval = 5;
  int _maxPhotosPerDevice = 50;

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      _loadEvent();
    }
  }

  Future<void> _loadEvent() async {
    setState(() => _isLoading = true);

    final event = await _eventService.getEvent(widget.eventId!);
    if (event != null) {
      setState(() {
        _existingEvent = event;
        _nameController.text = event.name;
        _descriptionController.text = event.description ?? '';
        _wifiNameController.text = event.networkSettings.localWifiName;
        _wifiPasswordController.text = event.networkSettings.localWifiPassword;
        _moderationEnabled = event.settings.moderationEnabled;
        _votingEnabled = event.settings.votingEnabled;
        _captionsEnabled = event.settings.captionsEnabled;
        _slideshowInterval = event.settings.slideshowIntervalSeconds;
        _maxPhotosPerDevice = event.settings.maxPhotosPerDevice;
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final appState = context.read<AppStateProvider>();
      final userId = appState.currentUser?.id ?? '';

      final settings = EventSettings(
        moderationEnabled: _moderationEnabled,
        votingEnabled: _votingEnabled,
        captionsEnabled: _captionsEnabled,
        slideshowIntervalSeconds: _slideshowInterval,
        maxPhotosPerDevice: _maxPhotosPerDevice,
      );

      final networkSettings = NetworkSettings(
        localWifiName: _wifiNameController.text,
        localWifiPassword: _wifiPasswordController.text,
      );

      if (_existingEvent != null) {
        // Update existing event
        final updated = _existingEvent!.copyWith(
          name: _nameController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          settings: settings,
          networkSettings: networkSettings,
        );

        await _eventService.updateEvent(updated);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event updated'),
              backgroundColor: LuminiqueTheme.successColor,
            ),
          );
          Navigator.of(context).pop(updated);
        }
      } else {
        // Create new event
        final event = await _eventService.createEvent(
          name: _nameController.text,
          ownerId: userId,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          settings: settings,
          networkSettings: networkSettings,
        );

        if (mounted) {
          Navigator.of(context).pop(event);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving event: $e'),
          backgroundColor: LuminiqueTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _wifiNameController.dispose();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminiqueTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: LuminiqueTheme.darkSurface,
        title: Text(
          _existingEvent != null ? 'EDIT EVENT' : 'NEW EVENT',
          style: GoogleFonts.montserrat(letterSpacing: 2),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveEvent,
              child: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          LuminiqueTheme.accentColor,
                        ),
                      ),
                    )
                  : Text(
                      'SAVE',
                      style: GoogleFonts.montserrat(
                        letterSpacing: 2,
                        color: LuminiqueTheme.accentColor,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  LuminiqueTheme.accentColor,
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Event Details Section
                  _buildSectionHeader('EVENT DETAILS'),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.raleway(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Event Name',
                      labelStyle: GoogleFonts.montserrat(
                        letterSpacing: 1,
                        color: Colors.white54,
                      ),
                      hintText: 'e.g., Smith Wedding, Company Party',
                      hintStyle: GoogleFonts.raleway(color: Colors.white24),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an event name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _descriptionController,
                    style: GoogleFonts.raleway(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: GoogleFonts.montserrat(
                        letterSpacing: 1,
                        color: Colors.white54,
                      ),
                      hintText: 'Add any notes about this event',
                      hintStyle: GoogleFonts.raleway(color: Colors.white24),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Features Section
                  _buildSectionHeader('FEATURES'),
                  const SizedBox(height: 16),

                  _buildSwitchTile(
                    icon: Icons.shield_outlined,
                    title: 'Content Moderation',
                    subtitle: 'Automatically filter inappropriate images',
                    value: _moderationEnabled,
                    onChanged: (v) => setState(() => _moderationEnabled = v),
                  ),

                  _buildSwitchTile(
                    icon: Icons.favorite_outline,
                    title: 'Voting',
                    subtitle: 'Allow guests to vote for favorite photos',
                    value: _votingEnabled,
                    onChanged: (v) => setState(() => _votingEnabled = v),
                  ),

                  _buildSwitchTile(
                    icon: Icons.comment_outlined,
                    title: 'Captions',
                    subtitle: 'Allow guests to add captions to photos',
                    value: _captionsEnabled,
                    onChanged: (v) => setState(() => _captionsEnabled = v),
                  ),

                  const SizedBox(height: 40),

                  // Slideshow Section
                  _buildSectionHeader('SLIDESHOW'),
                  const SizedBox(height: 16),

                  _buildSliderTile(
                    icon: Icons.timer_outlined,
                    title: 'Photo Duration',
                    subtitle: '$_slideshowInterval seconds per photo',
                    value: _slideshowInterval.toDouble(),
                    min: 3,
                    max: 15,
                    divisions: 12,
                    onChanged: (v) =>
                        setState(() => _slideshowInterval = v.round()),
                  ),

                  const SizedBox(height: 40),

                  // Limits Section
                  _buildSectionHeader('LIMITS'),
                  const SizedBox(height: 16),

                  _buildSliderTile(
                    icon: Icons.photo_library_outlined,
                    title: 'Max Photos Per Device',
                    subtitle: '$_maxPhotosPerDevice photos',
                    value: _maxPhotosPerDevice.toDouble(),
                    min: 10,
                    max: 100,
                    divisions: 9,
                    onChanged: (v) =>
                        setState(() => _maxPhotosPerDevice = v.round()),
                  ),

                  const SizedBox(height: 40),

                  // Network Section
                  _buildSectionHeader('LOCAL NETWORK (OPTIONAL)'),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _wifiNameController,
                    style: GoogleFonts.raleway(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Wi-Fi Network Name',
                      labelStyle: GoogleFonts.montserrat(
                        letterSpacing: 1,
                        color: Colors.white54,
                      ),
                      prefixIcon: Icon(Icons.wifi, color: Colors.white54),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _wifiPasswordController,
                    style: GoogleFonts.raleway(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Wi-Fi Password',
                      labelStyle: GoogleFonts.montserrat(
                        letterSpacing: 1,
                        color: Colors.white54,
                      ),
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.white54),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 12,
        letterSpacing: 2,
        color: Colors.white54,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: LuminiqueTheme.darkCard,
        border: Border.all(color: Colors.white12),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.white54),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.raleway(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: LuminiqueTheme.accentColor,
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuminiqueTheme.darkCard,
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.raleway(
                        fontSize: 12,
                        color: LuminiqueTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: LuminiqueTheme.accentColor,
            inactiveColor: Colors.white12,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
