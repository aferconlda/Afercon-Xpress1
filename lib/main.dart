
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';
import 'client_deliveries_screen.dart';
import 'delivery_details_screen.dart';
import 'firebase_options.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'my_deliveries_screen.dart';
import 'new_delivery_screen.dart';
import 'privacy_policy_screen.dart'; // Importa o novo ecrã
import 'signup_screen.dart';
import 'terms_screen.dart'; // Importa o novo ecrã
import 'verify_email_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
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
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const SignUpScreen(),
        ),
        // Adiciona a rota para os Termos e Condições
        GoRoute(
          path: '/terms',
          name: 'terms',
          builder: (context, state) => const TermsScreen(),
        ),
        // Adiciona a rota para a Política de Privacidade
        GoRoute(
          path: '/privacy',
          name: 'privacy',
          builder: (context, state) => const PrivacyPolicyScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/verify-email',
          name: 'verify-email',
          builder: (context, state) => const VerifyEmailScreen(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/new',
          name: 'new',
          builder: (context, state) => const NewDeliveryScreen(),
        ),
        GoRoute(
          path: '/my-deliveries',
          name: 'my-deliveries',
          builder: (context, state) => const MyDeliveriesScreen(),
        ),
        GoRoute(
          path: '/client-deliveries',
          name: 'client-deliveries',
          builder: (context, state) => const ClientDeliveriesScreen(),
        ),
        GoRoute(
          path: '/details/:id',
          name: 'details',
          builder: (context, state) {
            final deliveryId = state.pathParameters['id']!;
            return DeliveryDetailsScreen(deliveryId: deliveryId);
          },
        ),
      ],
      redirect: (context, state) {
        final user = authService.currentUser;
        final bool loggedIn = user != null;
        final bool isEmailVerified = loggedIn && user.emailVerified;

        final authRoutes = ['/', '/signup', '/forgot-password', '/terms', '/privacy'];
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

        return null; // Sem redirecionamento
      },
    );

    const Color primaryColor = Color(0xFF008080); // Azul Petróleo
    const Color accentColor = Color(0xFF00C853);  // Verde Vibrante

    final textTheme = GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: textTheme.headlineMedium?.copyWith(color: Colors.white),
      ),
       elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        brightness: Brightness.dark,
      ),
      textTheme: textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: Colors.white,
        titleTextStyle: textTheme.headlineMedium?.copyWith(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Color(0xFF1F2937),
      ),
       cardTheme: const CardThemeData(
        elevation: 3,
        color: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

// Helper para o GoRouter ouvir as alterações de autenticação
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
