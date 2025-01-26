import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:web_view/web_view_screen.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (String url) {
          setState(() {
            _isLoading = true;
          });
        },
        onPageFinished: (String url) {
          setState(() {
            _isLoading = false;
          });
        },
      ))
      ..loadRequest(
        Uri.parse('https://spacemate.io/corporate/terms-of-service'),
        headers: {
          'Cookie': 'deviceType=mobile',
        },
      );
  }

  void _loadUrl(String url) {
    _controller.loadRequest(
      Uri.parse(url),
      headers: {
        'Cookie': 'deviceType=mobile',
      },
    );
  }

  Future<void> _agreeToTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_agreed_to_terms', true);
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const WebViewScreen(
          cookies: {'deviceType': 'mobile'},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Image.asset(
              'assets/icons/logo.png',
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF5850EC),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Stack(
                    children: [
                      WebViewWidget(
                        controller: _controller,
                      ),
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF5850EC),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                  children: [
                    const TextSpan(
                      text: 'By Selecting "I Agree & Continue", I agree to SpaceMate\'s ',
                    ),
                    TextSpan(
                      text: "Terms of Service",
                      style: const TextStyle(
                        color: Color(0xFF5850EC),
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          _loadUrl('https://spacemate.io/corporate/terms-of-service');
                        },
                    ),
                    const TextSpan(text: ", & acknowledge the "),
                    TextSpan(
                      text: "Privacy Policy",
                      style: const TextStyle(
                        color: Color(0xFF5850EC),
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          _loadUrl('https://spacemate.io/corporate/privacy-policy');
                        },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton(
                onPressed: _isLoading ? null : _agreeToTerms,
                style: FilledButton.styleFrom(
                  backgroundColor: _isLoading ? Colors.grey[300] : const Color(0xFF5850EC),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'I Agree & Continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: _isLoading ? Colors.grey[600] : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 