import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/menu_screen.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldKey =
GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const AppTaxis());
}

class AppTaxis extends StatelessWidget {
  const AppTaxis({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppTaxis',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding:
          EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
      home: const MenuScreen(),
    );
  }
}