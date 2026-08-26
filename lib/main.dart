import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_gate.dart';
import 'l10n/app_language.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://bygqatraidykcxjfjala.supabase.co',
    publishableKey: 'sb_publishable_bE4vhtX2id53rSg1DpnmxA_8xxGFnui',
  );
  await AppLanguageController.initialize();
  await NotificationService.instance.initialize();
  runApp(const WerkStudentAI());
}

class WerkStudentAI extends StatelessWidget {
  const WerkStudentAI({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF17231F);
    const green = Color(0xFF2F6B55);
    const cream = Color(0xFFF7F7F2);

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLanguageController.language,
      builder: (context, language, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppStrings(language).get('appTitle'),
        locale: language.locale,
        supportedLocales: AppLanguage.values.map((item) => item.locale),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: cream,
          colorScheme: ColorScheme.fromSeed(
            seedColor: green,
            primary: green,
            secondary: const Color(0xFFE9A95B),
            surface: Colors.white,
            onSurface: ink,
          ),
          fontFamily: 'Arial',
          textTheme: const TextTheme(
            displaySmall: TextStyle(
              color: ink,
              fontSize: 34,
              height: 1.05,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
            headlineMedium: TextStyle(
              color: ink,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
            headlineSmall: TextStyle(
              color: ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            titleMedium: TextStyle(
              color: ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            bodyLarge: TextStyle(color: ink, fontSize: 15, height: 1.5),
            bodyMedium: TextStyle(
              color: Color(0xFF62706A),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Color(0xFFE7EAE4)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE4E8E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE4E8E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: green, width: 1.5),
            ),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}
