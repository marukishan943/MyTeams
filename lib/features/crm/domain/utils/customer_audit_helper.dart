import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerAuditHelper {
  /// Resolves the display name of the current authenticated user or staff member.
  static String getAuthorName([String? fallbackStaffName]) {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final meta = user.userMetadata;
        if (meta != null) {
          final fullName =
              meta['full_name'] ?? meta['name'] ?? meta['displayName'];
          if (fullName != null && fullName.toString().trim().isNotEmpty) {
            return fullName.toString().trim().toUpperCase();
          }
        }
        final email = user.email;
        if (email != null && email.isNotEmpty) {
          final namePart = email
              .split('@')
              .first
              .replaceAll(RegExp(r'[._\-]'), ' ')
              .trim();
          if (namePart.isNotEmpty) {
            return namePart.toUpperCase();
          }
        }
      }
    } catch (_) {}

    if (fallbackStaffName != null && fallbackStaffName.trim().isNotEmpty) {
      return fallbackStaffName.trim().toUpperCase();
    }
    return 'ADMIN ADMIN';
  }

  /// Encodes author metadata into note content safely without database schema changes.
  static String formatNoteContent({
    required String text,
    required String authorName,
  }) {
    final cleanAuthor = authorName.trim();
    if (cleanAuthor.isEmpty) return text.trim();
    return '[author: $cleanAuthor]\n${text.trim()}';
  }

  /// Decodes author and body from note content.
  static ({String author, String text}) parseNoteContent(
    String rawContent, [
    String? fallbackStaffName,
  ]) {
    final pattern = RegExp(r'^\[author:\s*([^\]]+)\]\s*\n?');
    final match = pattern.firstMatch(rawContent);
    if (match != null) {
      final author = match.group(1)?.trim() ?? '';
      final text = rawContent.substring(match.end).trim();
      return (
        author: author.isNotEmpty ? author : getAuthorName(fallbackStaffName),
        text: text,
      );
    }

    return (
      author: getAuthorName(fallbackStaffName),
      text: rawContent.trim(),
    );
  }
}
