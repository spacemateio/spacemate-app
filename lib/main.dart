import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_view/web_view_screen.dart';
import 'package:web_view/screens/terms_screen.dart';
import 'environment_config.dart';

Future<void> main() async {
  EnvironmentConfig.environment = Environment.prod;  // or test, or prod
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if user has agreed to terms
  final prefs = await SharedPreferences.getInstance();
  final hasAgreedToTerms = prefs.getBool('has_agreed_to_terms') ?? false;
  
  runApp(MyApp(hasAgreedToTerms: hasAgreedToTerms));
}

class MyApp extends StatelessWidget {
  final bool hasAgreedToTerms;
  
  const MyApp({super.key, required this.hasAgreedToTerms});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpaceMate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: hasAgreedToTerms 
        ? const WebViewScreen(cookies: {'deviceType': 'mobile'})
        : const TermsScreen(),
    );
  }
}
