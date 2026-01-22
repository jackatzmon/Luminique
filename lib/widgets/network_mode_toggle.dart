import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app/config/theme.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/network_service.dart';

class NetworkModeToggle extends StatefulWidget {
  final Event event;

  const NetworkModeToggle({super.key, required this.event});

  @override
  State<NetworkModeToggle> createState() => _NetworkModeToggleState();
}

class _NetworkModeToggleState extends State<NetworkModeToggle> {
  final EventService _eventService = EventService();

  late NetworkMode _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.event.networkSettings.mode;
  }

  Future<void> _updateMode(NetworkMode mode) async {
    setState(() {
      _selectedMode = mode;
    });

    // Update in network service
    context.read<NetworkService>().setMode(mode);

    // Update in event settings
    final newSettings = NetworkSettings(
      mode: mode,
      localWifiName: widget.event.networkSettings.localWifiName,
      localWifiPassword: widget.event.networkSettings.localWifiPassword,
      localServerIp: widget.event.networkSettings.localServerIp,
      localServerPort: widget.event.networkSettings.localServerPort,
    );

    await _eventService.updateNetworkSettings(widget.event.id, newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkService>(
      builder: (context, networkService, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: LuminiqueTheme.darkCard,
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection status
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: networkService.isOnline
                          ? LuminiqueTheme.successColor
                          : LuminiqueTheme.errorColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    networkService.isOnline ? 'Online' : 'Offline',
                    style: GoogleFonts.raleway(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  if (networkService.currentWifiName != null)
                    Row(
                      children: [
                        Icon(
                          Icons.wifi,
                          size: 16,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          networkService.currentWifiName!,
                          style: GoogleFonts.raleway(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(color: Colors.white12),
              const SizedBox(height: 20),

              // Mode selector
              Text(
                'SELECT MODE',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  letterSpacing: 2,
                  color: Colors.white54,
                ),
              ),

              const SizedBox(height: 16),

              // Mode options
              _ModeOption(
                icon: Icons.cloud_outlined,
                title: 'Internet Mode',
                description: 'Uses cloud storage via venue Wi-Fi or cellular',
                isSelected: _selectedMode == NetworkMode.internet,
                onTap: () => _updateMode(NetworkMode.internet),
              ),

              const SizedBox(height: 12),

              _ModeOption(
                icon: Icons.wifi_tethering,
                title: 'Local Mode',
                description: 'Uses local Wi-Fi router (no internet required)',
                isSelected: _selectedMode == NetworkMode.local,
                onTap: () => _updateMode(NetworkMode.local),
              ),

              const SizedBox(height: 12),

              _ModeOption(
                icon: Icons.sync_alt,
                title: 'Hybrid Mode',
                description: 'Auto-switches based on connectivity',
                isSelected: _selectedMode == NetworkMode.hybrid,
                onTap: () => _updateMode(NetworkMode.hybrid),
                recommended: true,
              ),

              // Local Wi-Fi settings (shown when local mode is selected)
              if (_selectedMode == NetworkMode.local ||
                  _selectedMode == NetworkMode.hybrid) ...[
                const SizedBox(height: 20),
                const Divider(color: Colors.white12),
                const SizedBox(height: 20),

                Text(
                  'LOCAL NETWORK SETTINGS',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    letterSpacing: 2,
                    color: Colors.white54,
                  ),
                ),

                const SizedBox(height: 16),

                _buildLocalSettings(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocalSettings() {
    return Column(
      children: [
        // Wi-Fi Name
        Row(
          children: [
            Icon(Icons.wifi, size: 18, color: Colors.white54),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Network Name',
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.event.networkSettings.localWifiName,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // TODO: Edit Wi-Fi settings
              },
              icon: Icon(Icons.edit_outlined, size: 18),
              color: Colors.white54,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Server Status
        if (widget.event.networkSettings.localServerIp != null)
          Row(
            children: [
              Icon(Icons.dns_outlined, size: 18, color: Colors.white54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local Server',
                      style: GoogleFonts.raleway(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.event.networkSettings.localServerIp}:${widget.event.networkSettings.localServerPort}',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: LuminiqueTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

        const SizedBox(height: 16),

        // Start local server button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Start/stop local server
            },
            icon: Icon(Icons.play_circle_outline, size: 18),
            label: Text(
              'START LOCAL SERVER',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final bool recommended;

  const _ModeOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    this.recommended = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? LuminiqueTheme.accentColor.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? LuminiqueTheme.accentColor.withOpacity(0.5)
                : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? LuminiqueTheme.accentColor : Colors.white54,
            ),
            const SizedBox(width: 16),
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
                          color: isSelected
                              ? LuminiqueTheme.accentColor
                              : Colors.white,
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: LuminiqueTheme.accentColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: GoogleFonts.montserrat(
                              fontSize: 9,
                              letterSpacing: 1,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
              activeColor: LuminiqueTheme.accentColor,
            ),
          ],
        ),
      ),
    );
  }
}
