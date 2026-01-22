import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app/config/theme.dart';
import '../../providers/app_state_provider.dart';
import '../../services/moderation_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _visionApiKeyController = TextEditingController();
  final ModerationService _moderationService = ModerationService();

  bool _obscureApiKey = true;

  @override
  void dispose() {
    _visionApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminiqueTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: LuminiqueTheme.darkSurface,
        title: Text(
          'SETTINGS',
          style: GoogleFonts.montserrat(letterSpacing: 2),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Appearance Section
          _buildSectionHeader('APPEARANCE'),
          const SizedBox(height: 16),

          _buildSettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Use dark theme (recommended for events)',
            trailing: Consumer<AppStateProvider>(
              builder: (context, appState, child) {
                return Switch(
                  value: appState.themeMode == ThemeMode.dark,
                  onChanged: (v) {
                    appState.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                  },
                  activeColor: LuminiqueTheme.accentColor,
                );
              },
            ),
          ),

          const SizedBox(height: 40),

          // API Configuration Section
          _buildSectionHeader('API CONFIGURATION'),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LuminiqueTheme.darkCard,
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud_outlined, color: Colors.white54),
                    const SizedBox(width: 12),
                    Text(
                      'Google Cloud Vision API',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _moderationService.isCloudModerationAvailable
                            ? LuminiqueTheme.successColor.withOpacity(0.2)
                            : Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _moderationService.isCloudModerationAvailable
                            ? 'CONFIGURED'
                            : 'NOT SET',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          letterSpacing: 1,
                          color: _moderationService.isCloudModerationAvailable
                              ? LuminiqueTheme.successColor
                              : Colors.white54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Used for content moderation. If not configured, local AI moderation will be used instead.',
                  style: GoogleFonts.raleway(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _visionApiKeyController,
                  obscureText: _obscureApiKey,
                  style: GoogleFonts.raleway(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    labelStyle: GoogleFonts.montserrat(
                      letterSpacing: 1,
                      color: Colors.white54,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _obscureApiKey = !_obscureApiKey);
                      },
                      icon: Icon(
                        _obscureApiKey
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _moderationService.configure(
                        apiKey: _visionApiKeyController.text,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('API key saved'),
                          backgroundColor: LuminiqueTheme.successColor,
                        ),
                      );
                    },
                    child: Text(
                      'SAVE API KEY',
                      style: GoogleFonts.montserrat(letterSpacing: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Moderation Section
          _buildSectionHeader('MODERATION'),
          const SizedBox(height: 16),

          _buildSettingsTile(
            icon: Icons.shield_outlined,
            title: 'Current Mode',
            subtitle: _moderationService.currentMode,
          ),

          const SizedBox(height: 40),

          // About Section
          _buildSectionHeader('ABOUT'),
          const SizedBox(height: 16),

          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'Luminique Photo Stream',
            subtitle: 'Version 1.0.0',
          ),

          _buildSettingsTile(
            icon: Icons.code,
            title: 'Built with',
            subtitle: 'Flutter + Firebase',
          ),

          const SizedBox(height: 40),

          // Support Section
          _buildSectionHeader('SUPPORT'),
          const SizedBox(height: 16),

          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Documentation',
            subtitle: 'View guides and FAQs',
            onTap: () {
              // TODO: Open help
            },
          ),

          _buildSettingsTile(
            icon: Icons.email_outlined,
            title: 'Contact Support',
            subtitle: 'info@luminiqueeventsgroup.com',
            onTap: () {
              // TODO: Open email
            },
          ),

          const SizedBox(height: 100),
        ],
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

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: LuminiqueTheme.darkCard,
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white54),
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
        trailing: trailing ??
            (onTap != null
                ? Icon(Icons.chevron_right, color: Colors.white54)
                : null),
        onTap: onTap,
      ),
    );
  }
}
