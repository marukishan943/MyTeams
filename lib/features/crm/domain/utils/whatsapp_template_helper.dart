import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/lead.dart';

class WhatsAppTemplateHelper {
  static const String defaultLeadTemplate =
      'Hello {{name}}, following up on our recent discussion regarding your requirements with {{brand_name}}. Please let us know how we can assist you!';
  static const String defaultBrandName = 'IV SQUARE STRUCTURE INDIA PVT LTD';

  static String? _cachedTemplate;
  static DateTime? _lastFetchTime;

  /// Fetches the default WhatsApp template for Leads from Supabase SYS_CONFIG
  static Future<String> getLeadDefaultTemplate() async {
    if (_cachedTemplate != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 2) {
      return _cachedTemplate!;
    }

    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('customers')
          .select('company')
          .eq('customer_number', 'SYS_CONFIG')
          .maybeSingle();

      if (res != null && res['company'] != null) {
        final parsed = jsonDecode(res['company'] as String);
        if (parsed['templates'] is List) {
          final list = parsed['templates'] as List;
          final defTmpl = list.firstWhere(
            (t) => t['module'] == 'Leads' && t['is_default'] == true,
            orElse: () => list.firstWhere(
              (t) => t['module'] == 'Leads',
              orElse: () => null,
            ),
          );
          if (defTmpl != null && defTmpl['content'] != null) {
            _cachedTemplate = defTmpl['content'] as String;
            _lastFetchTime = DateTime.now();
            return _cachedTemplate!;
          }
        }
      }
    } catch (_) {
      // Best-effort fallback
    }

    return _cachedTemplate ?? defaultLeadTemplate;
  }

  /// Formats the template with the lead's values
  static String formatLeadMessage(String template, Lead? lead, {String? fallbackPhone}) {
    final leadName = lead?.name ?? '';
    final companyName = (lead != null && lead.company.isNotEmpty) ? lead.company : leadName;
    final stage = lead != null ? lead.stage.name : '';
    final phone = lead?.phone ?? fallbackPhone ?? '';
    final leadNum = lead?.leadNumber ?? '';

    return template
        .replaceAll('{{name}}', leadName)
        .replaceAll('{{companyName}}', companyName)
        .replaceAll('{{company_name}}', companyName)
        .replaceAll('{{company}}', companyName)
        .replaceAll('{{brand_name}}', defaultBrandName)
        .replaceAll('{{stage}}', stage)
        .replaceAll('{{phone}}', phone)
        .replaceAll('{{lead_number}}', leadNum);
  }

  /// Cleans phone, encodes message, and opens WhatsApp
  static Future<bool> openWhatsApp({
    required String phone,
    String? message,
  }) async {
    var cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isEmpty) return false;

    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }

    final encodedText = message != null && message.isNotEmpty ? Uri.encodeComponent(message) : '';
    final nativeUri = Uri.parse(encodedText.isNotEmpty
        ? 'whatsapp://send?phone=$cleanPhone&text=$encodedText'
        : 'whatsapp://send?phone=$cleanPhone');
    final webUri = Uri.parse(encodedText.isNotEmpty
        ? 'https://wa.me/$cleanPhone?text=$encodedText'
        : 'https://wa.me/$cleanPhone');

    try {
      if (await canLaunchUrl(nativeUri)) {
        return await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
  }
}
