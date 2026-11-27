import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/session.dart';
import 'task_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _demoAccounts = [
    ('rana', 'Ceo.2026', 'Rana Tanrıverdi', 'CEO'),
    ('ayse', 'Calisan.2026', 'Ayşe Yılmaz', 'Çalışan'),
    ('mehmet', 'Calisan.2026', 'Mehmet Demir', 'Çalışan'),
    ('zeynep', 'Calisan.2026', 'Zeynep Kaya', 'Çalışan'),
  ];

  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String text) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(text), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  void _fillDemo(String username, String password) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
    });
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final result = await _api.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      await Session.save(result.token, result.user);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const TaskListScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(e.fullMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.task_alt, size: 72, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'TaskFlow',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ekibinin görevleri tek yerde',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _usernameController,
                      enabled: !_loading,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: 'Kullanıcı adı',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Kullanıcı adı zorunludur' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_loading,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _loading ? null : _login(),
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Şifreyi göster' : 'Şifreyi gizle',
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Şifre zorunludur' : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _loading ? null : _login,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(_loading ? 'Giriş yapılıyor...' : 'Giriş yap'),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: ExpansionTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Demo hesaplar'),
                        subtitle: const Text('Doldurmak için birine dokun'),
                        children: [
                          for (final account in _demoAccounts)
                            ListTile(
                              dense: true,
                              enabled: !_loading,
                              leading: Icon(
                                account.$4 == 'CEO' ? Icons.workspace_premium_outlined : Icons.badge_outlined,
                              ),
                              title: Text('${account.$3} · ${account.$4}'),
                              subtitle: Text('${account.$1} / ${account.$2}'),
                              onTap: () => _fillDemo(account.$1, account.$2),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}