// Libraries & dependencies
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Custom project files
import 'home_screen_widget.dart';
import 'session_database.dart';
import 'settings_provider.dart';

import 'translation_util/translation_service.dart';

void main() async {
  // Initialize Hive database
  WidgetsFlutterBinding.ensureInitialized();

  await SessionDatabase.instance.init();

  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  runApp(ChangeNotifierProvider.value(
    value: settingsProvider,
    child: MyApp(),
  ),);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Listen to language changes
    TranslationService.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    TranslationService.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'app_title'.tr,

      // Light theme
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Dark theme
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      themeMode: Provider.of<SettingsProvider>(context).isDarkMode
        ? ThemeMode.dark
        : ThemeMode.light,

      home: const HomeScreen(),
    );
  }
}