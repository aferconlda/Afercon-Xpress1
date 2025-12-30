
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';
import 'chat_screen.dart';
import 'client_deliveries_screen.dart';
import 'delivery_details_screen.dart';
import 'details_screen.dart';
import 'edit_profile_screen.dart';
import 'firebase_options.dart';
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
import 'theme_provider.dart';
import 'verify_email_screen.dart';

void main() async {
  // Envolve a app numa "zona" que captura todos os erros não tratados.
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Tenta inicializar o Firebase e ignora o erro se já estiver inicializado (comum em hot restarts).
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') {
        // Se o erro for outro que não "duplicate-app", lança-o.
        rethrow;
      }
    }

    // Configuração do Crashlytics para capturar erros do Flutter e erros assíncronos.
    FlutterError.onError = (errorDetails) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(errorDetails);
      } else {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      }
    };

    // Captura erros que acontecem fora do framework Flutter (ex: código assíncrono).
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    runApp(const MyApp());
    
  }, (error, stack) {
    // Este é o "apanhador" final da zona. Envia qualquer outro erro para o Crashlytics.
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(FirebaseAuth.instance),
        ),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: const MaterialAppRouter(),
    );
  }
}

class MaterialAppRouter extends StatelessWidget {
  const MaterialAppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    final router = GoRouter(
      initialLocation: '/login',
      refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
      redirect: (context, state) {
        final user = authService.currentUser;
        final isAuth = user != null;
        final isVerified = user?.emailVerified ?? false;

        final loggingIn = state.matchedLocation == '/login';
        final signingUp = state.matchedLocation == '/signup';
        final forgotPassword = state.matchedLocation == '/forgot-password';
        final terms = state.matchedLocation == '/terms';
        final privacy = state.matchedLocation == '/privacy-policy';

        final unauthenticatedRoutes =
            loggingIn || signingUp || forgotPassword || terms || privacy;

        if (!isAuth) {
          return unauthenticatedRoutes ? null : '/login';
        }

        if (isAuth && !isVerified) {
          return state.matchedLocation == '/verify-email' ? null : '/verify-email';
        }

        if (isAuth && isVerified && (loggingIn || signingUp)) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/verify-email',
          builder: (context, state) => const VerifyEmailScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/new-delivery',
          builder: (context, state) => const NewDeliveryScreen(),
        ),
        GoRoute(
          path: '/delivery-details/:id',
          builder: (context, state) =>
              DeliveryDetailsScreen(deliveryId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/details/:id',
          builder: (context, state) =>
              DetailsScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/my-deliveries',
          builder: (context, state) => const MyDeliveriesScreen(),
        ),
        GoRoute(
          path: '/client-deliveries',
          builder: (context, state) => const ClientDeliveriesScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => const EditProfileScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/chat/:deliveryId',
          builder: (context, state) =>
              ChatScreen(deliveryId: state.pathParameters['deliveryId']!),
        ),
        GoRoute(
          path: '/terms',
          builder: (context, state) => const TermsScreen(),
        ),
        GoRoute(
          path: '/privacy-policy',
          builder: (context, state) => const PrivacyPolicyScreen(),
        ),
      ],
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          title: 'Afercon Xpress',
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData.dark(),
          routerConfig: router,
        );
      },
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.asBroadcastStream().listen((_) => notifyListeners());
  }
}
