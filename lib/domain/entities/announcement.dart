import 'package:flutter/material.dart';
import 'package:worksense_app/core/theme/app_colors.dart';

// ── Enum ─────────────────────────────────────────────────────────────────────

enum AnnouncementPriority {
  low,
  normal,
  high,
  urgent;

  String get label {
    switch (this) {
      case AnnouncementPriority.low:    return 'Informativo';
      case AnnouncementPriority.normal: return 'General';
      case AnnouncementPriority.high:   return 'Importante';
      case AnnouncementPriority.urgent: return 'Urgente';
    }
  }

  String get raw {
    switch (this) {
      case AnnouncementPriority.low:    return 'LOW';
      case AnnouncementPriority.normal: return 'NORMAL';
      case AnnouncementPriority.high:   return 'HIGH';
      case AnnouncementPriority.urgent: return 'URGENT';
    }
  }

  Color get color {
    switch (this) {
      case AnnouncementPriority.low:    return AppColors.grey400;
      case AnnouncementPriority.normal: return AppColors.info;
      case AnnouncementPriority.high:   return AppColors.warning;
      case AnnouncementPriority.urgent: return AppColors.error;
    }
  }

  IconData get icon {
    switch (this) {
      case AnnouncementPriority.low:    return Icons.info_outline;
      case AnnouncementPriority.normal: return Icons.campaign_outlined;
      case AnnouncementPriority.high:   return Icons.warning_amber_outlined;
      case AnnouncementPriority.urgent: return Icons.priority_high;
    }
  }

  static AnnouncementPriority fromRaw(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'LOW':    return AnnouncementPriority.low;
      case 'HIGH':   return AnnouncementPriority.high;
      case 'URGENT': return AnnouncementPriority.urgent;
      default:       return AnnouncementPriority.normal;
    }
  }
}

// ── Entity ───────────────────────────────────────────────────────────────────

class Announcement {
  final String id;
  final String companyId;
  final String authorId;
  final String title;
  final String content;
  final AnnouncementPriority priority;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const Announcement({
    required this.id,
    required this.companyId,
    required this.authorId,
    required this.title,
    required this.content,
    required this.priority,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool get isActive => !isExpired;

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'author_id': authorId,
        'title': title,
        'content': content,
        'priority': priority.raw,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
      };
}
