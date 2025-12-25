import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'auth_service.dart';
import 'chat_screen.dart';
import 'client_deliveries_screen.dart';
import 'delivery_details_screen.dart';
import 'edit_profile_screen.dart';
import 'firebase_messaging_service.dart';
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
import 'verify_email_screen.dart';

// Classe para gerir o estado do tema
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseMessagingService().initialize();
  timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<AuthService>(
          create: (_) => AuthService(FirebaseAuth.instance),
        ),
        // O StreamProvider agora é usado implicitamente pelo StreamBuilder abaixo
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos um StreamBuilder para esperar pelo estado inicial de autenticação
    return StreamBuilder<User?>(
      stream: context.read<AuthService>().authStateChanges,
      builder: (context, snapshot) {
        // Enquanto esperamos pela primeira resposta do Firebase Auth, mostramos uma tela de carregamento
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        // Quando o estado de autenticação é conhecido, construímos o app com o roteador
        return const AppRouter();
      },
    );
  }
}

// Widget que contém a lógica do roteador e da MaterialApp
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    final router = GoRouter(
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
      redirect: (BuildContext context, GoRouterState state) {
        final authService = context.read<AuthService>();
        final bool loggedIn = authService.currentUser != null;

        final publicPages = [
          '/login',
          '/signup',
          '/forgot-password',
          '/terms',
          '/privacy-policy'
        ];
        final isPublicPage = publicPages.contains(state.matchedLocation);

        if (!loggedIn && !isPublicPage) {
          return '/login';
        }

        if (loggedIn && (isPublicPage || state.matchedLocation == '/verify-email')) {
           if (authService.currentUser!.emailVerified) {
             return '/';
           }
        }
        
        if (loggedIn && !authService.currentUser!.emailVerified && state.matchedLocation != '/verify-email') {
          return '/verify-email';
        }

        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'delivery-details/:deliveryId',
              builder: (context, state) {
                final deliveryId = state.pathParameters['deliveryId']!;
                return DeliveryDetailsScreen(deliveryId: deliveryId);
              },
            ),
             GoRoute(
              path: 'details/:deliveryId',
              builder: (context, state) {
                final deliveryId = state.pathParameters['deliveryId']!;
                return DeliveryDetailsScreen(deliveryId: deliveryId);
              },
            ),
            GoRoute(
              path: 'chat/:deliveryId',
              builder: (context, state) {
                final deliveryId = state.pathParameters['deliveryId']!;
                return ChatScreen(deliveryId: deliveryId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/client-deliveries',
          builder: (context, state) => const ClientDeliveriesScreen(),
        ),
        GoRoute(
          path: '/my-deliveries',
          builder: (context, state) => const MyDeliveriesScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => const EditProfileScreen(),
              ),
            ]),
        GoRoute(
          path: '/new-delivery',
          builder: (context, state) => const NewDeliveryScreen(),
        ),
        GoRoute(
          path: '/verify-email',
          builder: (context, state) => const VerifyEmailScreen(),
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
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          themeMode: themeProvider.themeMode,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}