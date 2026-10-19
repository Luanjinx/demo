import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'pages/tv_splash_page.dart';
import 'providers/tv_auth_provider.dart';
import 'providers/tv_home_provider.dart';
import 'utils/color.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android TV is strictly landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide system UI bars for full-screen cinema mode
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  runApp(const NexstreamTVApp());
}

class NexstreamTVApp extends StatelessWidget {
  const NexstreamTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TVAuthProvider()),
        ChangeNotifierProvider(create: (_) => TVHomeProvider()),
      ],
      child: MaterialApp(
        title: "Nexstream TV",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: TVColors.appBg,
          primaryColor: TVColors.primary,
          colorScheme: const ColorScheme.dark(
            primary: TVColors.primary,
            secondary: TVColors.accent,
            surface: TVColors.surfaceBg,
          ),
          textTheme: GoogleFonts.outfitTextTheme(
            ThemeData.dark().textTheme,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const TVSplashPage(),
      ),
    );
  }
}
