import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/lead.dart';
import '../entities/lead_note.dart';
import '../repositories/lead_repository.dart';

class LeadAuditHelper {
  /// Resolves the display name of the current authenticated user or staff member.
  static String getAuthorName([String? fallbackStaffName]) {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final meta = user.userMetadata;
        if (meta != null) {
          final fullName = meta['full_name'] ?? meta['name'] ?? meta['displayName'];
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

  /// Compares old lead with new lead and records audit notes in the repository.
  static Future<void> recordLeadChanges({
    required Lead existing,
    required Lead updated,
    required LeadRepository repository,
  }) async {
    final author = getAuthorName(existing.staffName);

    // 1. Check general info changes
    final otherChanges = <String>[];

    if (existing.name.trim() != updated.name.trim() &&
        existing.name.trim().isNotEmpty &&
        updated.name.trim().isNotEmpty) {
      otherChanges.add('Name changed: ${existing.name.trim()} > ${updated.name.trim()}');
    }

    if (existing.phone.trim() != updated.phone.trim() &&
        existing.phone.trim().isNotEmpty &&
        updated.phone.trim().isNotEmpty) {
      otherChanges.add('Phone changed: ${existing.phone.trim()} > ${updated.phone.trim()}');
    }

    if (existing.email.trim() != updated.email.trim() &&
        existing.email.trim().isNotEmpty &&
        updated.email.trim().isNotEmpty) {
      otherChanges.add('Email changed: ${existing.email.trim()} > ${updated.email.trim()}');
    }

    if (existing.company.trim() != updated.company.trim() &&
        existing.company.trim().isNotEmpty &&
        updated.company.trim().isNotEmpty) {
      otherChanges.add('Company changed: ${existing.company.trim()} > ${updated.company.trim()}');
    }

    if (existing.source != updated.source) {
      otherChanges.add('Source changed: ${existing.source.displayName} > ${updated.source.displayName}');
    }

    if (existing.rating != updated.rating) {
      otherChanges.add('Rating changed: ${existing.rating} > ${updated.rating}');
    }

    if (existing.value != updated.value) {
      final oldVal = NumberFormat('#,##,###').format(existing.value);
      final newVal = NumberFormat('#,##,###').format(updated.value);
      otherChanges.add('Value changed: ₹$oldVal > ₹$newVal');
    }

    if (existing.territory.trim() != updated.territory.trim() &&
        existing.territory.trim().isNotEmpty &&
        updated.territory.trim().isNotEmpty) {
      otherChanges.add('Territory changed: ${existing.territory.trim()} > ${updated.territory.trim()}');
    }

    if (existing.title.trim() != updated.title.trim() &&
        existing.title.trim().isNotEmpty &&
        updated.title.trim().isNotEmpty) {
      otherChanges.add('Title changed: ${existing.title.trim()} > ${updated.title.trim()}');
    }

    if (existing.staffName.trim() != updated.staffName.trim() &&
        existing.staffName.trim().isNotEmpty &&
        updated.staffName.trim().isNotEmpty) {
      otherChanges.add('Assigned changed: ${existing.staffName.trim()} > ${updated.staffName.trim()}');
    }

    if (otherChanges.isNotEmpty) {
      final note = LeadNote(
        id: '',
        leadId: updated.id,
        content: formatNoteContent(
          text: otherChanges.join('\n'),
          authorName: author,
        ),
        createdAt: DateTime.now(),
      );
      await repository.addLeadNote(note);
    }

    // 2. Stage change as its own card/bubble (exact screenshot behavior)
    if (existing.stage != updated.stage) {
      final stageNote = LeadNote(
        id: '',
        leadId: updated.id,
        content: formatNoteContent(
          text: 'Stage changed: ${existing.stage.displayName} > ${updated.stage.displayName}',
          authorName: author,
        ),
        createdAt: DateTime.now(),
      );
      await repository.addLeadNote(stageNote);
    }
  }
}
