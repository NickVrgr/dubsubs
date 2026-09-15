import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'screens/library_screen.dart';
import 'screens/player_screen.dart';
import 'services/incoming_file_service.dart';
import 'services/library_controller.dart';
import 'services/settings_controller.dart';
import 'services/srt_import.dart';
import 'services/storage_service.dart';

/// Lets [_handleIncomingFiles] navigate and read providers without needing a
/// [BuildContext] of its own.
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final storage = StorageService();
  await storage.init();
  runApp(DubSubsApp(storage: storage));
  WidgetsBinding.instance.addPostFrameCallback((_) => _handleIncomingFiles());
}

/// Wires up the "open with DubSubs" integration: imports .srt files the OS
/// hands to the app, whether the app was launched by opening one (cold
/// start) or one was opened while it was already running.
void _handleIncomingFiles() {
  IncomingFileService.listen(_importIncomingFile);
  IncomingFileService.takeInitialFile().then((file) {
    if (file != null) _importIncomingFile(file);
  });
}

Future<void> _importIncomingFile(IncomingFile file) async {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  final library = context.read<LibraryController>();
  final result = await importSrtBytes(library: library, fileName: file.name, bytes: file.bytes);

  final currentContext = navigatorKey.currentContext;
  if (currentContext == null) return;
  if (result.document != null) {
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => PlayerScreen(document: result.document!)));
  } else {
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(currentContext).showSnackBar(SnackBar(content: Text(result.errorMessage!)));
  }
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
        navigatorKey: navigatorKey,
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
