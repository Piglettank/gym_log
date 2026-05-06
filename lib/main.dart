import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/log_repository.dart';
import 'firebase_options.dart';
import 'screens/session_hub_screen.dart';
import 'services/sync_service.dart';
import 'widgets/wear_screen_preview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const GymLogApp());
}

class GymLogApp extends StatelessWidget {
  const GymLogApp({super.key});

  static final _repository = LogRepository();
  static final _syncService = SyncService();

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
      builder: (context, child) {
        return WearScreenPreview(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: SessionHubScreen(
        repository: _repository,
        syncService: _syncService,
      ),
    );
  }
}
