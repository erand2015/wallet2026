// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/home_screen.dart';
import 'screens/create_wallet_screen.dart';
import 'screens/import_wallet_screen.dart';
import 'screens/send_screen.dart';
import 'screens/receive_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/pin_screen.dart';
import 'utils/pointycastle_setup.dart';
import 'services/notification_service.dart';
import 'services/biometric_service.dart';
import 'theme/theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupPointyCastle();
  
  final notificationService = NotificationService();
  await notificationService.init();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final BiometricService _biometricService = BiometricService();
  bool _isAuthenticated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    setState(() => _isLoading = true);
    
    try {
      final hasPin = await _biometricService.hasPin();
      final biometricEnabled = await _biometricService.isBiometricEnabled();
      final pinEnabled = await _biometricService.isPinEnabled();
      
      if (!hasPin && !pinEnabled) {
        // Asnjë siguri nuk është konfiguruar, kalojmë direkt
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
        });
        return;
      }
      
      // Provo biometrinë nëse është e aktivizuar
      if (biometricEnabled) {
        try {
          final authenticated = await _biometricService.authenticateWithBiometrics();
          if (authenticated) {
            setState(() {
              _isAuthenticated = true;
              _isLoading = false;
            });
            return;
          }
        } catch (e) {
          print('Biometric auth error: $e');
          // Vazhdo me PIN nëse biometria dështon
        }
      }
      
      // Nëse biometria nuk funksionoi ose nuk është e aktivizuar, kërko PIN
      if (pinEnabled) {
        _showPinScreen();
      } else {
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print('Auth error: $e');
      setState(() {
        _isAuthenticated = true;
        _isLoading = false;
      });
    }
  }

  void _showPinScreen() {
    // Sigurohu që context-i është i disponueshëm
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentContext != null) {
        Navigator.push(
          navigatorKey.currentContext!,
          MaterialPageRoute(
            builder: (_) => PinScreen(
              isSetup: false,
              onSuccess: () {
                setState(() {
                  _isAuthenticated = true;
                });
                Navigator.pop(navigatorKey.currentContext!);
              },
            ),
          ),
        );
      } else {
        // Fallback: kalojmë direkt nëse context-i nuk është gati
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF000000),
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(WarthogColors.primaryOrange),
            ),
          ),
        ),
      );
    }

    if (!_isAuthenticated) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF000000),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock,
                  color: WarthogColors.primaryOrange,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Authentication required',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
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