import 'package:flutter/material.dart';
import 'package:web_view/web_view_screen.dart';

import 'environment_config.dart';

Future<void> main() async {
  EnvironmentConfig.environment = Environment.test;  // or test, or prod
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        useMaterial3: true,
      ),
      home: const WebViewScreen(
        cookies: {
/*          'next-auth.session-token': 'eyJhbGciOiJkaXIiLCJlbmMiOiJBMjU2R0NNIn0..qZeA0iyCOFi3aarl.GCMeczwMl3B-hrHJ9-LIcjauiPrcUIRCmVN_CBb8M52DGjnfP_5BshLTCFcQNjxDcJ0_VRvHGwk-j06sS3YndY7KDPXXNEr744B8OUkFLRqa4h9lqXis3OWiij6nRz6IxYXmeo7alMZJM_csBpZpwTwBLgcS35Fbhd6-SLjYMfe7hjFU39gXHvBil3ksCGO1QT2m8eR1wnN0JzVyzhJ1L8WAUaWZ5IQR1kF0JmmqH8GRAfSn0T96Ig1umuZqMLNHZklLq7M0AQVnnouHreXSUvtpRcQkZXB8ncOuLjCOE8P6LYJASXCXx8CaRUb74O6hWoGLttL_STthGv58NKdd__VA1n_Q8k2AjpI1h1wdllr1eUI3KiCYJR_Dizq8J1yl0yPW8gZGZ5zFHKRRne97NfD-kMz5VTcNz5kzKRL3g0n6ZIkDnWZ_wIPPrzmyKpvO0uXWBhrjNpm1G0GUQqdBCFMOZaHQ-r21PO5aXwyKZQHNZNcdAALvE3t_CV_WiwVGpkeNfe5Fv659a_gzpPnsIwfjg3pH31QazKFas8OqGTQZhvPXnlK9f1gr8r9ihyBLX17I0kaVzI5LUOaORLgTPziHAMos6fHtQAetqB1IaqXvKQFTaegJgDsFYotPUblMUttSZHe1pOv-KI7eQjCh9Fs.CVN_qLcWipn_MZJh4Xvkmw',*/
          'deviceType': 'mobile',
        },
      ),
    );
  }
}
