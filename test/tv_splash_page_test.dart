import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nexstream_tv/pages/tv_splash_page.dart';
import 'package:nexstream_tv/providers/tv_auth_provider.dart';
import 'package:nexstream_tv/providers/tv_home_provider.dart';

void main() {
  testWidgets('TVSplashPage renders cinematic dtlive-style animations and widgets', (WidgetTester tester) async {
    // Set 16:9 TV landscape viewport (1920x1080)
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TVAuthProvider()),
          ChangeNotifierProvider(create: (_) => TVHomeProvider()),
        ],
        child: const MaterialApp(
          home: TVSplashPage(),
        ),
      ),
    );

    // Initial frame check
    expect(find.byType(TVSplashPage), findsOneWidget);

    // Pump 400ms: Icon reveal and background start
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Image), findsOneWidget);

    // Pump to 1200ms: Separator and tagline appear
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Everything.'), findsOneWidget);
    expect(find.text('Nothing.'), findsOneWidget);

    // Pump to 2000ms: Subtitle appears
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Unlimited Entertainment Awaits'), findsOneWidget);
    expect(find.textContaining('v1.0.0'), findsOneWidget);

    // Pump to transition
    await tester.pump(const Duration(milliseconds: 600));
  });
}
