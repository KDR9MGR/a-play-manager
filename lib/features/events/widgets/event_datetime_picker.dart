import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:a_play_manage/core/theme/colors.dart';

class EventDateTimePicker extends StatelessWidget {
  final String label;
  final DateTime dateTime;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final DateFormat dateFormat;
  final DateFormat timeFormat;

  const EventDateTimePicker({
    super.key,
    required this.label,
    required this.dateTime,
    required this.onDateTap,
    required this.onTimeTap,
    required this.dateFormat,
    required this.timeFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSelector(
                context,
                icon: Icons.calendar_today,
                text: dateFormat.format(dateTime),
                onTap: onDateTap,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSelector(
                context,
                icon: Icons.access_time,
                text: timeFormat.format(dateTime),
                onTap: onTimeTap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelector(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 