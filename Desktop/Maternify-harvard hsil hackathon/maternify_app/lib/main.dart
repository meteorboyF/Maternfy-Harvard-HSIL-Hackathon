import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'blocs/auth/auth_bloc.dart';
import 'demo/demo_repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DemoRepository.instance.initialize();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const MaternifyApp(),
    ),
  );
}

class MaternifyApp extends StatelessWidget {
  const MaternifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc()..add(AuthStarted()),
        ),
      ],
      child: MaterialApp(
        title: 'Maternify',
        debugShowCheckedModeBanner: false,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        theme: _buildTheme(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('bn', 'BD'),
        ],
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return const HomeScreen();
            }
            if (state is AuthLoading) {
              return const _SplashScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    const primary = Color(0xFF993556);
    const secondary = Color(0xFF0F6E56);
    const background = Color(0xFFF7F4F1);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: Colors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
    );

    final textTheme = GoogleFonts.nunitoTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE7D8DF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE7D8DF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFE24B4A),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
