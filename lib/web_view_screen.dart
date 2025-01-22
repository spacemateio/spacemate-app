import 'dart:async';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';

import 'environment_config.dart';

class WebViewScreen extends StatefulWidget {
  final Map<String, String>? cookies;

  const WebViewScreen({
    super.key,
    this.cookies,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _webViewController;
  PullToRefreshController? pullToRefreshController;
  bool isLoading = true;
  int _currentIndex = 0;

  String get baseUrl => EnvironmentConfig.baseUrl;
  bool get isDevelopment => EnvironmentConfig.environment != Environment.prod;

  final List<NavigationItem> _pages = [
    NavigationItem(
      icon: 'assets/icons/explore.svg',
      label: 'Explore',
      route: '/storage',
    ),
    NavigationItem(
      icon: 'assets/icons/home.svg',
      label: 'Rents',
      route: '/account/reservation',
    ),
    NavigationItem(
      icon: 'assets/icons/inbox.svg',
      label: 'Inbox',
      route: '/chat',
    ),
    NavigationItem(
      icon: 'assets/icons/profile.svg',
      label: 'Profile',
      route: '/account',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializePullToRefresh();
    _initializeCookies();
  }

  void _initializePullToRefresh() {
    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: Colors.blue),
      onRefresh: () async {
        await _webViewController?.reload();
      },
    );
  }

  Future<void> _initializeCookies() async {
    if (widget.cookies != null) {
      try {
        final WebUri uri = WebUri(baseUrl);

        if (widget.cookies!.isNotEmpty) {
/*          try {
            await CookieManager.instance().deleteAllCookies();
          } catch (e) {
            developer.log('Error clearing cookies: $e', name: 'WebView');
          }*/

          for (final entry in widget.cookies!.entries) {
            try {
              await CookieManager.instance().setCookie(
                url: uri,
                name: entry.key,
                value: entry.value,
                domain: uri.host,
                path: '/',
              );
            } catch (e) {
              developer.log('Error setting cookie ${entry.key}: $e',
                  name: 'WebView');
            }
          }
        }
      } catch (e) {
        developer.log('Error initializing cookies: $e', name: 'WebView');
      }
    }
  }

  Future<void> sendToWebView(String type, dynamic data) async {
    try {
      final message = json.encode({
        'type': type,
        'data': data,
      });

      final escapedMessage = message.replaceAll("'", "\\'");

      await _webViewController?.evaluateJavascript(
          source:
              "window.dispatchEvent(new CustomEvent('fromFlutter', { detail: JSON.parse('$escapedMessage') }));");

      developer.log('Sent message to WebView: $message', name: 'WebView');
    } catch (e, stackTrace) {
      developer.log('Error sending message to WebView',
          name: 'WebView', error: e, stackTrace: stackTrace);
    }
  }

  void _handleJavaScriptMessage(String message) {
    try {
      final data = json.decode(message);
      developer.log('Received from web: $data', name: 'WebView');

      switch (data['type']) {
        case 'login':
          _handleLoginRequest();
          break;
        case 'logout':
          _handleLogoutRequest();
          break;
        // Handle other message types as needed
        default:
          break;
      }
    } catch (e, stackTrace) {
      developer.log('Error handling message',
          name: 'WebView', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _onItemTapped(int index) async {
    setState(() {
      _currentIndex = index;
    });

    await sendToWebView('navigation', {'route': _pages[index].route});
  }

  Future<void> _handleLogoutRequest() async {
    _onItemTapped(0);
  }

  Future<void> _handleLoginRequest() async {
    // _onItemTapped(0);

    try {
      final url =
          "$baseUrl/auth/signin?callbackUrl=${Uri.decodeFull("$baseUrl/auth/mobile-login")}";
      const callbackUrlScheme = "com.spacemate.app";

      if (Platform.isIOS) {
        // Use flutter_web_auth for iOS as it handles the flow better on iOS
        final result = await FlutterWebAuth.authenticate(
          url: url,
          callbackUrlScheme: callbackUrlScheme,
        );

        final token = Uri.parse(result).queryParameters['token'];
        if (token != null) {
          await _webViewController?.loadUrl(
              urlRequest: URLRequest(
                  url: WebUri("$baseUrl/auth/mobile-success?auth=$token")));

          setState(() {
            _currentIndex = 0;
          });
        }
      } else {
        // Android flow using url_launcher + uni_links
        final Uri uri = Uri.parse(url);

        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.inAppBrowserView,
          );

          final completer = Completer<String>();
          late StreamSubscription sub;

          sub = uriLinkStream.listen((Uri? uri) {
            if (uri != null && uri.scheme == callbackUrlScheme) {
              completer.complete(uri.toString());
              sub.cancel();
            }
          });

          try {
            final result = await completer.future.timeout(
              const Duration(minutes: 5),
              onTimeout: () {
                sub.cancel();
                throw TimeoutException('Authentication timed out');
              },
            );

            final token = Uri.parse(result).queryParameters['token'];
            if (token != null) {
              await _webViewController?.loadUrl(
                  urlRequest: URLRequest(
                      url: WebUri("$baseUrl/auth/mobile-success?auth=$token")));

              setState(() {
                _currentIndex = 0;
              });
            }
          } catch (e) {
            sub.cancel();
            rethrow;
          }
        }
      }
    } catch (e) {
      developer.log('Error during authentication: $e', error: e);
      await _webViewController?.loadUrl(
          urlRequest: URLRequest(url: WebUri("$baseUrl/storage")));
      _onItemTapped(0);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    var inAppWebViewSettings = InAppWebViewSettings(
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      javaScriptEnabled: true,
      useShouldOverrideUrlLoading: true,
      thirdPartyCookiesEnabled: true,
      domStorageEnabled: true,
      databaseEnabled: true,
      cacheEnabled: true,
      cacheMode: CacheMode.LOAD_DEFAULT,
      supportMultipleWindows: true,
    );

    if (Platform.isAndroid) {
      inAppWebViewSettings.mixedContentMode =
          MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW;
    }

    if (isDevelopment) {
      inAppWebViewSettings.isInspectable = true;
      inAppWebViewSettings.allowFileAccessFromFileURLs = true;
      inAppWebViewSettings.allowUniversalAccessFromFileURLs = true;
      inAppWebViewSettings.mixedContentMode =
          MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW;
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest:
                  URLRequest(url: WebUri('$baseUrl${_pages[0].route}')),
              initialSettings: inAppWebViewSettings,
              pullToRefreshController: pullToRefreshController,
              onWebViewCreated: (controller) {
                _webViewController = controller;

                controller.addJavaScriptHandler(
                  handlerName: 'FlutterChannel',
                  callback: (args) {
                    if (args.isNotEmpty) {
                      _handleJavaScriptMessage(args[0].toString());
                    }
                  },
                );
              },
              onLoadStart: (controller, url) async {
                setState(() => isLoading = true);

                developer.log("Navigation started to: $url");
              },
              onLoadStop: (controller, url) {
                pullToRefreshController?.endRefreshing();
                setState(() => isLoading = false);
                developer.log("Navigation completed to: $url");
              },
              onReceivedError: (controller, request, error) {
                pullToRefreshController?.endRefreshing();
                setState(() => isLoading = false);
                developer.log(
                    'Load Error: type=${error.type}, description=${error.description}, url=${request.url.toString()}',
                    name: 'WebView',
                    error: error.description);
              },
              onReceivedHttpError: (controller, request, errorResponse) {
                pullToRefreshController?.endRefreshing();
                setState(() => isLoading = false);
                developer.log(
                    'HTTP Error: statusCode=${errorResponse.statusCode}, description=${errorResponse.reasonPhrase}, url=${request.url.toString()}',
                    name: 'WebView',
                    error: errorResponse.reasonPhrase);
              },
              onPermissionRequest: (controller, request) async {
                return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT);
              },
              onLoadResource: (controller, resource) async {
                if (resource.url != null) {
                  final cookies = await CookieManager.instance()
                      .getCookies(url: resource.url!);
                  developer.log("URL: ${resource.url}");
                  developer.log("Cookies Detail:");
                  for (var cookie in cookies) {
                    developer.log("Name: ${cookie.name}");
                    developer.log("Value: ${cookie.value}");
                    developer.log("Domain: ${cookie.domain}");
                    developer.log("Path: ${cookie.path}");
                    developer.log("Secure: ${cookie.isSecure}");
                    developer.log("HttpOnly: ${cookie.isHttpOnly}");
                    developer.log("------------------");
                  }
                }
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                var uri = navigationAction.request.url!;
                var url = uri.toString();

                if (url.contains('facebook.com') ||
                    url.contains('linkedin.com') ||
                    url.contains('twitter.com') ||
                    url.contains('t.co')) {
                  await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                  return NavigationActionPolicy.CANCEL;
                }

                // Let WebView handle SpaceMate URLs
                if (url.contains('spacemate.io')) {
                  return NavigationActionPolicy.ALLOW;
                }

                // Open other external links in browser
                await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
                return NavigationActionPolicy.CANCEL;
              },
            ),
            if (isLoading)
              Container(
                color: Colors.white,
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/img/splash-screen.png',
                      width: MediaQuery.of(context).size.width *
                          0.8, // 80% of screen width
                      // or you can use a fixed larger size like:
                      // width: 300, // adjust this value to match your splash screen
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF4c4ddc)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade400,
              width: 1.0,
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF4c4ddc),
          unselectedItemColor: const Color(0xFF878787),
          backgroundColor: Colors.white,
          elevation: 0, // Changed to 0 since we're using custom border
          selectedFontSize: 12,
          unselectedFontSize: 12,
          onTap: _onItemTapped,
          items: _pages
              .map((page) => BottomNavigationBarItem(
                    icon: SvgPicture.asset(
                      page.icon,
                      width: 32,
                      height: 32,
                      colorFilter: ColorFilter.mode(
                          _currentIndex == _pages.indexOf(page)
                              ? const Color(0xFF4c4ddc)
                              : const Color(0xFF878787),
                          BlendMode.srcIn),
                    ),
                    label: page.label,
                  ))
              .toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    pullToRefreshController?.dispose();
    super.dispose();
  }
}

class NavigationItem {
  final String icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
