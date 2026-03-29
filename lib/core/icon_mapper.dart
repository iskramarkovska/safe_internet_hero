import 'package:flutter/material.dart';

class IconMapper {
  static IconData fromString(String iconName) {
    switch (iconName) {
      case 'lock_rounded':
        return Icons.lock_rounded;
      case 'badge_rounded':
        return Icons.badge_rounded;
      case 'share_rounded':
        return Icons.share_rounded;
      case 'track_changes_rounded':
        return Icons.track_changes_rounded;
      case 'phone_android_rounded':
        return Icons.phone_android_rounded;
      case 'key_rounded':
        return Icons.key_rounded;
      case 'security_rounded':
        return Icons.security_rounded;
      case 'verified_user_rounded':
        return Icons.verified_user_rounded;
      case 'shield_rounded':
        return Icons.shield_rounded;
      case 'folder_rounded':
        return Icons.folder_rounded;
      case 'favorite_rounded':
        return Icons.favorite_rounded;
      case 'visibility_rounded':
        return Icons.visibility_rounded;
      case 'emoji_people_rounded':
        return Icons.emoji_people_rounded;
      case 'block_rounded':
        return Icons.block_rounded;
      case 'gavel_rounded':
        return Icons.gavel_rounded;
      case 'photo_camera_rounded':
        return Icons.photo_camera_rounded;
      case 'settings_rounded':
        return Icons.settings_rounded;
      case 'person_off_rounded':
        return Icons.person_off_rounded;
      case 'location_off_rounded':
        return Icons.location_off_rounded;
      case 'timer_rounded':
        return Icons.timer_rounded;
      case 'warning_amber_rounded':
        return Icons.warning_amber_rounded;
      case 'search_rounded':
        return Icons.search_rounded;
      case 'link_off_rounded':
        return Icons.link_off_rounded;
      case 'mark_email_read_rounded':
        return Icons.mark_email_read_rounded;
      case 'gps_fixed_rounded':
        return Icons.gps_fixed_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}