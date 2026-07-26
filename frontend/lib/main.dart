import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Disable offline persistence so data is always fresh from server
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed. Make sure you have run flutterfire configure. Error: $e');
  }
  await initializeDateFormatting('id_ID', null);
  
  NotificationService().init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService().navigatorKey,
      scaffoldMessengerKey: NotificationService().scaffoldMessengerKey,
      title: 'SuajaPHOTOBOOTH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Light Slate Background
        primaryColor: const Color(0xFF4F46E5), // Indigo
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF4F46E5),
          secondary: Color(0xFF10B981), // Green
          surface: Colors.white, // Card color
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        dividerColor: Colors.black12,
      ),
      home: const SplashScreen(),
    );
  }
}
