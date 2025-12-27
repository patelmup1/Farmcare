import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/sign_up_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/home/presentation/main_scaffold.dart';
import 'features/farm/presentation/add_farm_screen.dart';
import 'features/schedule/presentation/schedule_screen.dart';
import 'features/schedule/presentation/add_task_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'core/services/notification_service.dart';
import 'l10n/app_localizations.dart';
import 'core/providers.dart'; // import providers for localeProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable Immersive Mode (Hides Status Bar and Navigation Bar)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  // Initialize Local Notifications
  await NotificationService().init();
  
  // TODO: Replace these with your actual Supabase values from your project dashboard
  // Go to: Project Settings -> API
  const supabaseUrl = 'https://ditqxditwxwchdpnjpyn.supabase.co';
  const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRpdHF4ZGl0d3h3Y2hkcG5qcHluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYzOTg4MjUsImV4cCI6MjA4MTk3NDgyNX0.ZqSN0s9fAmLczzGRHWuy2v2sSFCUr5svnAJ2rWSY34M';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  // Initialize Local Notifications
  // await NotificationService().init(); // Uncomment when service is ready and imported

  runApp(const ProviderScope(child: FarmerApp()));
}

class FarmerApp extends ConsumerWidget {
  const FarmerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.watch(authRepositoryProvider);
    final initialRoute = authRepo.currentSession != null ? '/home' : '/login';
    
    // Initialize Auto-Sync
    // We use a useEffect-like pattern or just read it once.
    // However, since build can run multiple times, we need to be careful.
    // For simplicity in this structure, we can just ensure it's alive.
    // A better pattern is a separate "StartupService". 
    // Here we will just read it once in a generic way or let the Home screen init it.
    // But to ensure it runs globally, we can do:
    ref.read(syncRepositoryProvider).initialize();

    final locale = ref.watch(localeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => 'Crop Care',
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: const [
         Locale('en'),
         Locale('hi'),
         Locale('gu'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50), // Standard Green
          primary: const Color(0xFF2E7D32), // Darker Green
          secondary: const Color(0xFF81C784), // Lighter Green
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        
        // Modern Input Styling
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),

        // Modern Button Styling
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // cardTheme removed to fix type error
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const MainScaffold(),
        '/add-farm': (context) => const AddFarmScreen(),
        '/schedule': (context) => const ScheduleScreen(),
        '/add-task': (context) => const AddTaskScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
