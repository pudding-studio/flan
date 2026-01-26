import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/character/character_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/chat_model_provider.dart';

void main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Crashlytics 설정
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => ChatModelSettingsProvider()),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Flan',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CharacterScreen(),
    ChatScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.surfaceContainer,
        padding: const EdgeInsets.only(bottom: AppTheme.navBarBottomPadding),
        child: NavigationBar(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          // 필수 파라미터
          selectedIndex: _currentIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: Transform.translate(
                offset: const Offset(0, AppTheme.navBarIconOffset),
                child: const Icon(Icons.person_outline),
              ),
              selectedIcon: Transform.translate(
                offset: const Offset(0, AppTheme.navBarIconOffset),
                child: const Icon(Icons.person),
              ),
              label: '캐릭터',
            ),
            NavigationDestination(
              icon: Transform.translate(
                offset: const Offset(0, AppTheme.navBarIconOffset),
                child: const Icon(Icons.chat_bubble_outline),
              ),
              selectedIcon: Transform.translate(
                offset: const Offset(0, AppTheme.navBarIconOffset),
                child: const Icon(Icons.chat_bubble),
              ),
              label: '채팅',
            ),
            NavigationDestination(
              icon: Transform.translate(
                offset: const Offset(0, AppTheme.navBarIconOffset),
                child: const Icon(Icons.settings_outlined),
              ),
              selectedIcon: Transform.translate(
                offset: const Offset(0, AppTheme.navBarIconOffset),
                child: const Icon(Icons.settings),
              ),
              label: '설정',
            ),
          ],
        ),
      ),
    );
  }
}
