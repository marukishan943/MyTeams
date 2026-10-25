import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/lead.dart';
import 'crm_ui_constants.dart';

class CrmLeadCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback onTap;

  const CrmLeadCard({
    super.key,
    required this.lead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CrmStyles.radiusLarge),
        border: Border.all(color: CrmStyles.border, width: 1),
        boxShadow: CrmStyles.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(CrmStyles.radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CrmStyles.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Lead Number, Source Chip, Stage Badge
                Row(
                  children: [
                    // Lead number pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: CrmStyles.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        lead.leadNumber.isNotEmpty ? '#${lead.leadNumber}' : '#---',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: CrmStyles.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Source chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getSourceIcon(lead.source.displayName),
                            size: 12,
                            color: CrmStyles.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lead.source.displayName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: CrmStyles.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Stage badge with colored dot
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: lead.stage.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: lead.stage.color.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: lead.stage.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            lead.stage.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: lead.stage.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Middle: Lead Name & Company
                Text(
                  lead.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CrmStyles.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (lead.company.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.business_outlined,
                        size: 14,
                        color: CrmStyles.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          lead.company,
                          style: const TextStyle(
                            fontSize: 13,
                            color: CrmStyles.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),

                // Divider line
                const Divider(height: 1, color: CrmStyles.borderLight),
                const SizedBox(height: 10),

                // Bottom row: Value / Location / Staff
                Row(
                  children: [
                    // Location / Territory tag
                    if (lead.city.isNotEmpty || lead.territory.isNotEmpty) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: CrmStyles.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            lead.city.isNotEmpty ? lead.city : lead.territory,
                            style: const TextStyle(
                              fontSize: 12,
                              color: CrmStyles.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Lead value (if > 0)
                    if (lead.value > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CrmStyles.successLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '₹${NumberFormat('#,##,###').format(lead.value)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF047857), // Emerald 700
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],

                    const Spacer(),

                    // Staff name
                    if (lead.staffName.isNotEmpty) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: CrmStyles.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                lead.staffName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: CrmStyles.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            lead.staffName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: CrmStyles.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: CrmStyles.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSourceIcon(String source) {
    final s = source.toLowerCase();
    if (s.contains('call')) return Icons.phone_outlined;
    if (s.contains('email')) return Icons.email_outlined;
    if (s.contains('web')) return Icons.language_outlined;
    return Icons.tag_outlined;
  }
}
