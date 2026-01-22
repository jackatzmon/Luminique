import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/config/theme.dart';
import '../providers/upload_provider.dart';

class UploadProgressCard extends StatelessWidget {
  final UploadItem item;
  final VoidCallback? onRemove;
  final VoidCallback? onRetry;

  const UploadProgressCard({
    super.key,
    required this.item,
    this.onRemove,
    this.onRetry,
  });

  Color get _statusColor {
    switch (item.status) {
      case UploadStatus.pending:
        return Colors.white54;
      case UploadStatus.moderating:
        return LuminiqueTheme.warningColor;
      case UploadStatus.uploading:
        return LuminiqueTheme.accentColor;
      case UploadStatus.completed:
        return LuminiqueTheme.successColor;
      case UploadStatus.rejected:
        return LuminiqueTheme.errorColor;
      case UploadStatus.failed:
        return LuminiqueTheme.errorColor;
    }
  }

  IconData get _statusIcon {
    switch (item.status) {
      case UploadStatus.pending:
        return Icons.hourglass_empty;
      case UploadStatus.moderating:
        return Icons.shield_outlined;
      case UploadStatus.uploading:
        return Icons.cloud_upload_outlined;
      case UploadStatus.completed:
        return Icons.check_circle;
      case UploadStatus.rejected:
        return Icons.block;
      case UploadStatus.failed:
        return Icons.error_outline;
    }
  }

  String get _statusText {
    switch (item.status) {
      case UploadStatus.pending:
        return 'Pending';
      case UploadStatus.moderating:
        return 'Checking...';
      case UploadStatus.uploading:
        return 'Uploading...';
      case UploadStatus.completed:
        return 'Uploaded';
      case UploadStatus.rejected:
        return item.error ?? 'Rejected';
      case UploadStatus.failed:
        return item.error ?? 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LuminiqueTheme.darkCard,
        border: Border.all(
          color: _statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: LuminiqueTheme.darkSurface,
              image: DecorationImage(
                image: MemoryImage(item.bytes),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File name
                  Text(
                    item.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.raleway(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Status
                  Row(
                    children: [
                      Icon(
                        _statusIcon,
                        size: 14,
                        color: _statusColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _statusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.raleway(
                            fontSize: 12,
                            color: _statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Progress bar
                  if (item.status == UploadStatus.moderating ||
                      item.status == UploadStatus.uploading) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: item.progress,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                      minHeight: 2,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Actions
          if (item.status == UploadStatus.pending && onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.close,
                color: Colors.white54,
                size: 20,
              ),
              tooltip: 'Remove',
            ),

          if (item.status == UploadStatus.failed && onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: Icon(
                Icons.refresh,
                color: LuminiqueTheme.accentColor,
                size: 20,
              ),
              tooltip: 'Retry',
            ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
