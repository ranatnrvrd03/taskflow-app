import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/task.dart';

class ApiException implements Exception {
  final String message;
  final List<String> details;

  ApiException(this.message, [this.details = const []]);

  String get fullMessage =>
      details.isEmpty ? message : '$message\n${details.join('\n')}';

  @override
  String toString() => fullMessage;
}

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=utf-8',
  };

  Uri _uri(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request) async {
    final http.Response response;

    try {
      response = await request().timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw ApiException('Sunucu yanıt vermedi (zaman aşımı).', [
        'Sunucunun açık olduğundan ve telefonla bilgisayarın aynı ağda olduğundan emin olun.',
      ]);
    } on SocketException {
      throw ApiException('Sunucuya bağlanılamadı.', [
        'Adres: ${AppConfig.baseUrl}',
        'Sunucunun açık olduğundan ve telefonla bilgisayarın aynı ağda olduğundan emin olun.',
      ]);
    } on http.ClientException {
      throw ApiException('Sunucuya bağlanılamadı.', ['Adres: ${AppConfig.baseUrl}']);
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Sunucudan beklenmeyen bir yanıt geldi (kod: ${response.statusCode}).');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = (body['message'] as String?) ?? 'Bilinmeyen hata (kod: ${response.statusCode})';
    final errors = (body['errors'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    throw ApiException(message, errors);
  }

  Future<String> checkConnection() async {
    final body = await _send(() => _client.get(_uri('/')));
    return (body['message'] as String?) ?? 'Sunucu çalışıyor';
  }

  Future<List<Task>> getTasks() async {
    final body = await _send(() => _client.get(_uri('/tasks')));
    final list = (body['tasks'] as List?) ?? [];
    return list.map((json) => Task.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Task> getTask(String id) async {
    final body = await _send(() => _client.get(_uri('/tasks/$id')));
    return Task.fromJson(body['task'] as Map<String, dynamic>);
  }

  Future<Task> createTask({
    required String title,
    required String description,
    required int priority,
    required String assignee,
  }) async {
    final payload = jsonEncode({
      'title': title,
      'description': description,
      'priority': priority,
      'assignee': assignee,
    });
    final body = await _send(() => _client.post(_uri('/tasks'), headers: _headers, body: payload));
    return Task.fromJson(body['task'] as Map<String, dynamic>);
  }

  Future<Task> updateTask(String id, Map<String, dynamic> changes) async {
    final payload = jsonEncode(changes);
    final body = await _send(() => _client.patch(_uri('/tasks/$id'), headers: _headers, body: payload));
    return Task.fromJson(body['task'] as Map<String, dynamic>);
  }

  Future<Task> updateStatus(String id, String status) => updateTask(id, {'status': status});

  Future<Task> deleteTask(String id) async {
    final body = await _send(() => _client.delete(_uri('/tasks/$id')));
    return Task.fromJson(body['task'] as Map<String, dynamic>);
  }
}