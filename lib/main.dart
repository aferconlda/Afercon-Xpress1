
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'auth_service.dart';
import 'client_deliveries_screen.dart';
import 'delivery_details_screen.dart';
import 'edit_profile_screen.dart';
import 'firebase_options.dart';
import 'firebase_messaging_service.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'my_deliveries_screen.dart';
import 'new_delivery_screen.dart';
import 'notifications_screen.dart';
import 'privacy_policy_screen.dart';
import 'profile_screen.dart';
import 'signup_screen.dart';
import 'terms_screen.dart';
import 'verify_email_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
  timeago.setDefaultLocale('pt_BR');

  await FirebaseMessagingService().initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(FirebaseAuth.instance),
        ),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
        ),
      ],
      child: const AferconXpressApp(),
    ),
  );
}

// --- Gerenciador de Tema ---
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

// --- App Principal ---
class AferconXpressApp extends StatelessWidget {
  const AferconXpressApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    final router = GoRouter(
      refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
            path: '/',
            name: 'login',
            builder: (context, state) => const LoginScreen()),
        GoRoute(
            path: '/signup',
            name: 'signup',
            builder: (context, state) => const SignUpScreen()),
        GoRoute(
            path: '/terms',
            name: 'terms',
            builder: (context, state) => const TermsScreen()),
        GoRoute(
            path: '/privacy',
            name: 'privacy',
            builder: (context, state) => const PrivacyPolicyScreen()),
        GoRoute(
            path: '/forgot-password',
            name: 'forgot-password',
            builder: (context, state) => const ForgotPasswordScreen()),
        GoRoute(
            path: '/verify-email',
            name: 'verify-email',
            builder: (context, state) => const VerifyEmailScreen()),
        GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen()),
        GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                  path: 'edit',
                  name: 'edit-profile',
                  builder: (context, state) => const EditProfileScreen())
            ]),
        GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen()),
        GoRoute(
            path: '/new',
            name: 'new',
            builder: (context, state) => const NewDeliveryScreen()),
        GoRoute(
            path: '/my-deliveries',
            name: 'my-deliveries',
            builder: (context, state) => const MyDeliveriesScreen()),
        GoRoute(
            path: '/client-deliveries',
            name: 'client-deliveries',
            builder: (context, state) => const ClientDeliveriesScreen()),
        GoRoute(
            path: '/details/:id',
            name: 'details',
            builder: (context, state) {
              final deliveryId = state.pathParameters['id']!;
              return DeliveryDetailsScreen(deliveryId: deliveryId);
            }),
      ],
      redirect: (context, state) {
        final user = authService.currentUser;
        final bool loggedIn = user != null;
        final bool isEmailVerified = loggedIn && user.emailVerified;
        final authRoutes = [
          '/',
          '/signup',
          '/forgot-password',
          '/terms',
          '/privacy'
        ];
        final isAuthRoute = authRoutes.contains(state.matchedLocation);
        final isVerifyRoute = state.matchedLocation == '/verify-email';

        if (loggedIn && !isEmailVerified && !isVerifyRoute) {
          return '/verify-email';
        }

        if (loggedIn && (isAuthRoute || isVerifyRoute) && isEmailVerified) {
          return '/home';
        }

        if (!loggedIn && !isAuthRoute) {
          return '/';
        }

        return null; // No redirect
      },
    );

    const Color primarySeedColor = Color(0xFF008080); // Teal

    // Define a common TextTheme
    final TextTheme appTextTheme = TextTheme(
      displayLarge: GoogleFonts.oswald(
          fontSize: 57, fontWeight: FontWeight.bold, letterSpacing: -0.25),
      headlineLarge: GoogleFonts.oswald(
          fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 0.25),
      titleLarge:
          GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w700),
      bodyLarge:
          GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.normal),
      bodyMedium:
          GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.normal),
      labelLarge:
          GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.bold),
    );

    // Light Theme
    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
      ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primarySeedColor,
        foregroundColor: Colors.white,
        titleTextStyle:
            appTextTheme.titleLarge?.copyWith(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primarySeedColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: appTextTheme.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primarySeedColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
    );

    // Dark Theme
    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.dark,
      ),
      textTheme: appTextTheme.apply(
        bodyColor: Colors.grey.shade300,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: Colors.white,
        titleTextStyle:
            appTextTheme.titleLarge?.copyWith(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primarySeedColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: appTextTheme.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF1E293B), // Dark blue-gray
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: Colors.grey.shade800),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primarySeedColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade900,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          routerConfig: router,
          title: 'Afercon Xpress',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

// Helper for GoRouter to listen to auth changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription =
        stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
