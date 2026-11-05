import 'package:flutter/material.dart';

import 'screens/task_list_screen.dart';

void main() {
  runApp(const TaskFlowApp());
}

// Uygulamanın kök widget'ı: tema ve açılış ekranı burada belirlenir
class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false, // sağ üstteki "DEBUG" şeridini gizle
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const TaskListScreen(),
    );
  }
}