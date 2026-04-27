import 'package:flutter/material.dart';

import 'data/log_repository.dart';
import 'screens/session_hub_screen.dart';
import 'services/export_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GymLogApp());
}

class GymLogApp extends StatelessWidget {
  const GymLogApp({super.key});

  static final _repository = LogRepository();
  static final _exportService = ExportService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Log',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
        ),
      ),
      home: SessionHubScreen(
        repository: _repository,
        exportService: _exportService,
      ),
    );
  }
}
