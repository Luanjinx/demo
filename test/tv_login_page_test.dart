import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nexstream_tv/pages/tv_login_page.dart';
import 'package:nexstream_tv/providers/tv_auth_provider.dart';
import 'package:nexstream_tv/providers/tv_home_provider.dart';
import 'package:nexstream_tv/utils/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      Constant.keyUserId: "123",
      Constant.keyUserName: "Rjl War",
      Constant.keyUserEmail: "rjl@example.com",
      Constant.keyUserIsKid: false,
    });
  });

  testWidgets('TVLoginPage renders Profiles and switches to Kids without overflow', (tester) async {
    final authProvider = TVAuthProvider();
    final homeProvider = TVHomeProvider();
    await authProvider.initAuth();

    // Set screen size to typical 1080p landscape TV resolution (1920x1080)
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TVAuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<TVHomeProvider>.value(value: homeProvider),
        ],
        child: const MaterialApp(
          home: TVLoginPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify "Profiles" header and "Edit" action
    expect(find.text("Profiles"), findsOneWidget);
    expect(find.text("Edit"), findsOneWidget);

    // Verify profiles exist: User profile and Kids
    expect(find.text("Rjl War"), findsOneWidget);
    expect(find.text("Kids"), findsOneWidget);

    // Initial state: not kid
    expect(Constant.userIsKid, isFalse);

    // Tap Kids profile
    await tester.tap(find.text("Kids"));
    await tester.pumpAndSettle();

    // Switched to Kids
    expect(Constant.userIsKid, isTrue);
    expect(find.text("Profil Anak Aktif"), findsOneWidget);

    // Tap User profile to switch back
    await tester.tap(find.text("Rjl War"));
    await tester.pumpAndSettle();

    expect(Constant.userIsKid, isFalse);
    expect(find.text("Profil Utama Aktif"), findsOneWidget);

    // Verify "Keluar Akun" button
    expect(find.text("Keluar Akun"), findsOneWidget);
  });
}
