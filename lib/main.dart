import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_user_app/core/services/background_service.dart';
import 'package:flutter_user_app/core/provider/theme_provider.dart';
import 'package:flutter_user_app/core/providers/locale_provider.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/auth/login/presentation/screens/login_page.dart';
import 'package:flutter_user_app/core/helper/auth_helper.dart';
import 'package:flutter_user_app/features/posts/presentation/providers/post_provider.dart';
import 'package:flutter_user_app/features/posts/presentation/provider/posts_provider.dart';
import 'package:flutter_user_app/features/posts/data/repository/post_repository_impl.dart';
import 'package:flutter_user_app/features/posts/domain/usecase/get_posts_usecase.dart';
import 'package:flutter_user_app/core/util/theme_scheme.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/screens/admin_main_layout.dart';
import 'package:flutter_user_app/features/home/presentation/screens/home_page.dart';
import 'core/config/app_config.dart';
import 'package:flutter_user_app/features/follow/presentation/providers/follow_provider.dart';
import 'package:flutter_user_app/core/deep_links/deep_link_handler.dart';
import 'package:flutter_user_app/features/events/presentation/providers/events_provider.dart';
import 'package:flutter_user_app/features/reels/presentation/providers/reels_provider.dart';
import 'package:flutter_user_app/features/block/presentation/providers/block_provider.dart';
import 'package:flutter_user_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter/foundation.dart'; // Required for kDebugMode

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Ensure Flutter is initialized and preserve splash screen
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Background Service if not on Web
  if (!kIsWeb) {
    // This needs to be called before runApp
    await Workmanager().initialize(
      callbackDispatcher, 
      isInDebugMode: kDebugMode // true for testing, change to false for prod
    );
    
    // Register Periodic Task
    await Workmanager().registerPeriodicTask(
      "1", 
      taskName, 
      frequency: const Duration(minutes: 15), // Minimum is 15 mins
      constraints: Constraints(
        networkType: NetworkType.connected, 
      ),
    );
  }

  // Initialize environment variables from .env file
  await AppConfig.initialize();

  // Initialize theme provider with saved preferences
  final themeProvider = await ThemeProvider.initialize();
  
  // Initialize locale provider
  final localeProvider = LocaleProvider();

  // Run the app
  runApp(
    MultiProvider(
      providers: [
        // ApiService - shared instance
        Provider<ApiService>(
          create: (_) {
            final service = ApiService.create();
            // Configure 401 Unauthorized handling
            service.onTokenExpired = () async {
              print('AUTH: Session expired. Logging out...');
              
              // Clear session data safely using AuthHelper
              await AuthHelper.clearSession();
              
              // Navigate to login using global key
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            };
            return service;
          },
          dispose: (_, apiService) => apiService.client.close(),
        ),
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
        ),
        ChangeNotifierProvider<LocaleProvider>.value(
          value: localeProvider,
        ),
        ChangeNotifierProxyProvider<ApiService, BlockProvider>(
          create: (context) {
            final provider = BlockProvider(
              Provider.of<ApiService>(context, listen: false),
            );
            provider.loadBlockList();
            return provider;
          },
          update: (context, apiService, previous) =>
              previous ?? BlockProvider(apiService),
        ),
        ChangeNotifierProxyProvider<ApiService, PostProvider>(
          create: (context) => PostProvider(
            Provider.of<ApiService>(context, listen: false),
          ),
          update: (context, apiService, previous) =>
              previous ?? PostProvider(apiService),
        ),
        ChangeNotifierProxyProvider<ApiService, FollowProvider>(
          create: (context) => FollowProvider(
            Provider.of<ApiService>(context, listen: false),
          ),
          update: (context, apiService, previous) =>
              previous ?? FollowProvider(apiService),
        ),
        ChangeNotifierProxyProvider<ApiService, EventsProvider>(
          create: (context) => EventsProvider(
            Provider.of<ApiService>(context, listen: false),
          ),
          update: (context, apiService, previous) =>
              previous ?? EventsProvider(apiService),
        ),
        ChangeNotifierProxyProvider2<ApiService, BlockProvider, ReelsProvider>(
          create: (context) => ReelsProvider(
            Provider.of<ApiService>(context, listen: false),
          ),
          update: (context, apiService, blockProvider, previous) {
            final provider = previous ?? ReelsProvider(apiService);
            provider.updateBlockedIds(blockProvider.blockedIds);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider2<ApiService, BlockProvider, PostsProvider>(
          create: (context) {
            final apiService = Provider.of<ApiService>(context, listen: false);
            final repository = PostRepositoryImpl(apiService: apiService);
            final usecase = GetPostsUsecase(repository);
            return PostsProvider(usecase, repository);
          },
          update: (context, apiService, blockProvider, previous) {
            final provider = previous ?? (() {
              final repository = PostRepositoryImpl(apiService: apiService);
              final usecase = GetPostsUsecase(repository);
              return PostsProvider(usecase, repository);
            })();
            provider.updateBlockedIds(blockProvider.blockedIds);
            return provider;
          }
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // Future for handling initialization tasks
  late Future<Widget> _initializationFuture;

  @override
  void initState() {
    super.initState();
    // Define initialization tasks that need to complete before removing splash
    _initializationFuture = _initializeApp();
  }

  // Handle all initialization tasks here
  Future<Widget> _initializeApp() async {
    // Check if user is already logged in
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');
    final userType = prefs.getString('user_type');

    // Minimum splash display time
    await Future.delayed(const Duration(milliseconds: 500));

    // Remove splash screen once everything is ready
    FlutterNativeSplash.remove();

    // Note: Deep link handler will be initialized in MainApp build method
    // after the context is available

    // Return appropriate screen based on login status
    if (authToken != null && authToken.isNotEmpty) {
      if (userType == 'Admin') {
        return const AdminMainLayout();
      } else {
        return HomePage();
      }
    }

    // Not logged in, show login page
    return const LoginPage();
  }

  // Update system UI based on current theme
  void _updateSystemUI(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, _) {
        // Update system UI whenever theme changes
        _updateSystemUI(themeProvider.themeMode);

        // Initialize deep link handler after first frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          DeepLinkHandler().initialize(context);
        });

        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 600),
          themeAnimationCurve: Curves.easeInOutCirc,
          // Localization support
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('mr'), // Marathi
            Locale('hi'), // Hindi
            Locale('gu'), // Gujarati
          ],
        // Use FutureBuilder to transition from splash to app content
        home: FutureBuilder<Widget>(
          future: _initializationFuture,
          builder: (context, snapshot) {
            // Show actual app content when initialization is complete
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
              return snapshot.data!;
            }

            // During initialization, show a minimal loading widget
            // The native splash is still visible during this time
            return const SizedBox.shrink();
          },
        ),
      );
    });
  }
}
