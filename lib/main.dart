import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rotina_comercial/api/client.dart';
import 'package:rotina_comercial/auth/auth_provider.dart';
import 'package:rotina_comercial/hooks/departments_controller.dart';
import 'package:rotina_comercial/screens/login_screen.dart';
import 'package:rotina_comercial/screens/login_token_screen.dart';
import 'package:rotina_comercial/screens/login_webview_screen.dart';
import 'package:rotina_comercial/screens/main_screen.dart';
import 'package:rotina_comercial/screens/department_detail_screen.dart';
import 'package:rotina_comercial/screens/special_items_screen.dart';
import 'package:rotina_comercial/screens/dashboard_screen.dart';
import 'package:rotina_comercial/utils/toast.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  setupApiInterceptors();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DepartmentsController()),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        title: 'Rotina Comercial',
        theme: ThemeData(
          primaryColor: const Color(0xFFE60014),
          scaffoldBackgroundColor: const Color(0xFFF2F4F8),
          useMaterial3: false,
        ),
        home: const Root(),
        routes: {
          'Login': (context) => const LoginScreen(),
          'LoginWebView': (context) => const LoginWebViewScreen(),
          'LoginToken': (context) => const LoginTokenScreen(),
          'Main': (context) => const MainScreen(),
          'DepartmentDetail': (context) => const DepartmentDetailScreen(),
          'SpecialItems': (context) => const SpecialItemsScreen(),
          'Dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.state == AuthState.loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F4F8),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE60014)),
        ),
      );
    }
    if (auth.state == AuthState.authenticated) {
      return const MainScreen();
    }
    if (auth.autoLogin) {
      return const LoginWebViewScreen();
    }
    return const LoginScreen();
  }
}
