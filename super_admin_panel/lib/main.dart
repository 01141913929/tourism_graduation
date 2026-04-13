import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'providers/admin_auth_provider.dart';
import 'providers/admin_data_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // تهيئة اللغة العربية للتواريخ
  await initializeDateFormatting('ar', null);

  runApp(const SuperAdminApp());
}

class SuperAdminApp extends StatelessWidget {
  const SuperAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminDataProvider()),
      ],
      child: MaterialApp(
        title: 'Super Admin Panel',
        debugShowCheckedModeBanner: false,

        // استخدام نظام الثيم الجديد
        theme: AppTheme.lightTheme,

        // اتجاه RTL للغة العربية
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },

        home: Consumer<AdminAuthProvider>(
          builder: (context, auth, _) {
            if (auth.isAuthenticated && auth.isSuperAdmin) {
              return const DashboardScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
