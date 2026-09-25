import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/counsellor_provider.dart';
import 'providers/request_provider.dart';
import 'providers/wallet_provider.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const UnTenseProApp());
}

class UnTenseProApp extends StatelessWidget {
  const UnTenseProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CounsellorProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.token != null) {
            debugPrint('🔑 [MainApp] BEARER TOKEN: Bearer ${authProvider.token}');
          }
          if (authProvider.counsellor != null) {
            debugPrint('🐛 [MainApp] Counsellor ID: ${authProvider.counsellor?.uid} (userId: ${authProvider.counsellor?.userId})');
          }
          final router = AppRouter.createRouter(authProvider);
          return MaterialApp.router(
            title: 'UnTense Professional',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
