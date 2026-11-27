import 'package:flutter/material.dart';
import '../main.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../widgets/task_badges.dart';
import 'admin_panel_screen.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final ApiService _api = ApiService();

  List<Task> _tasks = [];
  bool _loading = true;
  ApiException? _error;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadTasks(initial: true);
  }

  Future<void> _loadTasks({bool initial = false}) async {
    if (!initial) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final tasks = await _api.getTasks();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } on ApiException catch (e) {
      _handleLoadError(e);
    } catch (e) {
      _handleLoadError(ApiException('Beklenmeyen bir hata oluştu.', [e.toString()]));
    }
  }

  void _handleLoadError(ApiException e) {
    if (!mounted) return;
    setState(() {
      _error = e;
      _loading = false;
    });
    if (_tasks.isNotEmpty) {
      _showMessage(e.fullMessage, isError: true);
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

  Future<bool> _confirmAndDelete(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Görevi sil'),
        content: Text('"${task.title}" silinsin mi? Bu işlem geri alınamaz.'),
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

    if (confirmed != true) return false;

    try {
      await _api.deleteTask(task.id);
      if (!mounted) return false;
      _showMessage('"${task.title}" silindi');
      return true;
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.fullMessage, isError: true);
      return false;
    }
  }

  Future<void> _openDetail(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
    );
    if (!mounted) return;
    _loadTasks();
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => const TaskFormScreen()),
    );
    if (!mounted || created == null) return;
    setState(() => _statusFilter = null);
    _loadTasks();
  }

  Future<void> _openAdminPanel() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
    );
    if (!mounted) return;
    _loadTasks();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Çıkış yap'),
        content: const Text('Hesabından çıkış yapılsın mı?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Çıkış yap'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await Session.logout();
    }
  }

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TaskFlow'),
            if (Session.user != null)
              Text(
                '${Session.user!.name} · ${Session.user!.roleLabel}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          if (Session.isCeo)
            IconButton(
              tooltip: 'Ekip paneli',
              icon: const Icon(Icons.groups_outlined),
              onPressed: _openAdminPanel,
            ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeModeNotifier,
            builder: (context, mode, _) => PopupMenuButton<ThemeMode>(
              tooltip: 'Tema',
              icon: Icon(_themeIcon(mode)),
              initialValue: mode,
              onSelected: (selected) => themeModeNotifier.value = selected,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: ThemeMode.system,
                  child: ListTile(
                    leading: Icon(Icons.brightness_auto),
                    title: Text('Sistem'),
                  ),
                ),
                PopupMenuItem(
                  value: ThemeMode.light,
                  child: ListTile(
                    leading: Icon(Icons.light_mode),
                    title: Text('Açık'),
                  ),
                ),
                PopupMenuItem(
                  value: ThemeMode.dark,
                  child: ListTile(
                    leading: Icon(Icons.dark_mode),
                    title: Text('Koyu'),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : () => _loadTasks(),
          ),
          IconButton(
            tooltip: 'Çıkış yap',
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: Session.isCeo
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
              label: const Text('Yeni görev'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading && _tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _tasks.isEmpty) {
      return _MessageView(
        icon: Icons.cloud_off,
        title: _error!.message,
        details: _error!.details,
        buttonText: 'Tekrar dene',
        onPressed: () => _loadTasks(),
      );
    }

    if (_tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadTasks(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            _MessageView(
              icon: Icons.inbox_outlined,
              title: Session.isCeo ? 'Henüz görev yok' : 'Sana atanmış görev yok',
              details: [
                Session.isCeo
                    ? 'Sağ alttaki "Yeni görev" butonuyla ilk görevi ekle.'
                    : 'Yöneticin sana görev atadığında burada görünecek.',
              ],
            ),
          ],
        ),
      );
    }

    final visibleTasks = _statusFilter == null
        ? _tasks
        : _tasks.where((t) => t.status == _statusFilter).toList();

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadTasks(),
            child: visibleTasks.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      _MessageView(
                        icon: Icons.filter_alt_off_outlined,
                        title: '"${TaskStatus.label(_statusFilter!)}" durumunda görev yok',
                        details: const ['Başka bir filtre seç ya da "Tümü"ne dön.'],
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                    itemCount: visibleTasks.length,
                    itemBuilder: (context, index) => _buildTaskCard(visibleTasks[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    Widget chip(String label, String? value) {
      final count = value == null
          ? _tasks.length
          : _tasks.where((t) => t.status == value).length;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text('$label ($count)'),
          selected: _statusFilter == value,
          onSelected: (_) => setState(() => _statusFilter = value),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          chip('Tümü', null),
          for (final status in TaskStatus.values) chip(TaskStatus.label(status), status),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(task.id),
      direction: Session.isCeo ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (_) => _confirmAndDelete(task),
      onDismissed: (_) => setState(() => _tasks.removeWhere((t) => t.id == task.id)),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openDetail(task),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  task.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: statusColor(task.status),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration: task.isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusChip(status: task.status),
                          PriorityChip(priority: task.priority),
                          if (task.deadline != null) DeadlineChip(task: task),
                          if (task.assignee.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(task.assignee, style: theme.textTheme.bodySmall),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> details;
  final String? buttonText;
  final VoidCallback? onPressed;

  const _MessageView({
    required this.icon,
    required this.title,
    this.details = const [],
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            for (final line in details) ...[
              const SizedBox(height: 6),
              Text(
                line,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.refresh),
                label: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}