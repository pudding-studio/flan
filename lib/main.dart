import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'platform/database_factory_init.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/character/character_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/chat_model_provider.dart';
import 'providers/localization_provider.dart';
import 'providers/tokenizer_provider.dart';
import 'providers/viewer_settings_provider.dart';
import 'providers/community_model_provider.dart';
import 'providers/diary_model_provider.dart';
import 'database/database_helper.dart';
import 'services/default_seeder_service.dart';
import 'screens/tutorial/tutorial_screen.dart';

// Firebase + Crashlytics are only wired up for mobile and web.
// Desktop (Windows/Linux/macOS) has no firebase_options entry and
// firebase_crashlytics does not support those platforms.
bool get _isFirebaseSupported {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

void main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Web uses sqflite_common_ffi_web (IndexedDB-backed SQLite WASM); native is no-op.
    initDatabaseFactoryForPlatform();

    if (_isFirebaseSupported) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // Crashlytics — mobile only (package does not support web/desktop).
    if (_isFirebaseSupported && !kIsWeb) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    }

    // Seed default data on first launch
    await DefaultSeederService().seedAllDefaults();

    // Delete API logs older than 7 days
    await DatabaseHelper.instance.deleteOldChatLogs();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocalizationProvider()),
          ChangeNotifierProvider(create: (_) => ChatModelSettingsProvider()),
          ChangeNotifierProvider(create: (_) => TokenizerProvider()),
          ChangeNotifierProvider(create: (_) => ViewerSettingsProvider()),
          ChangeNotifierProvider(create: (_) => CommunityModelProvider()),
          ChangeNotifierProvider(create: (_) => DiaryModelProvider()),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    if (_isFirebaseSupported && !kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
  });
}

// On desktop, cap content width to window height so landscape windows
// show a centered square with black letterboxing on the sides.
class _DesktopAspectLock extends StatelessWidget {
  const _DesktopAspectLock({required this.child});

  final Widget? child;

  bool get _isDesktop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    final content = child ?? const SizedBox.shrink();
    if (!_isDesktop) return content;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Target content aspect ratio: width 4, height 6.
        final targetWidth = constraints.maxHeight * 4 / 6;
        if (constraints.maxWidth <= targetWidth) return content;
        return ColoredBox(
          color: Colors.white,
          child: Center(
            child: SizedBox(
              width: targetWidth,
              height: constraints.maxHeight,
              child: content,
            ),
          ),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocalizationProvider>(
      builder: (context, themeProvider, l10nProvider, child) {
        return MaterialApp(
          title: 'Flan',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(
            seedColor: themeProvider.seedColor,
            brightness: Brightness.light,
          ),
          darkTheme: AppTheme.getTheme(
            seedColor: themeProvider.seedColor,
            brightness: Brightness.dark,
          ),
          themeMode: themeProvider.themeMode,
          locale: l10nProvider.effectiveLocale,
          supportedLocales: LocalizationProvider.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => _DesktopAspectLock(child: child),
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
  bool? _tutorialCompleted;

  final List<Widget> _screens = const [
    CharacterScreen(),
    ChatScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkTutorial();
  }

  Future<void> _checkTutorial() async {
    final completed = await isTutorialCompleted();
    if (mounted) {
      setState(() => _tutorialCompleted = completed);
    }
  }

  void _onTutorialComplete() {
    setState(() {
      _tutorialCompleted = true;
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_tutorialCompleted == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_tutorialCompleted == false) {
      return TutorialScreen(onComplete: _onTutorialComplete);
    }
    final l10n = AppLocalizations.of(context);
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
              label: l10n.navCharacter,
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
              label: l10n.navChat,
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
              label: l10n.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
