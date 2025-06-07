import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/account_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/auth_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/kos_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/providers/lowongan_provider.dart';
import 'package:loker_kabur_aja_dulu/presentation/screens/auth/login_screen.dart';
import 'package:loker_kabur_aja_dulu/presentation/screens/home_screen.dart'; // Akan kita buat nanti
import 'package:loker_kabur_aja_dulu/services/notification_service.dart';
// import 'package:loker_kabur_aja_dulu/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
// import 'package:timezone/standalone.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await NotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
  }

  

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => LowonganProvider(),
        ), // Daftarkan di sini
        ChangeNotifierProvider(create: (_) => KosProvider()), // Nanti untuk Kos
        // ChangeNotifierProvider(create: (_) => FavoritesProvider()), // Nanti untuk favorit gabungan
        ChangeNotifierProvider(
          create: (_) => AccountProvider(),
        ), // Nanti untuk saldo, dll
      ],
      child: MaterialApp(
        title: 'KaburAjaDulu',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.teal),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.tealAccent, width: 2),
            ),
            labelStyle: GoogleFonts.poppins(),
            hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // Coba load token saat aplikasi dimulai
            // Ini bisa dipindahkan ke splash screen jika ada

            if (authProvider.isInitializing) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Jika token ada, anggap sudah login (untuk sementara)
            // Idealnya ada validasi token ke server atau cek role
            return authProvider.isAuthenticated
                ? const HomeScreen()
                : const LoginScreen();
          },
        ),
        routes: {
          LoginScreen.routeName: (ctx) => const LoginScreen(),
          HomeScreen.routeName: (ctx) => const HomeScreen(),
          // RegisterScreen.routeName: (ctx) => const RegisterScreen(), // Akan ditambahkan
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
