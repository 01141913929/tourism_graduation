import 'package:egyptian_tourism_app/app/app_shell.dart';
import 'package:egyptian_tourism_app/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'providers/app_state.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Language Provider
  final languageProvider = LanguageProvider();
  await languageProvider.initialize();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(EgyptianTourismApp(languageProvider: languageProvider));
}

class EgyptianTourismApp extends StatelessWidget {
  final LanguageProvider languageProvider;

  const EgyptianTourismApp({super.key, required this.languageProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, AppState>(
          create: (_) => AppState(),
          update: (_, authProvider, appState) {
            appState?.setAuthProvider(authProvider);
            return appState ?? AppState();
          },
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, langProvider, _) {
          return MaterialApp(
            title: 'Bazar',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,

            // Dynamic Locale based on LanguageProvider
            locale: langProvider.locale,
            supportedLocales: const [
              Locale('ar', 'EG'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // Dynamic text direction based on language
            builder: (context, child) {
              return Directionality(
                textDirection: langProvider.textDirection,
                child: child!,
              );
            },

            // Start with SplashScreen for auth flow
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
