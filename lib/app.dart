import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'pages/expense_page.dart';
import 'providers/theme_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const _green = Color(0xFF07C160);
  static const _red = Color(0xFFF43F5E);
  static const _darkGreen = Color(0xFF357DFF);
  static const _darkRed = Color(0xfffd5147);
  static const _darkOrange = Color(0xFFE8A02C);
  static const _darkBg = Color(0xFF384152);
  static const _darkSurface = Color(0xFF2C2E35);

  static final _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _green,
    colorScheme: ColorScheme.light(
      primary: _green,
      secondary: _red,
      tertiary: Colors.orange,
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    scaffoldBackgroundColor: const Color(0xFFF0F0F0),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE0E0E0),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF0F0F0),
      surfaceTintColor:Color(0xFFF0F0F0),
      scrolledUnderElevation: 0,
    ),
    fontFamily: 'PingFang SC',
  );

  static final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _darkGreen,
    colorScheme: ColorScheme.dark(
      primary: _darkGreen,
      secondary: _darkRed,
      tertiary: _darkOrange,
      surface: _darkSurface,
      onSurface: const Color(0xFFB9B9B9),
    ),
    scaffoldBackgroundColor: _darkBg,
    cardColor: _darkSurface,
    dividerColor: const Color(0xff7e7e7e),//1
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF384152),
      surfaceTintColor: Color(0xFF384152),
      scrolledUnderElevation: 0,
    ),
    fontFamily: 'PingFang SC',
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => MaterialApp(
        title: '报账了吗',
        theme: _lightTheme,
        darkTheme: _darkTheme,
        themeMode: themeProvider.themeMode,
        home: const ExpensePage(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('zh', 'CH'), Locale('en', 'US')],
      ),
    );
  }
}
