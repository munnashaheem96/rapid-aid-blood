import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rapid_aid/theme/app_theme.dart';

class TimelineNode {
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final bool isCompleted;

  TimelineNode({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.isCompleted = false,
  });
}

class EmergencyTimeline extends StatelessWidget {
  final List<TimelineNode> nodes;

  const EmergencyTimeline({
    super.key,
    required this.nodes,
  });

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return Center(
        child: Text(
          "No timeline logs recorded for this emergency.",
          style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];
        final isLast = index == nodes.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Line and Circle Indicator
            Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: node.isCompleted ? AppTheme.primary : Colors.grey.shade300,
                    border: Border.all(
                      color: node.isCompleted ? AppTheme.primaryLight : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 45,
                    color: node.isCompleted ? AppTheme.primary : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        node.title,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: node.isCompleted ? AppTheme.textMain : AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        DateFormat('hh:mm a').format(node.timestamp),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    node.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
