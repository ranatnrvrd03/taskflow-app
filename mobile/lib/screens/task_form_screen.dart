import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/api_service.dart';
import '../widgets/task_badges.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  bool get isEdit => task != null;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _assigneeController;
  late int _priority;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _assigneeController = TextEditingController(text: task?.assignee ?? '');
    _priority = task?.priority ?? TaskPriority.medium;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assigneeController.dispose();
    super.dispose();
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

  Map<String, dynamic> _changedFields(Task task) {
    final changes = <String, dynamic>{};
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final assignee = _assigneeController.text.trim();

    if (title != task.title) changes['title'] = title;
    if (description != task.description) changes['description'] = description;
    if (assignee != task.assignee) changes['assignee'] = assignee;
    if (_priority != task.priority) changes['priority'] = _priority;

    return changes;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (widget.isEdit) {
      final changes = _changedFields(widget.task!);
      if (changes.isEmpty) {
        _showMessage('Herhangi bir değişiklik yapılmadı');
        return;
      }
      await _submit(() => _api.updateTask(widget.task!.id, changes), 'Görev güncellendi');
    } else {
      await _submit(
        () => _api.createTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          assignee: _assigneeController.text.trim(),
        ),
        'Görev oluşturuldu',
      );
    }
  }

  Future<void> _submit(Future<Task> Function() request, String successMessage) async {
    setState(() => _saving = true);

    try {
      final task = await request();
      if (!mounted) return;
      _showMessage('$successMessage: "${task.title}"');
      Navigator.pop(context, task);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(e.fullMessage, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Görevi düzenle' : 'Yeni görev'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              enabled: !_saving,
              maxLength: 100,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Başlık *',
                hintText: 'Örn: Sunumu hazırla',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Başlık zorunludur';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              enabled: !_saving,
              minLines: 3,
              maxLines: 6,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                hintText: 'Görevin ayrıntıları (isteğe bağlı)',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _assigneeController,
              enabled: !_saving,
              maxLength: 50,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Sorumlu kişi',
                hintText: 'Örn: rana (isteğe bağlı)',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Öncelik', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: [
                  for (final priority in TaskPriority.values)
                    ButtonSegment(
                      value: priority,
                      label: Text(TaskPriority.label(priority)),
                      icon: Icon(Icons.flag, color: priorityColor(priority)),
                    ),
                ],
                selected: {_priority},
                showSelectedIcon: false,
                onSelectionChanged: _saving
                    ? null
                    : (set) => setState(() => _priority = set.first),
              ),
            ),
            if (!widget.isEdit) ...[
              const SizedBox(height: 16),
              Text(
                'Yeni görevler "Bekliyor" durumunda başlar. Durumu görev detayından değiştirebilirsin.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(widget.isEdit ? Icons.save_outlined : Icons.add),
              label: Text(
                _saving
                    ? 'Kaydediliyor...'
                    : widget.isEdit
                        ? 'Değişiklikleri kaydet'
                        : 'Görevi oluştur',
              ),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }
}