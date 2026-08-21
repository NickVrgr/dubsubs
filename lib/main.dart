import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'screens/library_screen.dart';
import 'services/library_controller.dart';
import 'services/settings_controller.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final storage = StorageService();
  await storage.init();
  runApp(DubSubsApp(storage: storage));
}

class DubSubsApp extends StatelessWidget {
  const DubSubsApp({super.key, required this.storage});

  final StorageService storage;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibraryController(storage)),
        ChangeNotifierProvider(create: (_) => SettingsController(storage)),
      ],
      child: MaterialApp(
        title: 'DubSubs',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: const LibraryScreen(),
      ),
    );
  }
}
