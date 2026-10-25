import 'package:flutter/material.dart';
import '../../domain/entities/lead_stats.dart';
import 'crm_ui_constants.dart';

class CrmStatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const CrmStatCard({
    super.key,
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: CrmStyles.textMuted.withOpacity(0.7),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count.toString(),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: CrmStyles.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CrmStyles.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}

class CrmStageDistributionBar extends StatelessWidget {
  final LeadStats stats;

  const CrmStageDistributionBar({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.newCount +
        stats.contactedCount +
        stats.proposalSentCount +
        stats.disqualifiedCount +
        stats.convertedCount;

    if (total == 0) return const SizedBox.shrink();

    final newPct = stats.newCount / total;
    final contactedPct = stats.contactedCount / total;
    final proposalPct = stats.proposalSentCount / total;
    final convertedPct = stats.convertedCount / total;
    final disqualifiedPct = stats.disqualifiedCount / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CrmStyles.radiusLarge),
        border: Border.all(color: CrmStyles.border, width: 1),
        boxShadow: CrmStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pipeline Distribution',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CrmStyles.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: CrmStyles.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$total Total Leads',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CrmStyles.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (newPct > 0)
                    Expanded(
                      flex: (newPct * 1000).toInt(),
                      child: Container(color: const Color(0xFF1565C0)),
                    ),
                  if (contactedPct > 0)
                    Expanded(
                      flex: (contactedPct * 1000).toInt(),
                      child: Container(color: const Color(0xFFF9A825)),
                    ),
                  if (proposalPct > 0)
                    Expanded(
                      flex: (proposalPct * 1000).toInt(),
                      child: Container(color: const Color(0xFF0097A7)),
                    ),
                  if (convertedPct > 0)
                    Expanded(
                      flex: (convertedPct * 1000).toInt(),
                      child: Container(color: const Color(0xFF2E7D32)),
                    ),
                  if (disqualifiedPct > 0)
                    Expanded(
                      flex: (disqualifiedPct * 1000).toInt(),
                      child: Container(color: const Color(0xFFE53935)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildLegend('New', const Color(0xFF1565C0), stats.newCount),
              _buildLegend('Contacted', const Color(0xFFF9A825), stats.contactedCount),
              _buildLegend('Proposal', const Color(0xFF0097A7), stats.proposalSentCount),
              _buildLegend('Converted', const Color(0xFF2E7D32), stats.convertedCount),
              _buildLegend('Disqualified', const Color(0xFFE53935), stats.disqualifiedCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String title, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$title ($count)',
          style: const TextStyle(
            fontSize: 12,
            color: CrmStyles.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
