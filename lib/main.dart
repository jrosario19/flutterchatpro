import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_pro/authentication/login_screen.dart';
import 'package:flutter_chat_pro/authentication/otp_screen.dart';
import 'package:flutter_chat_pro/authentication/user_information_screen.dart';
import 'package:flutter_chat_pro/constants.dart';
import 'package:flutter_chat_pro/firebase_options.dart';
import 'package:flutter_chat_pro/main_screens/settings_screen.dart';
import 'package:flutter_chat_pro/providers/authentication_provider.dart';
import 'package:provider/provider.dart';

import 'main_screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(
      create: (_) => AuthenticationProvider(),
    )
  ], child: MyApp(savedThemeMode: savedThemeMode)));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.savedThemeMode});

  final AdaptiveThemeMode? savedThemeMode;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.deepPurple,
      ),
      dark: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
      ),
      initial: savedThemeMode ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Chat Pro',
        theme: theme,
        darkTheme: darkTheme,
        initialRoute: Constants.loginScreen,
        routes: {
          Constants.loginScreen: (context) => LoginScreen(),
          Constants.otpScreen: (context) => OTPScreen(),
          Constants.userInformationScreen: (context) =>
              UserInformationScreen(),
          Constants.homeScreen  : (context) => HomeScreen(),
  }),
    );
  }
}
