// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart'; // <- Kjo duhet të jetë MainScreen
import 'screens/create_wallet_screen.dart';
import 'screens/import_wallet_screen.dart';
import 'screens/send_screen.dart';
import 'screens/receive_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/pointycastle_setup.dart';
import 'services/notification_service.dart';
import 'theme/theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupPointyCastle();

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        title: 'Warthog Wallet',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: WarthogTheme.lightTheme,
        darkTheme: WarthogTheme.darkTheme,
        themeMode: ThemeMode.dark,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/': (context) =>
              const MainScreen(), // <- Kjo duhet të jetë MainScreen
          '/create': (context) => const CreateWalletScreen(),
          '/import': (context) => const ImportWalletScreen(),
          '/send': (context) => const SendScreen(),
          '/receive': (context) => const ReceiveScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
