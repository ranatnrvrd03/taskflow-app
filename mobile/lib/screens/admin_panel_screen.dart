import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../widgets/task_badges.dart';
import 'task_detail_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final ApiService _api = ApiService();

  List<TeamMember> _members = [];
  List<Task> _tasks = [];
  bool _loading = true;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
  }

  Future<void> _load({bool initial = false}) async {
    if (!initial) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([_api.getUsers(), _api.getTasks()]);
      if (!mounted) return;
      setState(() {
        _members = results[0] as List<TeamMember>;
        _tasks = results[1] as List<Task>;
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

  Future<void> _openTask(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
    );
    if (!mounted) return;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ekip paneli'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : () => _load(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);

    if (_loading && _members.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text(_error!.message, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _load(),
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
    }

    final open = _tasks.where((t) => !t.isDone).length;
    final done = _tasks.where((t) => t.isDone).length;
    final overdueTasks = _tasks.where((t) => t.isOverdue).toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
    final unassigned = _tasks.where((t) => t.assigneeId == null && !t.isDone).length;

    return RefreshIndicator(
      onRefresh: () => _load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text('Genel durum', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatTile(label: 'Toplam', value: _tasks.length, icon: Icons.list_alt, color: Colors.indigo),
              const SizedBox(width: 12),
              _StatTile(label: 'Açık', value: open, icon: Icons.pending_actions, color: Colors.blue),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatTile(label: 'Geciken', value: overdueTasks.length, icon: Icons.warning_amber, color: Colors.red),
              const SizedBox(width: 12),
              _StatTile(label: 'Tamamlanan', value: done, icon: Icons.check_circle_outline, color: Colors.green),
            ],
          ),
          if (unassigned > 0) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_off_outlined),
                title: Text('$unassigned açık görev kimseye atanmamış'),
                subtitle: const Text('Görev detayında kalem ikonuyla atama yapabilirsin.'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('Ekip', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final member in _members) _MemberCard(member: member),
          const SizedBox(height: 24),
          Text('Geciken görevler', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (overdueTasks.isEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.verified_outlined, color: Colors.green),
                title: const Text('Geciken görev yok'),
                subtitle: const Text('Tüm görevler zamanında ilerliyor.'),
              ),
            )
          else
            for (final task in overdueTasks)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.warning_amber, color: Colors.red),
                  title: Text(task.title),
                  subtitle: Text(
                    '${task.assignee.isEmpty ? 'Atanmamış' : task.assignee} · ${task.deadlineText}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openTask(task),
                ),
              ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(label, style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final TeamMember member;

  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = member.user;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(user.name.isEmpty ? '?' : user.name[0])),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: theme.textTheme.titleMedium),
                      Text('${user.roleLabel} · @${user.username}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Text('${member.done}/${member.total}', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: member.progress, minHeight: 8),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                LabelChip(text: 'Açık: ${member.open}', color: Colors.blue),
                LabelChip(
                  text: 'Geciken: ${member.overdue}',
                  color: member.overdue > 0 ? Colors.red : Colors.grey,
                ),
                LabelChip(text: 'Tamamlanan: ${member.done}', color: Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }
}