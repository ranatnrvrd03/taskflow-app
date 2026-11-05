import 'package:flutter/material.dart';

import '../models/task.dart';

// Duruma göre renk: liste ve detay ekranında aynı renkler kullanılsın diye tek yerde
Color statusColor(String status) {
  switch (status) {
    case TaskStatus.pending:
      return Colors.orange;
    case TaskStatus.inProgress:
      return Colors.blue;
    case TaskStatus.done:
      return Colors.green;
    default:
      return Colors.grey;
  }
}

// Önceliğe göre renk
Color priorityColor(int priority) {
  switch (priority) {
    case TaskPriority.low:
      return Colors.blueGrey;
    case TaskPriority.medium:
      return Colors.amber.shade800;
    case TaskPriority.high:
      return Colors.red;
    default:
      return Colors.grey;
  }
}

// Renkli, yuvarlak köşeli küçük etiket
class LabelChip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const LabelChip({super.key, required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Durum etiketi (Bekliyor / Devam ediyor / Tamamlandı)
class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return LabelChip(text: TaskStatus.label(status), color: statusColor(status));
  }
}

// Öncelik etiketi (Düşük / Orta / Yüksek)
class PriorityChip extends StatelessWidget {
  final int priority;

  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    return LabelChip(
      text: TaskPriority.label(priority),
      color: priorityColor(priority),
      icon: Icons.flag,
    );
  }
}