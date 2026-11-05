import 'package:flutter_test/flutter_test.dart';

import 'package:taskflow_mobile/models/task.dart';

// Görev modelinin birim testleri (sunucuya bağlanmadan çalışır)
void main() {
  test('Eksik alanlı JSON güvenli varsayılan değerlerle okunur', () {
    final task = Task.fromJson({'id': '1', 'title': 'Deneme'});

    expect(task.title, 'Deneme');
    expect(task.description, '');
    expect(task.assignee, '');
    expect(task.status, TaskStatus.pending);
    expect(task.priority, TaskPriority.medium);
    expect(task.updatedAt, isNull);
  });

  test('Tam JSON doğru okunur', () {
    final task = Task.fromJson({
      'id': '01ABC',
      'title': 'Sunum hazırla',
      'description': 'README güncellenecek',
      'status': 'done',
      'priority': 3,
      'assignee': 'rana',
      'createdAt': '2026-11-05T12:00:00.000Z',
      'updatedAt': '2026-11-05T13:00:00.000Z',
    });

    expect(task.isDone, isTrue);
    expect(task.statusLabel, 'Tamamlandı');
    expect(task.priorityLabel, 'Yüksek');
    expect(task.updatedAt, isNotNull);
  });

  test('Durum ve öncelik etiketleri Türkçe', () {
    expect(TaskStatus.label(TaskStatus.pending), 'Bekliyor');
    expect(TaskStatus.label(TaskStatus.inProgress), 'Devam ediyor');
    expect(TaskStatus.label(TaskStatus.done), 'Tamamlandı');
    expect(TaskPriority.label(TaskPriority.low), 'Düşük');
    expect(TaskPriority.label(TaskPriority.medium), 'Orta');
    expect(TaskPriority.label(TaskPriority.high), 'Yüksek');
  });
}