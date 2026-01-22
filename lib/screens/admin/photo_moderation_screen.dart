import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../app/config/theme.dart';
import '../../models/photo.dart';
import '../../services/photo_service.dart';
import '../../providers/app_state_provider.dart';

class PhotoModerationScreen extends StatefulWidget {
  const PhotoModerationScreen({super.key});

  @override
  State<PhotoModerationScreen> createState() => _PhotoModerationScreenState();
}

class _PhotoModerationScreenState extends State<PhotoModerationScreen>
    with SingleTickerProviderStateMixin {
  final PhotoService _photoService = PhotoService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventId = context.read<AppStateProvider>().currentEvent?.id;

    if (eventId == null) {
      return Scaffold(
        backgroundColor: LuminiqueTheme.darkBackground,
        appBar: AppBar(
          backgroundColor: LuminiqueTheme.darkSurface,
          title: Text(
            'MODERATION',
            style: GoogleFonts.montserrat(letterSpacing: 2),
          ),
        ),
        body: Center(
          child: Text(
            'No event selected',
            style: GoogleFonts.raleway(color: Colors.white54),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: LuminiqueTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: LuminiqueTheme.darkSurface,
        title: Text(
          'MODERATION',
          style: GoogleFonts.montserrat(letterSpacing: 2),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: LuminiqueTheme.accentColor,
          unselectedLabelColor: Colors.white54,
          indicatorColor: LuminiqueTheme.accentColor,
          labelStyle: GoogleFonts.montserrat(
            fontSize: 12,
            letterSpacing: 1,
          ),
          tabs: const [
            Tab(text: 'PENDING'),
            Tab(text: 'APPROVED'),
            Tab(text: 'REJECTED'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PhotoGrid(
            eventId: eventId,
            statusFilter: [PhotoStatus.pending, PhotoStatus.flagged],
            photoService: _photoService,
            showActions: true,
          ),
          _PhotoGrid(
            eventId: eventId,
            statusFilter: [PhotoStatus.approved],
            photoService: _photoService,
          ),
          _PhotoGrid(
            eventId: eventId,
            statusFilter: [PhotoStatus.rejected],
            photoService: _photoService,
          ),
        ],
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final String eventId;
  final List<PhotoStatus> statusFilter;
  final PhotoService photoService;
  final bool showActions;

  const _PhotoGrid({
    required this.eventId,
    required this.statusFilter,
    required this.photoService,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Photo>>(
      stream: photoService.getAllPhotosStream(eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                LuminiqueTheme.accentColor,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 64,
                  color: Colors.white24,
                ),
                const SizedBox(height: 16),
                Text(
                  'No photos',
                  style: GoogleFonts.raleway(color: Colors.white54),
                ),
              ],
            ),
          );
        }

        final filteredPhotos = snapshot.data!
            .where((p) => statusFilter.contains(p.status))
            .toList();

        if (filteredPhotos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.white24,
                ),
                const SizedBox(height: 16),
                Text(
                  'No photos in this category',
                  style: GoogleFonts.raleway(color: Colors.white54),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: filteredPhotos.length,
          itemBuilder: (context, index) {
            final photo = filteredPhotos[index];
            return _PhotoTile(
              photo: photo,
              showActions: showActions,
              onApprove: () => photoService.approvePhoto(photo.id),
              onReject: () => photoService.rejectPhoto(photo.id),
              onDelete: () => photoService.deletePhoto(photo.id),
            );
          },
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final Photo photo;
  final bool showActions;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  const _PhotoTile({
    required this.photo,
    required this.showActions,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (photo.status) {
      case PhotoStatus.pending:
        return Colors.white54;
      case PhotoStatus.approved:
        return LuminiqueTheme.successColor;
      case PhotoStatus.rejected:
        return LuminiqueTheme.errorColor;
      case PhotoStatus.flagged:
        return LuminiqueTheme.warningColor;
      case PhotoStatus.archived:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPhotoDetail(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo
          CachedNetworkImage(
            imageUrl: photo.thumbnailUrl.isNotEmpty
                ? photo.thumbnailUrl
                : photo.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: LuminiqueTheme.darkCard,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    LuminiqueTheme.accentColor,
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: LuminiqueTheme.darkCard,
              child: Icon(
                Icons.broken_image,
                color: Colors.white24,
              ),
            ),
          ),

          // Status indicator
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusColor,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),

          // Flagged indicator
          if (photo.status == PhotoStatus.flagged)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: LuminiqueTheme.warningColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'REVIEW',
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Actions overlay
          if (showActions)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: onApprove,
                      icon: Icon(
                        Icons.check,
                        color: LuminiqueTheme.successColor,
                        size: 20,
                      ),
                      tooltip: 'Approve',
                    ),
                    IconButton(
                      onPressed: onReject,
                      icon: Icon(
                        Icons.close,
                        color: LuminiqueTheme.errorColor,
                        size: 20,
                      ),
                      tooltip: 'Reject',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPhotoDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: LuminiqueTheme.darkCard,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Photo
            AspectRatio(
              aspectRatio: 1,
              child: CachedNetworkImage(
                imageUrl: photo.imageUrl,
                fit: BoxFit.contain,
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photo.caption != null && photo.caption!.isNotEmpty) ...[
                    Text(
                      photo.caption!,
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.white54),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(photo.uploadedAt),
                        style: GoogleFonts.raleway(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),

                  if (photo.moderationResult != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 14, color: Colors.white54),
                        const SizedBox(width: 8),
                        Text(
                          'Checked by ${photo.moderationResult!.source.name}',
                          style: GoogleFonts.raleway(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Actions
                  if (showActions)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              onApprove();
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.check, size: 18),
                            label: Text(
                              'APPROVE',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LuminiqueTheme.successColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              onReject();
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.close, size: 18),
                            label: Text(
                              'REJECT',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: LuminiqueTheme.errorColor,
                              side: BorderSide(color: LuminiqueTheme.errorColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')} - '
        '${date.month}/${date.day}/${date.year}';
  }
}
