import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/api_service.dart';
import '../widgets/task_badges.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final ApiService _api = ApiService();

  late Task _task;
  bool _loading = true;
  bool _saving = false;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _refresh(initial: true);
  }

  Future<void> _refresh({bool initial = false}) async {
    if (!initial) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final task = await _api.getTask(_task.id);
      if (!mounted) return;
      setState(() {
        _task = task;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _changeStatus(String status) async {
    if (status == _task.status || _saving) return;

    setState(() => _saving = true);

    try {
      final updated = await _api.updateStatus(_task.id, status);
      if (!mounted) return;
      setState(() {
        _task = updated;
        _saving = false;
      });
      _showMessage('Durum "${updated.statusLabel}" olarak güncellendi');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(e.fullMessage, isError: true);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Görevi sil'),
        content: Text('"${_task.title}" silinsin mi? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);

    try {
      await _api.deleteTask(_task.id);
      if (!mounted) return;
      _showMessage('"${_task.title}" silindi');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(e.fullMessage, isError: true);
    }
  }

    Future<void> _openEdit() async {
    final updated = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: _task)),
    );
    if (!mounted || updated == null) return;
    setState(() => _task = updated);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Görev detayı'),
        actions: [
          IconButton(
            tooltip: 'Düzenle',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _saving || _error != null ? null : _openEdit,
          ),
          IconButton(
            tooltip: 'Sil',
            icon: const Icon(Icons.delete_outline),
            onPressed: _saving || _error != null ? null : _delete,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      final notFound = _error!.message == 'Görev bulunamadı';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                notFound ? Icons.search_off : Icons.cloud_off,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                notFound ? 'Bu görev artık mevcut değil' : _error!.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                notFound
                    ? 'Görev başka bir yerden silinmiş olabilir.'
                    : _error!.details.join('\n'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: notFound ? () => Navigator.pop(context) : () => _refresh(),
                icon: Icon(notFound ? Icons.arrow_back : Icons.refresh),
                label: Text(notFound ? 'Listeye dön' : 'Tekrar dene'),
              ),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => _refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                _task.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: _task.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  StatusChip(status: _task.status),
                  PriorityChip(priority: _task.priority),
                ],
              ),
              const SizedBox(height: 28),
              Text('Durumu değiştir', style: theme.textTheme.titleSmall),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: [
                    for (final status in TaskStatus.values)
                      ButtonSegment(
                        value: status,
                        label: Text(TaskStatus.label(status), textAlign: TextAlign.center),
                      ),
                  ],
                  selected: {_task.status},
                  showSelectedIcon: false,
                  onSelectionChanged: _saving ? null : (set) => _changeStatus(set.first),
                ),
              ),
              const SizedBox(height: 28),
              _InfoTile(
                icon: Icons.notes,
                label: 'Açıklama',
                value: _task.description.isEmpty ? 'Açıklama eklenmemiş' : _task.description,
                muted: _task.description.isEmpty,
              ),
              _InfoTile(
                icon: Icons.person_outline,
                label: 'Sorumlu',
                value: _task.assignee.isEmpty ? 'Atanmamış' : _task.assignee,
                muted: _task.assignee.isEmpty,
              ),
              _InfoTile(
                icon: Icons.event_outlined,
                label: 'Oluşturulma',
                value: formatDateTime(_task.createdAt),
              ),
              _InfoTile(
                icon: Icons.update,
                label: 'Son güncelleme',
                value: _task.updatedAt == null
                    ? 'Henüz güncellenmedi'
                    : formatDateTime(_task.updatedAt!),
                muted: _task.updatedAt == null,
              ),
            ],
          ),
        ),
        if (_loading || _saving)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}

String formatDateTime(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool muted;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: muted ? theme.colorScheme.outline : null,
                    fontStyle: muted ? FontStyle.italic : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}