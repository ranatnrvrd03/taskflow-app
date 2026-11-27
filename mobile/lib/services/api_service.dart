import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/task.dart';
import '../models/user.dart';
import 'session.dart';

class ApiException implements Exception {
  final String message;
  final List<String> details;
  final int? statusCode;

  ApiException(this.message, [this.details = const [], this.statusCode]);

  bool get isUnauthorized => statusCode == 401;

  String get fullMessage =>
      details.isEmpty ? message : '$message\n${details.join('\n')}';

  @override
  String toString() => fullMessage;
}

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=utf-8',
        if (Session.token != null) 'Authorization': 'Bearer ${Session.token}',
      };

  Uri _uri(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request) async {
    final http.Response response;

    try {
      response = await request().timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw ApiException('Sunucu yanıt vermedi (zaman aşımı).', [
        'İnternet bağlantınızı kontrol edip tekrar deneyin.',
      ]);
    } on SocketException {
      throw ApiException('Sunucuya bağlanılamadı.', [
        'Adres: ${AppConfig.baseUrl}',
        'İnternet bağlantınızı kontrol edip tekrar deneyin.',
      ]);
    } on http.ClientException {
      throw ApiException('Sunucuya bağlanılamadı.', ['Adres: ${AppConfig.baseUrl}']);
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Sunucudan beklenmeyen bir yanıt geldi (kod: ${response.statusCode}).',
        const [],
        response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = (body['message'] as String?) ?? 'Bilinmeyen hata (kod: ${response.statusCode})';
    final errors = (body['errors'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];

    if (response.statusCode == 401 && Session.isLoggedIn) {
      await Session.logout();
    }

    throw ApiException(message, errors, response.statusCode);
  }

  Future<({String token, AppUser user})> login(String username, String password) async {
    final payload = jsonEncode({'username': username, 'password': password});
    final body = await _send(() => _client.post(_uri('/auth/login'), headers: _headers, body: payload));
    return (
      token: body['token'] as String,
      user: AppUser.fromJson(body['user'] as Map<String, dynamic>),
    );
  }

  Future<List<TeamMember>> getUsers() async {
    final body = await _send(() => _client.get(_uri('/users'), headers: _headers));
    final list = (body['users'] as List?) ?? [];
    return list.map((json) => TeamMember.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Task>> getTasks() async {
    final body = await _send(() => _client.get(_uri('/tasks'), headers: _headers));
    final list = (body['tasks'] as List?) ?? [];
    return list.map((json) => Task.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Task> getTask(String id) async {
    final body = await _send(() => _client.get(_uri('/tasks/$id'), headers: _headers));
    return Task.fromJson(body['task'] as Map<String, dynamic>);
  }

  Future<Task> createTask({
    required String title,
    required String description,
    required int priority,
    String? assigneeId,
    String? deadline,
  }) async {
    final payload = jsonEncode({
      'title': title,
      'description': description,
      'priority': priority,
      'assigneeId': assigneeId,
      'deadline': deadline,
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
    final body = await _send(() => _client.delete(_uri('/tasks/$id'), headers: _headers));
    return Task.fromJson(body['task'] as Map<String, dynamic>);
  }
}