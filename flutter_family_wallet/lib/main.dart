import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/start_screen.dart';

const supabaseUrl = 'https://zqqsnnvlgbiervaxnpki.supabase.co';
const supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpxcXNubnZsZ2JpZXJ2YXhucGtpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjY4NDAzOTYsImV4cCI6MjA0MjQxNjM5Nn0.MO5xT7LNUlcHx-waEu9pEGyZtfn0L41YOgExq4RMoZc';
//String.fromEnvironment('SUPABASE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Wallet',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme:
            ColorScheme.fromSwatch().copyWith(secondary: Colors.orangeAccent),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const StartScreen(),
    );
  }
}
