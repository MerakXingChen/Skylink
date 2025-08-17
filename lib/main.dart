import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'theme/index.dart';
import 'routes/app_routes.dart';
import 'providers/index.dart';
import 'models/index.dart';
import 'services/index.dart';
import 'utils/index.dart';
import 'generated/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive adapters
  _registerHiveAdapters();
  
  // Initialize Isar database
  await _initializeIsar();
  
  // Initialize services
  await _initializeServices();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(
    const ProviderScope(
      child: SkyLinkApp(),
    ),
  );
}

void _registerHiveAdapters() {
  // Register all Hive type adapters
  Hive.registerAdapter(ServerAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(AIConfigAdapter());
  Hive.registerAdapter(SyncConfigAdapter());
  Hive.registerAdapter(PrivateKeyAdapter());
  Hive.registerAdapter(SSHSessionAdapter());
  Hive.registerAdapter(ServerPreviewMetricsAdapter());
  Hive.registerAdapter(WidgetLayoutAdapter());
  Hive.registerAdapter(WindowStateAdapter());
  
  // Register enum adapters
  Hive.registerAdapter(AuthTypeAdapter());
  Hive.registerAdapter(ServerStatusAdapter());
  Hive.registerAdapter(ConnectionStatusAdapter());
  Hive.registerAdapter(AIProviderAdapter());
  Hive.registerAdapter(SyncProviderAdapter());
  Hive.registerAdapter(ThemeModeAdapter());
  Hive.registerAdapter(LanguageAdapter());
  Hive.registerAdapter(TerminalFontFamilyAdapter());
  Hive.registerAdapter(WidgetTypeAdapter());
  Hive.registerAdapter(WindowTypeAdapter());
}

Future<void> _initializeIsar() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        ServerSchema,
        AppSettingsSchema,
        AIConfigSchema,
        SyncConfigSchema,
        PrivateKeySchema,
        SSHSessionSchema,
        ServerPreviewMetricsSchema,
        WidgetLayoutSchema,
        WindowStateSchema,
      ],
      directory: dir.path,
      name: 'skylink',
    );
    
    // Store Isar instance globally for services
    IsarService.initialize(isar);
  } catch (e) {
    debugPrint('Failed to initialize Isar: $e');
    // Continue without Isar - fallback to Hive only
  }
}

Future<void> _initializeServices() async {
  try {
    // Initialize core services
    await HiveService.initialize();
    await SecureStorageService.initialize();
    await LoggingService.initialize();
    
    // Initialize other services
    await MonitoringService.initialize();
    await SyncService.initialize();
    
    debugPrint('All services initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize services: $e');
    // Continue with limited functionality
  }
}

class SkyLinkApp extends ConsumerWidget {
  const SkyLinkApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final appSettings = ref.watch(appSettingsProvider);
    
    return MaterialApp.router(
      title: 'SkyLink SSH',
      debugShowCheckedModeBanner: false,
      
      // Router configuration
      routerConfig: router,
      
      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _getThemeMode(appSettings.themeMode),
      
      // Localization configuration
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: _getLocale(appSettings.language),
      
      // Builder for additional configuration
      builder: (context, child) {
        return MediaQuery(
          // Ensure text scaling doesn't break the UI
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
  
  ThemeMode _getThemeMode(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return ThemeMode.light;
      case ThemeMode.dark:
        return ThemeMode.dark;
      case ThemeMode.system:
      default:
        return ThemeMode.system;
    }
  }
  
  Locale? _getLocale(Language language) {
    switch (language) {
      case Language.english:
        return const Locale('en');
      case Language.chinese:
        return const Locale('zh');
      case Language.system:
      default:
        return null; // Use system locale
    }
  }
}

/// Global error handler
class GlobalErrorHandler {
  static void initialize() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      LoggingService.logError(
        'Flutter Error',
        details.exception,
        details.stack,
      );
    };
    
    // Handle other errors
    PlatformDispatcher.instance.onError = (error, stack) {
      LoggingService.logError('Platform Error', error, stack);
      return true;
    };
  }
}

/// App lifecycle handler
class AppLifecycleHandler extends WidgetsBindingObserver {
  static final AppLifecycleHandler _instance = AppLifecycleHandler._internal();
  factory AppLifecycleHandler() => _instance;
  AppLifecycleHandler._internal();
  
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }
  
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.inactive:
        _onAppInactive();
        break;
      case AppLifecycleState.hidden:
        _onAppHidden();
        break;
    }
  }
  
  void _onAppResumed() {
    debugPrint('App resumed');
    // Reconnect SSH sessions if needed
    SSHService.instance.resumeConnections();
    // Resume monitoring
    MonitoringService.instance.resume();
  }
  
  void _onAppPaused() {
    debugPrint('App paused');
    // Pause monitoring to save battery
    MonitoringService.instance.pause();
    // Save current state
    HiveService.instance.saveAll();
  }
  
  void _onAppDetached() {
    debugPrint('App detached');
    // Clean up resources
    _cleanup();
  }
  
  void _onAppInactive() {
    debugPrint('App inactive');
    // Reduce background activity
  }
  
  void _onAppHidden() {
    debugPrint('App hidden');
    // Handle app being hidden (iOS specific)
  }
  
  void _cleanup() {
    // Close all SSH connections
    SSHService.instance.disconnectAll();
    // Stop all services
    MonitoringService.instance.stop();
    SyncService.instance.stop();
    // Close databases
    HiveService.instance.close();
    IsarService.instance.close();
  }
}

/// Memory management helper
class MemoryManager {
  static void initialize() {
    // Monitor memory usage and clean up when needed
    _startMemoryMonitoring();
  }
  
  static void _startMemoryMonitoring() {
    // This would be implemented with platform-specific code
    // For now, just log memory warnings
    debugPrint('Memory monitoring initialized');
  }
  
  static void clearCaches() {
    // Clear image caches
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    
    // Clear other caches
    debugPrint('Caches cleared');
  }
  
  static void optimizeMemory() {
    // Force garbage collection
    // Note: This is generally not recommended in production
    // but can be useful for debugging memory issues
    debugPrint('Memory optimization requested');
  }
}