import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_user_app/core/provider/theme_provider.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/auth/login/presentation/screens/login_page.dart';
import 'package:flutter_user_app/features/posts/presentation/providers/post_provider.dart';
import 'package:flutter_user_app/core/util/theme_scheme.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/screens/admin_main_layout.dart';
import 'package:flutter_user_app/features/home/presentation/screens/home_page.dart';
import 'core/config/app_config.dart';

void main() async {
  // Ensure Flutter is initialized and preserve splash screen
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize environment variables from .env file
  await AppConfig.initialize();

  // Initialize theme provider with saved preferences
  final themeProvider = await ThemeProvider.initialize();

  // Run the app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
        ),
        ChangeNotifierProvider<PostProvider>(
          create: (_) => PostProvider(ApiService.create()),
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
    return Consumer<ThemeProvider>(builder: (context, themeProvider, _) {
      // Update system UI whenever theme changes
      _updateSystemUI(themeProvider.themeMode);

      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeProvider.themeMode,
        themeAnimationDuration: const Duration(milliseconds: 600),
        themeAnimationCurve: Curves.easeInOutCirc,
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
